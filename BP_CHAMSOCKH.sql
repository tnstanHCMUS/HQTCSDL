USE QLITHONGTINHETHONGSIEUTHI
GO

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
    @Ma_KhachHang CHAR(10), @NgayCapPhieu DATE
AS
BEGIN
    -- Bắt đầu giao dịch
    BEGIN TRANSACTION;

    -- Thiết lập mức độ cô lập của giao dịch
    SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;

    -- 1. Kiểm tra phân hạng năm trước trong bảng KhachHang
    DECLARE @PhanHangTruoc NVARCHAR(50);

    SELECT @PhanHangTruoc = PHANHANG_NAMTRUOC
    FROM KhachHang WITH (HOLDLOCK, ROWLOCK)
    WHERE MA_KHACHHANG = @Ma_KhachHang;

    -- 1.1. Nếu phân hạng là "Thân thiết", kết thúc thủ tục
    IF @PhanHangTruoc = N'Thân thiết'
    BEGIN
        ROLLBACK TRANSACTION;
        RETURN;
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

    -- Commit giao dịch
    COMMIT TRANSACTION;
END;