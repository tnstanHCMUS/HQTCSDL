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
        ROLLBACK TRANSACTION;
        RETURN;
    END

    -- Commit transaction nếu không có lỗi
    COMMIT TRANSACTION;
END
