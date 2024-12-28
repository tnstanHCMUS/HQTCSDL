USE QLITHONGTINHETHONGSIEUTHI
GO


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
    -- Bắt đầu giao dịch
    BEGIN TRANSACTION;

    -- Thiết lập mức độ cô lập của giao dịch
    SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;

    BEGIN TRY
        -- 1. Kiểm tra phân hạng năm trước trong bảng KhachHang
        DECLARE @PhanHangTruoc NVARCHAR(50);

        SELECT @PhanHangTruoc = PHANHANG_NAMTRUOC
        FROM KhachHang WITH (ROWLOCK)
        WHERE MA_KHACHHANG = @Ma_KhachHang;

        -- 1.1. Nếu phân hạng là "Thân thiết", kết thúc thủ tục
        IF @PhanHangTruoc = N'Thân thiết'
        BEGIN
            COMMIT TRANSACTION;
            RETURN 1; -- Trả về 1: Không tạo phiếu
        END

        -- 1.2. Nếu không phải "Thân thiết", tiếp tục tạo phiếu
        DECLARE @GiaTriPhieu FLOAT;

        -- 1.2.1. Đối chiếu giá trị phiếu từ bảng PhanHang
        SELECT @GiaTriPhieu = GIATRI_PHIEUTANG
        FROM PHANHANG WITH (ROWLOCK)
        WHERE TEN_PHANHANG = @PhanHangTruoc;

        -- 1.2.2. Tạo bản ghi mới trong bảng PhieuSinhNhat
        INSERT INTO PhieuSinhNhat WITH (TABLOCK)
			(MA_KHACHHANG, NGAYPHATHANH, TRANGTHAI_PHIEUSINHNHAT, GIATRIPHIEU)
        VALUES (
            @Ma_KhachHang, @NgayCapPhieu, N'Active', @GiaTriPhieu
        );

        COMMIT TRANSACTION;
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
        FROM KHACHHANG WITH (ROWLOCK)
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

-- TEST STORED PROCEDURES NẾU CẦN

/*

SELECT * FROM PHANHANG
SELECT * FROM KHACHHANG
SELECT * FROM PHIEUSINHNHAT
SELECT * FROM DONHANG

DELETE FROM DONHANG
DELETE FROM PHIEUSINHNHAT
DELETE FROM KHACHHANG


INSERT INTO KHACHHANG (MA_KHACHHANG, SDT, HOTEN, NGAYSINH, NGAYDANGKY, TEN_PHANHANG, PHANHANG_NAMTRUOC)
VALUES  ('KH00001', '0123456789', N'Nguyễn Văn A', '1999-05-01', '2023-01-01', N'Kim cương', N'Kim cương'),
		('KH00002', '0123456769', N'Nguyễn Thị B', '1999-06-02', '2017-01-02', N'Bạch Kim', N'Bạch Kim'),
		('KH00003', '0123456788', N'Nguyễn Văn C', '1999-07-03', '2018-02-03', N'Vàng', N'Vàng'),
		('KH00004', '0123456787', N'Nguyễn Thị D', '1999-12-04', '2021-01-04', N'Bạc', N'Bạc'),
		('KH00005', '0123456786', N'Nguyễn Văn E', '1999-01-05', '2021-05-05', N'Đồng', N'Đồng'),
		('KH00006', '0123456785', N'Nguyễn Thị F', '1999-08-06', '2020-09-06', N'Thân thiết', N'Thân thiết')
GO


EXEC sp_TaoPhieuSinhNhat 'KH00001', '2024-05-01';
EXEC sp_TaoPhieuSinhNhat 'KH00002', '2024-05-01';
EXEC sp_TaoPhieuSinhNhat 'KH00003', '2024-05-01';
EXEC sp_TaoPhieuSinhNhat 'KH00004', '2024-05-01';
EXEC sp_TaoPhieuSinhNhat 'KH00005', '2024-05-01';
EXEC sp_TaoPhieuSinhNhat 'KH00006', '2024-05-01';
GO


INSERT INTO DONHANG (MA_DONHANG, MA_KHACHHANG, NGAYTAO, TONGGIATRI)
VALUES	('DH001', 'KH00006', '2024-04-02', 1000000),
		('DH002', 'KH00006', '2024-05-03', 500000),
		('DH003', 'KH00006', '2024-05-05', 2000000)
GO


EXEC sp_CapNhatTongTienMuaSamTrongNam 'KH00006', '2024-04-30';
EXEC sp_CapNhatTongTienMuaSamTrongNam 'KH00006', '2024-05-31';
GO


EXEC sp_GhiNhanPhanHangMoiNam 'KH00001';
EXEC sp_GhiNhanPhanHangMoiNam 'KH00002';
EXEC sp_GhiNhanPhanHangMoiNam 'KH00003';
EXEC sp_GhiNhanPhanHangMoiNam 'KH00004';
EXEC sp_GhiNhanPhanHangMoiNam 'KH00005';
EXEC sp_GhiNhanPhanHangMoiNam 'KH00006';
GO


EXEC sp_PhanHangKhachHang '2024-04-30';
EXEC sp_PhanHangKhachHang '2024-05-31';
EXEC sp_PhanHangKhachHang '2024-12-31';
GO


EXEC sp_GuiQuaSinhNhat '2024-05-01';
EXEC sp_GuiQuaSinhNhat '2024-06-01';
EXEC sp_GuiQuaSinhNhat '2024-07-01';
GO

*/