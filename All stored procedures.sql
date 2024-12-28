USE QLITHONGTINHETHONGSIEUTHI
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
        SELECT TOP 1 @Muc_GiamGia = MUC_GIAMGIA
        FROM SANPHAM_KHUYENMAI
        WHERE MA_SANPHAM = @MaSanPham AND TINHTRANG = 'Active'

        IF @Muc_GiamGia > 0
        BEGIN
            COMMIT TRANSACTION
            RETURN
        END

        SELECT TOP 1 @Muc_GiamGia = MUC_GIAMGIA
        FROM SANPHAM_KHUYENMAI_COMBO
        WHERE (MA_SANPHAM_1 = @MaSanPham OR MA_SANPHAM_2 = @MaSanPham) AND TINHTRANG = 'Active'

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
CREATE PROCEDURE sp_TaoChiTietDonHang
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

--Tạo đơn hàng cho khách hàng: tạo đơn hàng cho khách hàng dựa trên thông tin đơn hàng và khách hàng
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

    -- Check if customer exists
    IF NOT EXISTS (SELECT 1 FROM KHACHHANG WHERE MA_KHACHHANG = @MaKhachHang)
    BEGIN
        PRINT N'Khách hàng không tồn tại.';
        RETURN;
    END;

    -- Check if voucher exists and is valid
    DECLARE @GiaTriPhieu INT;
    IF NOT EXISTS (
        SELECT 1
        FROM PHIEUMUAHANG
        WHERE MA_PHIEUMUAHANG = @MaPhieuMuaHang
        AND TRANGTHAI_PHIEUMUAHANG = 'Active' -- Check if the voucher is active
        AND GETDATE() BETWEEN NGAYAPDUNG AND NGAYHETHAN
    )
    BEGIN
        PRINT N'Phiếu mua hàng không hợp lệ, đã dùng hoặc hết hạn.';
        SET @GiaTriPhieu = 0;
    END
    ELSE
    BEGIN
        -- Get the voucher value
        SELECT @GiaTriPhieu = GIATRI_PHIEUMUAHANG
        FROM PHIEUMUAHANG
        WHERE MA_PHIEUMUAHANG = @MaPhieuMuaHang;

        PRINT N'Phiếu mua hàng hợp lệ. Giá trị phiếu: ' + CAST(@GiaTriPhieu AS NVARCHAR(20));
    END


    BEGIN TRANSACTION;
    BEGIN TRY
        -- Declare variables cho đơn hàng
        DECLARE @MaDonHang CHAR(10);
        DECLARE @TongTienDonHang INT = 0;
        
        -- Generate order ID in DH001 format tạo mã đơn hàng
        DECLARE @LastOrderNumber CHAR(10);
        IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'DONHANG') --tim table DONHANG
        BEGIN
            PRINT N'Bảng DONHANG không tồn tại.';
            RETURN;
        END;

        --Lấy mã đơn hàng cuối cùng từ bảng DONHANG
        SELECT @LastOrderNumber = MA_DONHANG FROM DONHANG
        WHERE MA_DONHANG = (SELECT MAX(MA_DONHANG) FROM DONHANG);
        IF @LastOrderNumber IS NULL
        BEGIN
            SET @LastOrderNumber = 0;
        END;
        
        IF @LastOrderNumber IS NULL
BEGIN
    SET @LastOrderNumber = 'DH001';  -- If no order exists, start with 'DH000'
END;

    -- Remove the 'DH' prefix and trim spaces before converting to INT
    DECLARE @NumericPart INT;
    SET @NumericPart = CAST(LTRIM(RTRIM(SUBSTRING(@LastOrderNumber, 3, LEN(@LastOrderNumber) - 2))) AS INT);

    -- Increment the numeric part
    SET @NumericPart = @NumericPart + 1;

    -- Create the new order number with a leading 'DH' and 3-digit format
    SET @MaDonHang = 'DH' + RIGHT('000' + CAST(@NumericPart AS VARCHAR(10)), 3);

    -- You can now use @MaDonHang in your logic
    PRINT @MaDonHang;

        --Chèn bản ghi vào bảng DONHANG
        INSERT INTO DONHANG (MA_DONHANG, MA_KHACHHANG, MA_PHIEUMUAHANG, TONGGIATRI, HINHTHUC_MUAHANG, TRANGTHAI_DONHANG, NGAYTAO, PHUONGTHUC_THANHTOAN, TRANGTHAI_THANHTOAN)
        VALUES (@MaDonHang, @MaKhachHang, @MaPhieuMuaHang, NULL, @HinhThucMuaHang, NULL, GETDATE(), @PhuongThucThanhToan, @TinhTrangThanhToan);

        -- Create order details
        EXEC sp_TaoChiTietDonHang @MaDonHang, @DanhSachMaSanPham;

        -- Calculate total order value
        SELECT @TongTienDonHang = SUM(GIABAN * SOLUONG - GIATRIKHUYENMAI)
        FROM CHITIET_DONHANG
        WHERE MA_DONHANG = @MaDonHang;

        -- Apply voucher value
        IF @GiaTriPhieu > @TongTienDonHang
        BEGIN
            SET @TongTienDonHang = 0;
        END
        ELSE
        BEGIN
            SET @TongTienDonHang = @TongTienDonHang - @GiaTriPhieu;
        END;

        -- Mark voucher as used
        UPDATE PHIEUMUAHANG
        SET TRANGTHAI_PHIEUMUAHANG = N'Inactive'
        WHERE MA_PHIEUMUAHANG = @MaPhieuMuaHang;

        -- Update order total value
        UPDATE DONHANG
        SET TONGGIATRI = @TongTienDonHang
        WHERE MA_DONHANG = @MaDonHang;

        --UPDATE TRANGTHAI_DONHANG
        UPDATE DONHANG
        SET TRANGTHAI_DONHANG = N'Đã xử lý'
        WHERE MA_DONHANG = @MaDonHang;

        -- Commit transaction
        COMMIT TRANSACTION;

        PRINT N'Tạo đơn hàng thành công với mã đơn: ' + @MaDonHang;
    END TRY
    BEGIN CATCH
        -- Check the transaction state before rolling back
        IF XACT_STATE() = -1
        BEGIN
            ROLLBACK TRANSACTION;
            PRINT N'Lỗi nghiêm trọng, giao dịch đã bị hủy.';
        END
        ELSE IF XACT_STATE() = 1
        BEGIN
            ROLLBACK TRANSACTION;
            PRINT N'Lỗi xảy ra, giao dịch đã bị hoàn tác.';
        END
        ELSE
        BEGIN
            PRINT N'Không có giao dịch nào để hoàn tác.';
        END;

        -- Print the error message
        PRINT N'Lỗi xảy ra trong quá trình tạo đơn hàng: ' + ERROR_MESSAGE();
    END CATCH;
END;
GO



