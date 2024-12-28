USE QLITHONGTINHETHONGSIEUTHI
GO

--StoredProcedure phụ
--Cập nhật giá sản phẩm: cập nhật giá sản phẩm theo mã sản phẩm
CREATE PROCEDURE sp_CapNhatGiaSanPham
    @MaSanPham CHAR(10),
    @GiaMoi INT
AS
BEGIN
    -- Bắt đầu giao dịch
    BEGIN TRANSACTION;

    -- Thiết lập mức độ ISOLATION cho toàn bộ giao dịch
    SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;

    -- Cập nhật giá sản phẩm
    UPDATE SANPHAM
    SET GIATIEN = @GiaMoi
    WHERE MA_SANPHAM = @MaSanPham;

    -- Kiểm tra lỗi, nếu có rollback giao dịch
    IF @@ERROR <> 0
    BEGIN
        ROLLBACK TRANSACTION;
        RETURN;
    END

    -- Commit giao dịch nếu không có lỗi
    COMMIT TRANSACTION;
END
GO

--XOA KhachHang: xóa khách hàng theo mã khách hàng
CREATE PROCEDURE sp_XoaKhachHang
    @MaKhachHang CHAR(10)
AS
BEGIN
    -- Bắt đầu giao dịch
    BEGIN TRANSACTION;

    -- Thiết lập mức độ ISOLATION cho toàn bộ giao dịch
    SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;

    -- Xóa khách hàng
    DELETE FROM KHACHHANG
    WHERE MA_KHACHHANG = @MaKhachHang;

    -- Kiểm tra lỗi, nếu có rollback giao dịch
    IF @@ERROR <> 0
    BEGIN
        ROLLBACK TRANSACTION;
        RETURN;
    END

    -- Commit giao dịch nếu không có lỗi
    COMMIT TRANSACTION;
END
GO

--Xoá khuyến mãi: xóa khuyến mãi theo mã khuyến mãi
CREATE PROCEDURE sp_XoaKhuyenMai
    @MaKhuyenMai CHAR(10)
AS
BEGIN
    -- Bắt đầu giao dịch
    BEGIN TRANSACTION;

    -- Thiết lập mức độ ISOLATION cho toàn bộ giao dịch
    SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;

    --xoá chi tiết khuyến mãi sản phẩm có liên quan
    DELETE FROM SANPHAM_KHUYENMAI WITH (TABLOCKX)
    WHERE MA_CHUONGTRINH = @MaKhuyenMai;

    --xoá chi tiết khuyến mãi combo có liên quan
    DELETE FROM SANPHAM_KHUYENMAI_COMBO WITH (TABLOCKX)
    WHERE MA_CHUONGTRINH = @MaKhuyenMai;

    --xoá chương trình khuyến mãi
    DELETE FROM CHUONGTRINH_KHUYENMAI WITH (TABLOCKX)
    WHERE MA_CTKM = @MaKhuyenMai;

    -- Kiểm tra lỗi, nếu có rollback giao dịch
    IF @@ERROR <> 0
    BEGIN
        ROLLBACK TRANSACTION;
        RETURN;
    END
    COMMIT TRANSACTION;
END
GO

--Thống kê đơn hàng: thống kê số lượng khách hàng theo ngày
CREATE or alter PROCEDURE sp_ThongKeKhachHang
AS
BEGIN
    BEGIN TRY
        BEGIN TRANSACTION;

        SET TRANSACTION ISOLATION LEVEL SERIALIZABLE; 

        SELECT COUNT(DISTINCT MA_KHACHHANG) AS TongKhachHang
        FROM  KHACHHANG

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO



--Thuận: Bộ phân xử lý đơn hàng
--Kiểm tra khuyến mãi: kiểm tra một món hay combo sản phẩm có khuyến mãi hay không
CREATE PROCEDURE sp_KiemTraKhuyenMai @MaSanPham CHAR(10), @Muc_GiamGia FLOAT OUTPUT 
AS
BEGIN
    SET NOCOUNT ON
    SET @Muc_GiamGia = 0
    

    IF NOT EXISTS (SELECT 1 FROM SANPHAM WHERE MA_SANPHAM = @MaSanPham)
    BEGIN
        RETURN
    END

	BEGIN TRANSACTION
	BEGIN TRY
        DECLARE @Ma_CTKM CHAR(10)
        SELECT TOP 1 @Muc_GiamGia = MUC_GIAMGIA, @Ma_CTKM = MA_CHUONGTRINH
        FROM SANPHAM_KHUYENMAI
        WHERE MA_SANPHAM = @MaSanPham AND TINHTRANG = 'Active'

        IF @Muc_GiamGia > 0
        BEGIN
            COMMIT TRANSACTION
            RETURN
        END

        SELECT TOP 1 @Muc_GiamGia = MUC_GIAMGIA, @Ma_CTKM = MA_CHUONGTRINH
        FROM SANPHAM_KHUYENMAI_COMBO
        WHERE (MA_SANPHAM_1 = @MaSanPham OR MA_SANPHAM_2 = @MaSanPham) AND TINHTRANG = 'Active'

        --in ra mã chương trình khuyến mãi
        PRINT 'Mã chương trình khuyến mãi: ' + @Ma_CTKM

        COMMIT TRANSACTION
        RETURN

    END TRY
    BEGIN CATCH
        PRINT N'Lỗi xảy ra trong quá trình kiểm tra khuyến mãi: ' + ERROR_MESSAGE()
        ROLLBACK TRANSACTION
    END CATCH
END;
GO

--Tạo chi tiết đơn hàng: tạo các chi tiết đơn hàng cho từng sản phẩm trong đơn hàng
CREATE OR ALTER PROCEDURE sp_TaoChiTietDonHang
    @MaDonHang CHAR(10), -- Mã đơn hàng
    @DanhSachMaSanPham NVARCHAR(MAX) -- Danh sách mã sản phẩm cần mua (cách nhau bởi dấu phẩy vd: 'SP001,SP002,SP003')
AS
BEGIN
    SET NOCOUNT ON; -- Prevent extra result sets

    -- Check if the order exists
    IF NOT EXISTS (SELECT 1 FROM DONHANG WHERE MA_DONHANG = @MaDonHang)
    BEGIN
        PRINT N'Đơn hàng không tồn tại.';
        RETURN;
    END;

    BEGIN TRANSACTION;
    BEGIN TRY
        -- Temporary table to hold aggregated product quantities
        CREATE TABLE #SanPhamGop (
            MaSanPham CHAR(10), -- Mã sản phẩm
            SoLuong INT -- Số lượng
        );

        DECLARE @MaSanPham CHAR(10);
        DECLARE @SoLuong INT;
        DECLARE @GiaBan INT;
        DECLARE @MucGiamGia FLOAT;
        DECLARE @SoLuong_SPKM INT;
        DECLARE @SoLuong_SPKM_ToiDa INT = 3;
        DECLARE @TongGiaTriKhuyenMai INT;
        DECLARE @TongGiaTri INT;

        -- Parse the product list and aggregate quantities
        ;WITH SplitSanPham AS (
            SELECT
                LTRIM(RTRIM(value)) AS MaSanPham
            FROM STRING_SPLIT(@DanhSachMaSanPham, ',')
        )
        INSERT INTO #SanPhamGop (MaSanPham, SoLuong) -- Insert into temporary table
        SELECT MaSanPham, COUNT(*)
        FROM SplitSanPham
        GROUP BY MaSanPham;

        -- Cursor to process each product
        DECLARE sp_cursor CURSOR FOR 
        SELECT MaSanPham, SoLuong
        FROM #SanPhamGop;

        OPEN sp_cursor;
        FETCH NEXT FROM sp_cursor INTO @MaSanPham, @SoLuong;

        WHILE @@FETCH_STATUS = 0
        BEGIN
            -- Check if the product exists
            IF NOT EXISTS (SELECT 1 FROM SANPHAM WHERE MA_SANPHAM = @MaSanPham)
            BEGIN
                PRINT N'Sản phẩm không tồn tại: ' + @MaSanPham;
                FETCH NEXT FROM sp_cursor INTO @MaSanPham, @SoLuong;
                CONTINUE;
            END;

            -- Check for promotion
            EXEC sp_KiemTraKhuyenMai @MaSanPham, @MucGiamGia OUTPUT;

            IF @MucGiamGia <> 0
            BEGIN
                -- Get product price and promotion limit
                SELECT TOP 1 @GiaBan = SANPHAM.GIATIEN, @SoLuong_SPKM = SANPHAM_KHUYENMAI.SOLUONG_SANPHAM_KHUYENMAI
                FROM SANPHAM_KHUYENMAI JOIN SANPHAM ON SANPHAM_KHUYENMAI.MA_SANPHAM = SANPHAM.MA_SANPHAM
                WHERE SANPHAM.MA_SANPHAM = @MaSanPham;

                -- Adjust promotion quantity if necessary
                IF @SoLuong_SPKM_ToiDa > @SoLuong_SPKM
                BEGIN
                    SET @SoLuong_SPKM_ToiDa = @SoLuong_SPKM;
                    UPDATE SANPHAM_KHUYENMAI
                    SET TINHTRANG = 'Inactive', SOLUONG_SANPHAM_KHUYENMAI = 0
                    WHERE MA_SANPHAM = @MaSanPham;
                END;

                -- Calculate the total promotion value
                IF @SoLuong <= @SoLuong_SPKM_ToiDa
                BEGIN
                    SET @TongGiaTriKhuyenMai = @GiaBan * (@MucGiamGia / 100) * @SoLuong;
                END;
                ELSE
                BEGIN
                    SET @TongGiaTriKhuyenMai = @GiaBan * (@MucGiamGia / 100) * @SoLuong_SPKM_ToiDa;
                END;

                SET @TongGiaTri = (@GiaBan * @SoLuong) - @TongGiaTriKhuyenMai;

                -- Insert into order details with promotion
                INSERT INTO CHITIET_DONHANG (MA_CTDH, MA_DONHANG, MA_SANPHAM, SOLUONG, GIABAN, GIATRIKHUYENMAI)
                VALUES (NEWID(), @MaDonHang, @MaSanPham, @SoLuong, @GiaBan, @TongGiaTriKhuyenMai);
                UPDATE SANPHAM --WITH (UPDLOCK, ROWLOCK)
                SET SoLuong_ConLai = SoLuong_ConLai - @SoLuong
                WHERE MA_SANPHAM = @MaSanPham
            END;
            ELSE
            BEGIN
                -- Get product price
                SELECT TOP 1 @GiaBan = GIATIEN
                FROM SANPHAM
                WHERE MA_SANPHAM = @MaSanPham;

                SET @TongGiaTri = @GiaBan * @SoLuong;

                -- Insert into order details without promotion
                INSERT INTO CHITIET_DONHANG (MA_CTDH, MA_DONHANG, MA_SANPHAM, SOLUONG, GIABAN, GIATRIKHUYENMAI)
                VALUES (NEWID(), @MaDonHang, @MaSanPham, @SoLuong, @GiaBan, 0);

                UPDATE SANPHAM --WITH (UPDLOCK, ROWLOCK)
                SET SoLuong_ConLai = SoLuong_ConLai - @SoLuong
                WHERE MA_SANPHAM = @MaSanPham
            END;

            FETCH NEXT FROM sp_cursor INTO @MaSanPham, @SoLuong;
        END;

		
        -- Clean up cursor and temporary table
        CLOSE sp_cursor;
        DEALLOCATE sp_cursor;
        DROP TABLE #SanPhamGop;

        -- Commit transaction
        COMMIT TRANSACTION;

        PRINT N'Tạo chi tiết đơn hàng thành công.';
    END TRY
    BEGIN CATCH
        -- Rollback on error
        PRINT N'Lỗi xảy ra trong quá trình tạo chi tiết đơn hàng: ' + ERROR_MESSAGE();
        ROLLBACK TRANSACTION;
    END CATCH;
END;
GO


--Tạo đơn hàng cho khách hàng: tạo đơn hàng cho khách hàng với các thông tin cần thiết
CREATE PROCEDURE sp_TaoDonHangChoKhachHang
    @MaKhachHang CHAR(10), -- Mã khách hàng
    @MaPhieuMuaHang CHAR(10), -- Mã phiếu mua hàng để trừ trên tổng giá trị đơn hàng
    @DanhSachMaSanPham NVARCHAR(MAX), -- Danh sách mã sản phẩm cần mua (cách nhau bởi dấu phẩy vd: 'SP001,SP002,SP003')
    @HinhThucMuaHang CHAR(7), -- Hình thức mua hàng (Trực tiếp, Online)
    @PhuongThucThanhToan CHAR(7), -- Phương thức thanh toán (Tiền mặt, Chuyển khoản)
    @TinhTrangThanhToan CHAR(10) -- Tình trạng thanh toán (Chưa thanh toán, Đã thanh toán)
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRANSACTION;
    BEGIN TRY
        -- Kiểm tra khách hàng
        IF NOT EXISTS (SELECT 1 FROM KHACHHANG WHERE MA_KHACHHANG = @MaKhachHang)
        BEGIN
            RAISERROR (N'Khách hàng không tồn tại.', 16, 1);
        END;

        -- Kiểm tra phiếu mua hàng
        DECLARE @GiaTriPhieu INT = 0;
        IF NOT EXISTS (
            SELECT 1
            FROM PHIEUMUAHANG
            WHERE MA_PHIEUMUAHANG = @MaPhieuMuaHang
            AND TRANGTHAI_PHIEUMUAHANG = 'Active'
            AND GETDATE() BETWEEN NGAYAPDUNG AND NGAYHETHAN
        )
        BEGIN
            PRINT N'Phiếu mua hàng không hợp lệ hoặc đã hết hạn.';
        END
        ELSE
        BEGIN
            SELECT @GiaTriPhieu = GIATRI_PHIEUMUAHANG
            FROM PHIEUMUAHANG
            WHERE MA_PHIEUMUAHANG = @MaPhieuMuaHang;
        END;

        -- Tạo mã đơn hàng
        DECLARE @MaDonHang CHAR(10);
        DECLARE @LastOrderNumber CHAR(10) = (SELECT MAX(MA_DONHANG) FROM DONHANG);
        DECLARE @NumericPart INT;

        IF @LastOrderNumber IS NULL
        BEGIN
            SET @MaDonHang = 'DH001';
        END
        ELSE
        BEGIN
            SET @NumericPart = CAST(SUBSTRING(@LastOrderNumber, 3, LEN(@LastOrderNumber) - 2) AS INT) + 1;
            SET @MaDonHang = 'DH' + RIGHT('000' + CAST(@NumericPart AS VARCHAR(10)), 3);
        END;

        -- Tạo đơn hàng
        INSERT INTO DONHANG (MA_DONHANG, MA_KHACHHANG, MA_PHIEUMUAHANG, TONGGIATRI, HINHTHUC_MUAHANG, TRANGTHAI_DONHANG, NGAYTAO, PHUONGTHUC_THANHTOAN, TRANGTHAI_THANHTOAN)
        VALUES (@MaDonHang, @MaKhachHang, @MaPhieuMuaHang, NULL, @HinhThucMuaHang, NULL, GETDATE(), @PhuongThucThanhToan, @TinhTrangThanhToan);

        -- Tạo chi tiết đơn hàng
        EXEC sp_TaoChiTietDonHang @MaDonHang, @DanhSachMaSanPham;

        -- Tính tổng giá trị đơn hàng
        DECLARE @TongTienDonHang INT;
        SELECT @TongTienDonHang = SUM(GIABAN * SOLUONG - ISNULL(GIATRIKHUYENMAI, 0))
        FROM CHITIET_DONHANG
        WHERE MA_DONHANG = @MaDonHang;

        -- Áp dụng phiếu mua hàng
        IF @GiaTriPhieu > 0
        BEGIN
            SET @TongTienDonHang = @TongTienDonHang - @GiaTriPhieu;
            IF @TongTienDonHang < 0
                SET @TongTienDonHang = 0;

            -- Cập nhật trạng thái phiếu mua hàng
            UPDATE PHIEUMUAHANG
            SET TRANGTHAI_PHIEUMUAHANG = 'Inactive'
            WHERE MA_PHIEUMUAHANG = @MaPhieuMuaHang;
        END;

        -- Cập nhật tổng giá trị đơn hàng
        UPDATE DONHANG
        SET TONGGIATRI = @TongTienDonHang,
            TRANGTHAI_DONHANG = N'Đã xử lý'
        WHERE MA_DONHANG = @MaDonHang;

        -- Hoàn tất giao dịch
        COMMIT TRANSACTION;

        PRINT N'Tạo đơn hàng thành công. Mã đơn hàng: ' + @MaDonHang;

    END TRY
    BEGIN CATCH
        -- Rollback nếu lỗi xảy ra
        IF XACT_STATE() <> 0
            ROLLBACK TRANSACTION;

        -- Hiển thị lỗi
        PRINT N'Lỗi xảy ra: ' + ERROR_MESSAGE();
    END CATCH;
END;
GO


--YẾN: Bộ phận quản lý kho hàng
-- Dùng để thống kê kho theo ngày cụ thể để biết số lượng tồn, số lượng đặt, số lượng còn nợ
CREATE PROCEDURE sp_ThongKeKho
    @NgayThongKe DATE
AS
BEGIN
    -- Bắt đầu giao dịch
    BEGIN TRANSACTION;

    -- Thiết lập ISOLATION LEVEL cho toàn bộ giao dịch
    SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;  -- Đảm bảo tính toàn vẹn dữ liệu và tránh tranh chấp khi truy cập vào bảng

    -- Thực hiện thống kê kho cho các sản phẩm trong ngày @NgayThongKe
    -- Đọc dữ liệu từ bảng KhoHang (số lượng tồn kho)
    DECLARE @ThongKeKho TABLE (
        ProductID INT,
        SoLuongTon INT,
        SoLuongDat INT,
        SoLuongConNo INT
    );

    -- Truy vấn trực tiếp để tính toán các thông tin tồn kho, cần đặt và còn nợ
    INSERT INTO @ThongKeKho (ProductID, SoLuongTon, SoLuongDat, SoLuongConNo)
    SELECT 
        SP.MA_SANPHAM,
        SUM(ISNULL(SP.SOLUONG_CONLAI, 0)) AS SoLuongTon,
        ISNULL(SUM(CTDDH.SOLUONG_DATHANG), 0) AS SoLuongDat,
        (ISNULL(SUM(CTDDH.SOLUONG_DATHANG), 0) - ISNULL(SUM(NH.SOLUONG_NHAPHANG), 0)) AS SoLuongConNo
    FROM 
        SANPHAM SP
        LEFT JOIN CHITIET_NHAPHANG NH ON NH.MA_SANPHAM = SP.MA_SANPHAM
        LEFT JOIN CHITIET_DONDATHANG CTDDH ON CTDDH.MA_SANPHAM = SP.MA_SANPHAM
        LEFT JOIN DONDATHANG DDH ON DDH.MA_DONDATHANG = CTDDH.MA_DONDATHANG
    WHERE 
        DDH.NGAYDATHANG = @NgayThongKe AND DDH.TINHTRANG = N'Đang xử lý'
    GROUP BY 
        SP.MA_SANPHAM;

    -- Cập nhật thông tin thống kê kho vào bảng ChiTiet_ThongKe_Kho_HangNgay
    -- Sử dụng mức khoá ROWLOCK cho câu lệnh UPDATE để chỉ khóa các dòng đang được cập nhật, tránh tranh chấp
    UPDATE THK
    SET 
        THK.SOLUONG_TONKHO = TK.SoLuongTon,
        THK.SOLUONG_CANDAT = TK.SoLuongDat,
        THK.SOLUONG_CONNO = TK.SoLuongConNo
    FROM 
        ChiTiet_ThongKe_Kho_HangNgay THK WITH (ROWLOCK)  -- Cấp độ khóa dòng
    JOIN 
        @ThongKeKho TK ON THK.MA_SANPHAM = TK.ProductID
    WHERE 
        THK.THOIGIAN_THONGKE = @NgayThongKe
        AND THK.MA_SANPHAM IN (SELECT ProductID FROM @ThongKeKho);

    -- Kiểm tra nếu có lỗi xảy ra, thực hiện rollback
    IF @@ERROR <> 0
    BEGIN
        ROLLBACK TRANSACTION
        RETURN
    END

    -- Commit transaction nếu không có lỗi
    COMMIT TRANSACTION
END
GO

--Tự động đặt sản phẩm nếu thiếu và đủ điều kiện đặt
CREATE PROCEDURE sp_DatHang 
AS
BEGIN
    -- Bắt đầu giao dịch
    BEGIN TRANSACTION

    -- Thiết lập ISOLATION LEVEL cho toàn bộ giao dịch
    SET TRANSACTION ISOLATION LEVEL SERIALIZABLE -- Đảm bảo tính toàn vẹn dữ liệu và tránh tranh chấp

    -- Khai báo con trỏ để duyệt qua các sản phẩm trong KhoHang
    DECLARE product_cursor CURSOR LOCAL FORWARD_ONLY READ_ONLY FOR
    SELECT MA_SANPHAM, SOLUONG_CONLAI, SOLUONG_TOIDA
    FROM SANPHAM WITH (TABLOCKX) -- Khóa bảng để đảm bảo không có thay đổi song song

    -- Biến để lưu trữ thông tin sản phẩm từ con trỏ
    DECLARE @MA_SANPHAM CHAR(10), @SOLUONG_CONLAI INT, @SOLUONG_TOIDA INT

    -- Mở con trỏ
    OPEN product_cursor

    -- Lặp qua từng sản phẩm
    FETCH NEXT FROM product_cursor INTO @MA_SANPHAM, @SOLUONG_CONLAI, @SOLUONG_TOIDA;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        -- 1.2: Sử dụng sp_ThongKeKho để lấy số lượng chưa giao của sản phẩm
        DECLARE @SoLuongChuaGiao INT
		DECLARE @Ngay DATE
		SET @Ngay = GETDATE()
        EXEC sp_ThongKeKho @NgayThongKe = @Ngay

        -- Lấy số lượng chưa giao từ bảng ChiTiet_ThongKe_Kho_HangNgay
        SELECT @SoLuongChuaGiao = SOLUONG_CONNO
        FROM ChiTiet_ThongKe_Kho_HangNgay WITH (ROWLOCK)
        WHERE MA_SANPHAM = @MA_SANPHAM AND THOIGIAN_THONGKE = GETDATE()

        -- 1.3: Lọc sản phẩm có số lượng tồn kho thấp hơn ngưỡng 70%
        IF @SOLUONG_CONLAI < 0.7 * @SOLUONG_TOIDA
        BEGIN
            -- 1.4: Tính số lượng cần đặt
            DECLARE @SoLuongDat INT;
            SET @SoLuongDat = @SOLUONG_TOIDA - @SOLUONG_CONLAI - ISNULL(@SoLuongChuaGiao, 0)

            IF @SoLuongDat >= 0.1 * @SOLUONG_TOIDA
            BEGIN
                -- 1.5: Tạo đơn đặt hàng mới
                DECLARE @DonDatHangID INT;
                INSERT INTO DonDatHang (NGAYDATHANG, MA_NHASANXUAT, TINHTRANG)
                VALUES (GETDATE(),
                        (SELECT TOP 1 NSX.MA_NHASANXUAT FROM NHASANXUAT NSX JOIN SANPHAM SP ON NSX.MA_NHASANXUAT = SP.MA_NHASANXUAT  WHERE SP.MA_SANPHAM = @MA_SANPHAM), -- Lấy nhà cung cấp từ NCC
                        N'Chưa xử lý');

                SET @DonDatHangID = SCOPE_IDENTITY(); -- Lấy ID đơn đặt hàng vừa tạo

                -- 1.6: Ghi nhận chi tiết đơn đặt hàng
                INSERT INTO CHITIET_DONDATHANG (MA_DONDATHANG, MA_SANPHAM, SOLUONG_DATHANG)
                VALUES (@DonDatHangID, @MA_SANPHAM, @SoLuongDat);
            END
        END

        -- Lấy sản phẩm tiếp theo trong con trỏ
        FETCH NEXT FROM product_cursor INTO @MA_SANPHAM, @SOLUONG_CONLAI, @SOLUONG_TOIDA;
    END

    -- Đóng và giải phóng con trỏ
    CLOSE product_cursor
    DEALLOCATE product_cursor

    -- Kiểm tra nếu có lỗi và rollback nếu cần
    IF @@ERROR <> 0
    BEGIN
        ROLLBACK TRANSACTION
        RETURN
    END

    -- Commit giao dịch
    COMMIT TRANSACTION
END
GO

-- Để cập nhật trạng thái của đơn đặt hàng là "Đã xử lý" nếu đã giao đủ
CREATE PROCEDURE sp_XuLyDonDatHang
    @MaDonDatHang CHAR(10)
AS
BEGIN
    -- Thiết lập TRANSACTION để đảm bảo tính toàn vẹn dữ liệu
    BEGIN TRANSACTION;

    -- Thiết lập mức độ ISOLATION để tránh tranh chấp dữ liệu
    SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;

    -- Khai báo biến
    DECLARE @TongSoLuongDat INT, @TongSoLuongGiao INT;

    -- 1.1 Đọc thông tin từ DonDatHang và ChiTiet_DonDatHang
    SELECT 
        @TongSoLuongDat = SUM(DDH.SOLUONG_DATHANG),
		@TongSoLuongGiao = SUM(NH.SOLUONG_NHAPHANG)
    FROM CHITIET_DONDATHANG DDH WITH (HOLDLOCK, ROWLOCK) -- Khóa hàng để tránh thay đổi
    JOIN CHITIET_NHAPHANG NH WITH (HOLDLOCK, ROWLOCK)
	ON NH.MA_SANPHAM = DDH.MA_SANPHAM
	WHERE MA_DONDATHANG = @MaDonDatHang
	GROUP BY DDH.MA_DONDATHANG

    -- 1.2 So sánh tổng số lượng đặt và giao, cập nhật trạng thái nếu đã xử lý xong
    IF @TongSoLuongDat = @TongSoLuongGiao
    BEGIN
        UPDATE DONDATHANG WITH (UPDLOCK, ROWLOCK) -- Khóa để cập nhật trạng thái
        SET TINHTRANG = N'Đã xử lý'
        WHERE MA_DONDATHANG = @MaDonDatHang
    END

    -- Kiểm tra lỗi, nếu có rollback giao dịch
    IF @@ERROR <> 0
    BEGIN
        ROLLBACK TRANSACTION;
        RETURN;
    END

    -- Commit giao dịch nếu không có lỗi
    COMMIT TRANSACTION;
END
GO

-- Thêm sản phẩm vào kho hàng, cập nhật lại số lượng tồn kho trong kho hàng, thống kê vào bảng ChiTiet_ThongKe_Kho_HangNgay và gọi sp_XuLyDonDatHang để cập nhật lại số lượng đã giao chuyển đổi tình trạng của đơn đó là "Đã xử lý" hay chưa.
USE QLITHONGTINHETHONGSIEUTHI
GO

CREATE PROCEDURE sp_ThemSanPhamVaoKho
    @MaSanPham CHAR(10),
    @SoLuongNhap INT,
    @NgayNhap DATE
AS
BEGIN
    -- Thiết lập TRANSACTION để đảm bảo tính toàn vẹn dữ liệu
    BEGIN TRANSACTION;

    -- Thiết lập mức độ ISOLATION để tránh tranh chấp dữ liệu
    SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;

    -- Khai báo biến
    DECLARE @SoLuongConLai INT

    -- 1.1 Đọc thông tin sản phẩm từ bảng KhoHang
    -- Khóa các dòng để tránh tranh chấp khi đọc và cập nhật
    SELECT @SoLuongConLai = SoLuong_ConLai
    FROM SANPHAM WITH (HOLDLOCK, ROWLOCK)
    WHERE MA_SANPHAM = @MaSanPham

    -- 1.2 Cập nhật số lượng tồn kho
    -- Sử dụng UPDLOCK để khóa dòng khi cập nhật
    UPDATE SANPHAM WITH (UPDLOCK, ROWLOCK)
    SET SoLuong_ConLai = SoLuong_ConLai + @SoLuongNhap
    WHERE MA_SANPHAM = @MaSanPham

    -- 1.3 Ghi nhận thông tin nhập kho vào bảng ChiTiet_NhapHang
    -- Sử dụng UPDLOCK để khóa dòng khi ghi nhận thông tin nhập kho
    UPDATE CHITIET_NHAPHANG WITH (UPDLOCK, ROWLOCK)
    SET MA_SANPHAM = @MaSanPham,
        SOLUONG_NHAPHANG = @SoLuongNhap
    WHERE MA_SANPHAM = @MaSanPham

	-- Cập nhật ngày nhập kho vào NHAPHANG
	UPDATE NHAPHANG WITH (UPDLOCK, ROWLOCK)
	SET NGAY_NHAPHANG = @NgayNhap
	FROM CHITIET_NHAPHANG CT 
	WHERE CT.MA_NHAPHANG = NHAPHANG.MA_NHAPHANG AND CT.MA_SANPHAM = @MaSanPham

    -- 1.4 Cập nhật thông tin thống kê kho vào bảng ChiTiet_ThongKe_Kho_HangNgay
    -- Cập nhật tồn kho và số lượng cần đặt
    UPDATE ChiTiet_ThongKe_Kho_HangNgay WITH (UPDLOCK, ROWLOCK)
    SET SOLUONG_TONKHO = @SoLuongConLai + @SoLuongNhap,
        ThoiGian_ThongKe = GETDATE(),
        SoLuong_CanDat = 0
    WHERE MA_SANPHAM = @MaSanPham

    -- Gọi sp_XuLyDonDatHang để xử lý các đơn hàng bị ảnh hưởng sau khi nhập kho
    EXEC sp_XuLyDonDatHang @MaSanPham

    -- Kiểm tra lỗi, nếu có rollback giao dịch
    IF @@ERROR <> 0
    BEGIN
        -- Nếu có lỗi, rollback giao dịch
        ROLLBACK TRANSACTION
        RETURN
    END

    -- Commit giao dịch nếu không có lỗi
    COMMIT TRANSACTION
END
GO

--NGÂN: Bộ phận quản lý ngành hàng
CREATE PROCEDURE sp_CapNhatSoLuongSanPhamKhuyenMai
    @MaDonHang CHAR(10)
AS
BEGIN
    SET NOCOUNT ON;

    -- Temporary table to store relevant details
    SELECT MA_SANPHAM, SOLUONG
    INTO #ChiTietDonHang
    FROM CHITIET_DONHANG
    WHERE MA_DONHANG = @MaDonHang AND GIATRIKHUYENMAI > 0;

    -- Declare variables for cursor
    DECLARE @MaSanPham CHAR(10);
    DECLARE @SoLuong INT;

    -- Cursor declaration
    DECLARE sp_cursor CURSOR LOCAL FORWARD_ONLY READ_ONLY FOR
    SELECT MA_SANPHAM, SOLUONG
    FROM #ChiTietDonHang;

    -- Open the cursor
    OPEN sp_cursor;

    -- Begin transaction scope
    BEGIN TRY
        FETCH NEXT FROM sp_cursor INTO @MaSanPham, @SoLuong;

        WHILE @@FETCH_STATUS = 0
        BEGIN
            BEGIN TRANSACTION;

            -- Check and update the appropriate table
            IF EXISTS (SELECT 1 FROM SANPHAM_KHUYENMAI WHERE MA_SANPHAM = @MaSanPham)
            BEGIN
                UPDATE SANPHAM_KHUYENMAI WITH (ROWLOCK)
                SET SOLUONG_SANPHAM_KHUYENMAI = SOLUONG_SANPHAM_KHUYENMAI - @SoLuong
                WHERE MA_SANPHAM = @MaSanPham;
            END
            ELSE
            BEGIN
                UPDATE SANPHAM_KHUYENMAI_COMBO WITH (ROWLOCK)
                SET SOLUONG_SANPHAM_KHUYENMAI = SOLUONG_SANPHAM_KHUYENMAI - @SoLuong
                WHERE MA_SANPHAM_1 = @MaSanPham OR MA_SANPHAM_2 = @MaSanPham;
            END;

            -- Commit the transaction
            COMMIT TRANSACTION;

            FETCH NEXT FROM sp_cursor INTO @MaSanPham, @SoLuong;
        END;

        -- Clean up
        CLOSE sp_cursor;
        DEALLOCATE sp_cursor;

        PRINT N'Cập nhật thành công số lượng sản phẩm khuyến mãi.';
    END TRY
    BEGIN CATCH
        -- Rollback if an error occurs
        IF XACT_STATE() <> 0
        BEGIN
            ROLLBACK TRANSACTION;
        END;

        -- Close and deallocate the cursor if an error occurs
        IF CURSOR_STATUS('local', 'sp_cursor') >= 0
        BEGIN
            CLOSE sp_cursor;
            DEALLOCATE sp_cursor;
        END;

        -- Print the error message
        PRINT N'Lỗi xảy ra: ' + ERROR_MESSAGE();
    END CATCH;

    -- Drop the temporary table
    DROP TABLE #ChiTietDonHang;
END;
GO

EXEC sp_CapNhatSoLuongSanPhamKhuyenMai 'DH001';
GO

--Cập nhật tình trạng chi tiết khuyến mãi
CREATE PROCEDURE sp_CapNhatTinhTrangChiTietKhuyenMai
AS
BEGIN
    -- Declare variables
    DECLARE @MaChuongTrinh CHAR(10), @NgayKetThuc DATE;

    -- Cursor to iterate through active promotion
    DECLARE chuongtrinh_cursor CURSOR LOCAL FORWARD_ONLY READ_ONLY FOR
    SELECT MA_CTKM, THOIGIANKETTHUC
    FROM CHUONGTRINH_KHUYENMAI

    OPEN chuongtrinh_cursor;

    FETCH NEXT FROM chuongtrinh_cursor INTO @MaChuongTrinh, @NgayKetThuc;

    -- Iterate over all promotion programs
    WHILE @@FETCH_STATUS = 0
    BEGIN
        BEGIN TRANSACTION;
        SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;

        -- Check if the promotion program has ended or if any conditions require inactivation
        IF @NgayKetThuc < GETDATE()
        BEGIN
            -- Update the status of the promotion details to 'Inactive' if the program has ended
            UPDATE SANPHAM_KHUYENMAI
            SET TINHTRANG = 'Inactive'
            WHERE MA_CHUONGTRINH = @MaChuongTrinh;

            UPDATE SANPHAM_KHUYENMAI_COMBO
            SET TINHTRANG = 'Inactive'
            WHERE MA_CHUONGTRINH = @MaChuongTrinh;
        END
        ELSE
        BEGIN
            -- If the quantity of promotional products is zero or stock is zero, update status to 'Inactive'
            UPDATE SANPHAM_KHUYENMAI
            SET TINHTRANG = 'Inactive'
            WHERE SOLUONG_SANPHAM_KHUYENMAI = 0
               OR MA_SANPHAM IN (SELECT MA_SANPHAM FROM SANPHAM WHERE SOLUONG_CONLAI = 0);

            UPDATE SANPHAM_KHUYENMAI_COMBO
            SET TINHTRANG = 'Inactive'
            WHERE SOLUONG_SANPHAM_KHUYENMAI = 0
               OR MA_SANPHAM_1 IN (SELECT MA_SANPHAM FROM SANPHAM WHERE SOLUONG_CONLAI = 0)
               OR MA_SANPHAM_2 IN (SELECT MA_SANPHAM FROM SANPHAM WHERE SOLUONG_CONLAI = 0);
        END

        -- Commit the transaction after updating the status
        COMMIT TRANSACTION;

        -- Fetch the next promotion program
        FETCH NEXT FROM chuongtrinh_cursor INTO @MaChuongTrinh, @NgayKetThuc;
    END;

    -- Close and deallocate the cursor
    CLOSE chuongtrinh_cursor;
    DEALLOCATE chuongtrinh_cursor;

    PRINT N'Cập nhật tình trạng chi tiết khuyến mãi hoàn tất.';
END;
GO

exec sp_CapNhatTinhTrangChiTietKhuyenMai;
GO
    




--NHÂN: Bộ phận kinh doanh
--Thống kê sản phẩm đã bán theo ngày
CREATE PROCEDURE sp_ThongKeSanPhamDaBanTheoNgay
    @Ngay DATE
AS
BEGIN
    BEGIN TRY
        BEGIN TRANSACTION;
        SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;

        -- Insert aggregated results directly into THONGKE_SANPHAM
        -- Insert aggregated results directly into THONGKE_SANPHAM
        INSERT INTO THONGKE_SANPHAM WITH (TABLOCKX)(THOIGIAN_THONGKE, MA_SANPHAM, SOLUONG_SANPHAM, SOLUONG_KHACHHANG_MUASANPHAM, TONG_DOANHTHU_SANPHAM)
        SELECT 
            @Ngay AS THOIGIAN_THONGKE,
            CTDH.MA_SANPHAM,
            SUM(CTDH.SOLUONG) AS SOLUONG_SANPHAM,
            COUNT(DISTINCT DH.MA_DONHANG) AS SOLUONG_KHACHHANG_MUASANPHAM,
            SUM(CTDH.SOLUONG * CTDH.GIABAN) AS TONG_DOANHTHU_SANPHAM
        FROM 
            CHITIET_DONHANG AS CTDH
        JOIN 
            DONHANG AS DH ON CTDH.MA_DONHANG = DH.MA_DONHANG
        WHERE 
            --LAY NGAY TAO DON HANG
            CAST(DH.NGAYTAO AS DATE) = @Ngay
        GROUP BY 
            CTDH.MA_SANPHAM
        ORDER BY 
            SUM(CTDH.SOLUONG) DESC;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        -- Rollback the transaction in case of errors
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        -- Return the error
        THROW;
    END CATCH
END;
GO


--Thống kê doanh số theo ngày
CREATE PROCEDURE sp_ThongKeDoanhSoTheoNgay
    @Ngay DATE
AS
BEGIN
    BEGIN TRY
        BEGIN TRANSACTION;
        SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;

        -- Insert aggregated sales data directly into the summary table
        INSERT INTO THONGKE_DOANHSO WITH (TABLOCKX)(THOIGIAN_THONGKE, TONG_DOANHTHU, TONG_KHACHHANG)
        SELECT 
            @Ngay AS THOIGIAN_THONGKE,
            CAST(SUM(TONGGIATRI) AS DEC(20,3)) AS TONG_DOANHTHU,
            COUNT(DISTINCT MA_DONHANG) AS TONG_KHACHHANG
        FROM 
            DONHANG
        WHERE 
            CAST(NGAYTAO AS DATE) = @Ngay;

        -- Commit the transaction
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        -- Rollback the transaction in case of an error
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        -- Rethrow the error
        THROW;
    END CATCH;
END;
GO


--HUY: Bộ phận chăm sóc khách hàng
-- STORED PROCEDURE PHỤ

-- Cập nhật tổng tiền mua sắm theo tháng
-- Chạy sau giờ làm việc vào cuối tháng nếu sử dụng riêng lẻ
-- Tính tổng hết hoá đơn của tháng đó của khách hàng và cập nhật TONGCHITIEU
CREATE OR ALTER PROCEDURE sp_CapNhatTongTienMuaSamTrongNam
    @MaKhachHang CHAR(10), @NgayCapNhat DATE
AS
BEGIN
    -- Bắt đầu giao dịch
    BEGIN TRANSACTION

    -- Đặt mức cô lập là REPEATABLE READ
    SET TRANSACTION ISOLATION LEVEL REPEATABLE READ

    BEGIN TRY
        -- 1. Lấy tổng giá trị các hóa đơn của tháng hiện tại
        DECLARE @TongTienThang INT = 0;

        SELECT @TongTienThang = SUM(TONGGIATRI)
        FROM DONHANG WITH (ROWLOCK)
        WHERE MA_KHACHHANG = @MaKhachHang
          AND MONTH(NGAYTAO) = MONTH(@NgayCapNhat)
          AND YEAR(NGAYTAO) = YEAR(@NgayCapNhat);

        -- Nếu không có hóa đơn trong tháng, đặt tổng tiền là 0
        IF @TongTienThang IS NULL
            SET @TongTienThang = 0;

        -- 2. Cập nhật tổng tiền mua sắm trong năm vào bảng KHACHHANG
        UPDATE KHACHHANG WITH (ROWLOCK)
        SET TongChiTieu = ISNULL(TongChiTieu, 0) + @TongTienThang
        WHERE MA_KHACHHANG = @MaKhachHang;

        -- Commit giao dịch
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        -- Rollback giao dịch nếu xảy ra lỗi
        ROLLBACK TRANSACTION;
        -- Ném lỗi ra ngoài
        THROW;
    END CATCH
END;
GO


-- Ghi nhận phân hạng vào cuối năm và chuyển thành Phân hạng năm trước
-- Set mới phân hạng thành Thân thiết và tổng chi tiêu năm mới bằng 0
CREATE OR ALTER PROCEDURE sp_GhiNhanPhanHangMoiNam
    @MaKhachHang CHAR(10)
AS
BEGIN
    -- Bắt đầu giao dịch
    BEGIN TRANSACTION;

    -- Thiết lập mức độ cô lập giao dịch
    SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;

    -- Thực hiện cập nhật thông tin của khách hàng
    UPDATE KHACHHANG WITH (ROWLOCK)
    SET 
        PHANHANG_NAMTRUOC = TEN_PHANHANG,	-- Lưu phân hạng năm trước
		TEN_PHANHANG = N'Thân thiết',		-- Reset về Thân thiết qua năm mới
        TONGCHITIEU = 0						-- Reset tổng chi tiêu qua năm mới
    WHERE MA_KHACHHANG = @MaKhachHang;

    -- Commit giao dịch
    COMMIT TRANSACTION;
END;
GO


-- Tạo phiếu sinh nhật dựa trên phân hạng năm trước
-- Ngày cấp phiếu là ngày đầu của tháng sinh
CREATE OR ALTER PROCEDURE sp_TaoPhieuSinhNhat
    @Ma_KhachHang CHAR(10), 
    @NgayCapPhieu DATE
AS
BEGIN
    -- Thiết lập mức độ cô lập của giao dịch
    SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;

    BEGIN TRY
        -- 1. Kiểm tra phân hạng năm trước trong bảng KhachHang
        DECLARE @PhanHangTruoc NVARCHAR(50);

        SELECT @PhanHangTruoc = PHANHANG_NAMTRUOC
        FROM KhachHang WITH (HOLDLOCK, ROWLOCK)
        WHERE MA_KHACHHANG = @Ma_KhachHang;

        -- 1.1. Nếu phân hạng là "Thân thiết", kết thúc thủ tục
        IF @PhanHangTruoc = N'Thân thiết'
        BEGIN
            RETURN 1; -- Trả về 1: Không tạo phiếu
        END

        -- 1.2. Nếu không phải "Thân thiết", tiếp tục tạo phiếu
        DECLARE @GiaTriPhieu FLOAT;

        -- 1.2.1. Đối chiếu giá trị phiếu từ bảng PhanHang
        SELECT @GiaTriPhieu = GIATRI_PHIEUTANG
        FROM PHANHANG WITH (HOLDLOCK, ROWLOCK)
        WHERE TEN_PHANHANG = @PhanHangTruoc;

        -- 1.2.2. Tạo bản ghi mới trong bảng PhieuSinhNhat
        INSERT INTO PhieuSinhNhat (MA_KHACHHANG, NGAYPHATHANH, TRANGTHAI_PHIEUSINHNHAT, GIATRIPHIEU)
        VALUES (
            @Ma_KhachHang, @NgayCapPhieu, N'Active', @GiaTriPhieu
        );

        RETURN 0; -- Trả về 0: Tạo phiếu thành công
    END TRY
    BEGIN CATCH
        -- Xử lý lỗi nội bộ
        THROW;
    END CATCH
END;
GO


-- STORED PROCEDURE CHÍNH

-- Phân hạng khách hàng dựa trên số tiền của năm nay
-- Nếu là tháng 1-11, tính tổng hoá đơn của tháng cộng vào TONGCHITIEU và cập nhật phân hạng
-- Nếu là tháng 12, chạy tương tự rồi chuyển thông tin về năm trước và tính lại năm sau
-- Chạy vào ngày 31/12 của năm sau giờ làm việc
CREATE OR ALTER PROCEDURE sp_PhanHangKhachHang
    @NgayPhanHang DATE
AS
BEGIN
    -- Bắt đầu giao dịch
    BEGIN TRANSACTION;

    -- Thiết lập mức cô lập giao dịch
    SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;

    BEGIN TRY
        -- 1. Khai báo cursor để duyệt từng khách hàng
        DECLARE KhachHang_Cursor CURSOR FOR
        SELECT MA_KHACHHANG, ISNULL(TONGCHITIEU, 0) AS TONGCHITIEU, TEN_PHANHANG
        FROM KHACHHANG WITH (ROWLOCK);

        OPEN KhachHang_Cursor;

        DECLARE @MaKhachHang CHAR(10);
        DECLARE @TongTienMuaSam FLOAT;
        DECLARE @PhanHangNamNay NVARCHAR(50);

        -- Duyệt qua từng khách hàng
        FETCH NEXT FROM KhachHang_Cursor INTO @MaKhachHang, @TongTienMuaSam, @PhanHangNamNay;

        WHILE @@FETCH_STATUS = 0
        BEGIN
            -- 1.1. Cập nhật tổng tiền mua sắm
            EXEC sp_CapNhatTongTienMuaSamTrongNam @MaKhachHang, @NgayPhanHang;

			-- 1.2. Fetch lại tổng tiền mới
			SELECT @TongTienMuaSam = ISNULL(TONGCHITIEU, 0)
			FROM KHACHHANG WITH (ROWLOCK)
			WHERE MA_KHACHHANG = @MaKhachHang;

            -- 1.3. Nếu là tháng 12, reset thông tin năm trước
            IF MONTH(@NgayPhanHang) = 12
                BEGIN
                    -- 1.4. Xác định phân hạng mới dựa trên tổng tiền
                    DECLARE @PhanHangMoi NVARCHAR(50);

                    SELECT TOP 1 @PhanHangMoi = TEN_PHANHANG
                    FROM PHANHANG WITH (ROWLOCK)
                    WHERE ISNULL(@TongTienMuaSam, 0) >= TIENTOITHIEU
                    ORDER BY TIENTOITHIEU DESC;

                    -- 1.5. Cập nhật phân hạng vào bảng KHACHHANG
                    UPDATE KHACHHANG WITH (ROWLOCK)
                    SET TEN_PHANHANG = @PhanHangMoi
                    WHERE MA_KHACHHANG = @MaKhachHang;

                    -- 1.6. Ghi nhận lại phân hạng về năm trước và reset
                    EXEC sp_GhiNhanPhanHangMoiNam @MaKhachHang;
                END
            ELSE
                BEGIN
                    -- 1.5. Xác định phân hạng mới dựa trên tổng tiền
                    DECLARE @PhanHangMoiTrongNam NVARCHAR(50);

                    SELECT TOP 1 @PhanHangMoiTrongNam = TEN_PHANHANG
                    FROM PHANHANG WITH (ROWLOCK)
                    WHERE ISNULL(@TongTienMuaSam, 0) >= TIENTOITHIEU
                    ORDER BY TIENTOITHIEU DESC;

                    -- 1.6. Cập nhật phân hạng vào bảng KHACHHANG
                    UPDATE KHACHHANG WITH (ROWLOCK)
                    SET TEN_PHANHANG = @PhanHangMoiTrongNam
                    WHERE MA_KHACHHANG = @MaKhachHang;
                END;

            FETCH NEXT FROM KhachHang_Cursor INTO @MaKhachHang, @TongTienMuaSam, @PhanHangNamNay;
        END;

        -- Đóng và giải phóng cursor
        CLOSE KhachHang_Cursor;
        DEALLOCATE KhachHang_Cursor;

        -- Commit giao dịch
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        -- Rollback nếu xảy ra lỗi
        ROLLBACK TRANSACTION;

        -- Hiển thị lỗi
        THROW;
    END CATCH
END;
GO


-- Gửi tặng phiếu sinh nhật cho các khách hàng trong tháng đó dựa trên phân hạng năm ngoái
-- Chạy vào ngày đầu tháng tức ngày 01 trước giờ làm việc
CREATE OR ALTER PROCEDURE sp_GuiQuaSinhNhat
    @NgayHienTai DATE
AS
BEGIN
    -- Bắt đầu giao dịch
    BEGIN TRANSACTION;

    -- Thiết lập mức cô lập giao dịch
    SET TRANSACTION ISOLATION LEVEL READ COMMITTED;

    BEGIN TRY
        -- 1. Lọc các khách hàng có tháng sinh trùng với tháng trong @NgayHienTai
        DECLARE KhachHang_Cursor CURSOR FOR
        SELECT MA_KHACHHANG
        FROM KHACHHANG
        WHERE MONTH(NGAYSINH) = MONTH(@NgayHienTai);

        OPEN KhachHang_Cursor;

        DECLARE @MaKhachHang CHAR(10);
        DECLARE @Result INT;

        -- Duyệt qua từng khách hàng
        FETCH NEXT FROM KhachHang_Cursor INTO @MaKhachHang;

        WHILE @@FETCH_STATUS = 0
        BEGIN
            -- 2. Gọi sp_TaoPhieuSinhNhat để tạo phiếu sinh nhật
            EXEC @Result = sp_TaoPhieuSinhNhat @MaKhachHang, @NgayHienTai;

            FETCH NEXT FROM KhachHang_Cursor INTO @MaKhachHang;
        END;

        -- Đóng và giải phóng cursor
        CLOSE KhachHang_Cursor;
        DEALLOCATE KhachHang_Cursor;

        -- Commit giao dịch
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        -- Rollback nếu có lỗi
        ROLLBACK TRANSACTION;

        -- Hiển thị lỗi
        THROW;
    END CATCH
END;
GO





