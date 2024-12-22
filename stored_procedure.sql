-- SP_ThongKeKho
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
        KH.MA_SANPHAM,
        SUM(ISNULL(KH.SOLUONG_CONLAI, 0)) AS SoLuongTon,
        ISNULL(SUM(CTDDH.SOLUONG_DATHANG), 0) AS SoLuongDat,
        (ISNULL(SUM(CTDDH.SOLUONG_DATHANG), 0) - ISNULL(SUM(NH.SOLUONG_NHAPHANG), 0)) AS SoLuongConNo
    FROM 
        KHOHANG KH
        LEFT JOIN CHITIET_NHAPHANG NH ON NH.MA_SANPHAM = KH.MA_SANPHAM
        LEFT JOIN CHITIET_DONDATHANG CTDDH ON CTDDH.MA_SANPHAM = KH.MA_SANPHAM
        LEFT JOIN DONDATHANG DDH ON DDH.MA_DONDATHANG = CTDDH.MA_DONDATHANG
    WHERE 
        DDH.NGAYDATHANG = @NgayThongKe AND DDH.TINHTRANG = N'Đang xử lý'
    GROUP BY 
        KH.MA_SANPHAM;

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
--SP_DatHang
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
    FROM KHOHANG WITH (TABLOCKX) -- Khóa bảng để đảm bảo không có thay đổi song song

    -- Biến để lưu trữ thông tin sản phẩm từ con trỏ
    DECLARE @MA_SANPHAM INT, @SOLUONG_CONLAI INT, @SOLUONG_TOIDA INT

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