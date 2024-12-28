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

--Tự động đặt sản phẩm nếu thiếu và đủ điều kiện đặt
CREATE PROCEDURE sp_DatHang
AS
BEGIN
    SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;

    DECLARE @MA_SANPHAM CHAR(10), @SOLUONG_CONLAI INT, @SOLUONG_TOIDA INT;
    DECLARE @SoLuongChuaGiao INT, @SoLuongDat INT;
    DECLARE @DonDatHangID CHAR(10), @NhaSanXuatHienTai CHAR(10), @NhaSanXuatTruoc CHAR(10) = NULL;

    BEGIN TRANSACTION;

    DECLARE product_cursor CURSOR LOCAL FORWARD_ONLY READ_ONLY FOR
    SELECT MA_SANPHAM, SOLUONG_CONLAI, SOLUONG_TOIDA, MA_NHASANXUAT
    FROM SANPHAM;

    OPEN product_cursor;
    FETCH NEXT FROM product_cursor INTO @MA_SANPHAM, @SOLUONG_CONLAI, @SOLUONG_TOIDA, @NhaSanXuatHienTai;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        SELECT @SoLuongChuaGiao = SOLUONG_CONNO
        FROM ChiTiet_ThongKe_Kho_HangNgay WITH (ROWLOCK)
        WHERE MA_SANPHAM = @MA_SANPHAM AND THOIGIAN_THONGKE = CAST(GETDATE() AS DATE);

        IF @SOLUONG_CONLAI < 0.7 * @SOLUONG_TOIDA
        BEGIN
            SET @SoLuongDat = @SOLUONG_TOIDA - @SOLUONG_CONLAI - ISNULL(@SoLuongChuaGiao, 0);

            IF @SoLuongDat >= 0.1 * @SOLUONG_TOIDA
            BEGIN
                IF @NhaSanXuatTruoc IS NULL OR @NhaSanXuatTruoc <> @NhaSanXuatHienTai
                BEGIN
                    DECLARE @MaxOrderID CHAR(10), @NewOrderID CHAR(10);
                    SELECT @MaxOrderID = MAX(MA_DONDATHANG) FROM DonDatHang WHERE MA_DONDATHANG LIKE 'DDH%';

                    IF @MaxOrderID IS NULL
                    BEGIN
                        SET @NewOrderID = 'DDH001';
                    END
                    ELSE
                    BEGIN
                        DECLARE @CurrentNumber INT;
                        SET @CurrentNumber = CAST(SUBSTRING(@MaxOrderID, 4, 3) AS INT) + 1;
                        SET @NewOrderID = 'DDH' + RIGHT('000' + CAST(@CurrentNumber AS VARCHAR(3)), 3);
                    END

                    INSERT INTO DonDatHang (MA_DONDATHANG, NGAYDATHANG, MA_NHASANXUAT, TINHTRANG)
                    VALUES (
                        @NewOrderID,
                        GETDATE(),
                        @NhaSanXuatHienTai,
                        N'Chưa xử lý'
                    );

                    SET @DonDatHangID = @NewOrderID;
                END

                IF NOT EXISTS (
                    SELECT 1
                    FROM CHITIET_DONDATHANG
                    WHERE MA_DONDATHANG = @DonDatHangID AND MA_SANPHAM = @MA_SANPHAM
                )
                BEGIN
                    INSERT INTO CHITIET_DONDATHANG (MA_DONDATHANG, MA_SANPHAM, SOLUONG_DATHANG)
                    VALUES (@DonDatHangID, @MA_SANPHAM, @SoLuongDat);
                END
            END
        END

        SET @NhaSanXuatTruoc = @NhaSanXuatHienTai;

        FETCH NEXT FROM product_cursor INTO @MA_SANPHAM, @SOLUONG_CONLAI, @SOLUONG_TOIDA, @NhaSanXuatHienTai;
    END

    CLOSE product_cursor;
    DEALLOCATE product_cursor;

    COMMIT TRANSACTION;

    IF @@ERROR <> 0
    BEGIN
        ROLLBACK TRANSACTION;
        RETURN;
    END
END;


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
    --EXEC sp_XuLyDonDatHang @MaSanPham

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
    FROM KHOHANG WITH (HOLDLOCK, ROWLOCK)
    WHERE MA_SANPHAM = @MaSanPham

    -- 1.2 Cập nhật số lượng tồn kho
    -- Sử dụng UPDLOCK để khóa dòng khi cập nhật
    UPDATE KHOHANG WITH (UPDLOCK, ROWLOCK)
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

-- Xoá khách hàng
CREATE OR ALTER PROCEDURE sp_XoaKhachHang
    @MaKhachHang CHAR(10)
AS
BEGIN
    -- Bắt đầu giao dịch
    BEGIN TRANSACTION;

    -- Thiết lập mức cô lập giao dịch
    SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;

    -- Xoá khách hàng
    DELETE FROM KHACHHANG WHERE MA_KHACHHANG = 'KH100';

    COMMIT TRANSACTION;

END;
GO