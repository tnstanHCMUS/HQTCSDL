USE QLITHONGTINHETHONGSIEUTHI
GO

--INSERT DATA TO PHANHANG
INSERT INTO PHANHANG VALUES (N'Kim cương', 50000000, 1200000)
INSERT INTO PHANHANG VALUES (N'Bạch Kim', 30000000, 700000)
INSERT INTO PHANHANG VALUES (N'Vàng', 15000000, 500000)
INSERT INTO PHANHANG VALUES (N'Bạc', 5000000, 200000)
INSERT INTO PHANHANG VALUES (N'Đồng', 1000000, 100000)
INSERT INTO PHANHANG VALUES (N'Thân thiết', 0, 0)
go

select * from PHANHANG
go

--50 khách hàng mẫu với data khác nhau ngày sinh, tên, số điện thoại, ngày sinh, ngày đăng ký, Phân hạng, Phân hạng năm trước có thể khác nhau
INSERT INTO KHACHHANG VALUES ('KH001', '0123456789', N'Nguyễn Văn A', '1999-05-01', '2023-01-01', N'Kim cương', N'Kim cương')
INSERT INTO KHACHHANG VALUES ('KH002', '0123456769', N'Nguyễn Thị B', '1999-06-02', '2017-01-02', N'Bạch Kim', N'Bạch Kim')
INSERT INTO KHACHHANG VALUES ('KH003', '0123456788', N'Nguyễn Văn C', '1999-07-03', '2018-02-03', N'Vàng', N'Vàng')
INSERT INTO KHACHHANG VALUES ('KH004', '0123456787', N'Nguyễn Thị D', '1999-12-04', '2021-01-04', N'Bạc', N'Bạc')
INSERT INTO KHACHHANG VALUES ('KH005', '0123456786', N'Nguyễn Văn E', '1999-01-05', '2021-05-05', N'Đồng', N'Đồng')
INSERT INTO KHACHHANG VALUES ('KH006', '0123456785', N'Nguyễn Thị F', '1999-08-06', '2020-09-06', N'Thân thiết', N'Thân thiết')
INSERT INTO KHACHHANG VALUES ('KH007', '0123456784', N'Nguyễn Văn G', '1999-02-07', '2024-01-07', N'Kim cương', N'Kim cương')
INSERT INTO KHACHHANG VALUES ('KH008', '0123456783', N'Nguyễn Thị H', '1999-09-08', '2021-01-08', N'Bạch Kim', N'Bạch Kim')
INSERT INTO KHACHHANG VALUES ('KH009', '0123456782', N'Nguyễn Văn I', '1999-09-09', '2022-01-09', N'Vàng', N'Vàng')
INSERT INTO KHACHHANG VALUES ('KH010', '0123456781', N'Nguyễn Thị K', '1999-03-10', '2021-01-10', N'Bạc', N'Bạc')
INSERT INTO KHACHHANG VALUES ('KH011', '0123456780', N'Nguyễn Văn L', '1999-01-11', '2021-01-11', N'Đồng', N'Đồng')
INSERT INTO KHACHHANG VALUES ('KH012', '0123456779', N'Nguyễn Thị M', '1999-04-12', '2022-01-12', N'Thân thiết', N'Thân thiết')
INSERT INTO KHACHHANG VALUES ('KH013', '0123456778', N'Nguyễn Văn N', '1999-08-13', '2021-01-13', N'Kim cương', N'Vàng')
INSERT INTO KHACHHANG VALUES ('KH014', '0123456777', N'Nguyễn Thị O', '1999-11-14', '2021-01-14', N'Bạch Kim', N'Bạc')
INSERT INTO KHACHHANG VALUES ('KH015', '0123456776', N'Nguyễn Văn P', '1999-12-15', '2021-01-15', N'Vàng', N'Đồng')
INSERT INTO KHACHHANG VALUES ('KH016', '0123456775', N'Nguyễn Thị Q', '1999-10-16', '2021-08-16', N'Bạc', N'Thân thiết')
INSERT INTO KHACHHANG VALUES ('KH017', '0123456774', N'Nguyễn Văn R', '1999-10-17', '2025-01-17', N'Đồng', N'Kim cương')
INSERT INTO KHACHHANG VALUES ('KH018', '0123456773', N'Nguyễn Thị S', '1999-09-18', '2023-10-18', N'Thân thiết', N'Bạch Kim')
INSERT INTO KHACHHANG VALUES ('KH019', '0123456772', N'Nguyễn Văn T', '1999-08-19', '2018-12-19', N'Kim cương', N'Vàng')
INSERT INTO KHACHHANG VALUES ('KH020', '0123456771', N'Nguyễn Thị U', '1999-07-20', '2023-01-20', N'Bạch Kim', N'Bạc')
INSERT INTO KHACHHANG VALUES ('KH021', '0123456770', N'Nguyễn Văn V', '1999-01-21', '2021-01-21', N'Vàng', N'Đồng')
INSERT INTO KHACHHANG VALUES ('KH022', '0123456769', N'Nguyễn Thị W', '1999-06-22', '2021-01-22', N'Bạc', N'Thân thiết')
INSERT INTO KHACHHANG VALUES ('KH023', '0123456768', N'Nguyễn Văn X', '1999-05-23', '2023-03-23', N'Đồng', N'Kim cương')
INSERT INTO KHACHHANG VALUES ('KH024', '0123456767', N'Nguyễn Thị Y', '1999-04-24', '2021-01-24', N'Thân thiết', N'Bạch Kim')
INSERT INTO KHACHHANG VALUES ('KH025', '0123456766', N'Nguyễn Văn Z', '1999-01-25', '2024-01-25', N'Kim cương', N'Vàng')
INSERT INTO KHACHHANG VALUES ('KH026', '0123456765', N'Nguyễn Thị A1', '1999-03-26', '2021-07-26', N'Bạch Kim', N'Bạc')
INSERT INTO KHACHHANG VALUES ('KH027', '0123456764', N'Nguyễn Văn B1', '1999-05-27', '2021-01-27', N'Vàng', N'Đồng')
INSERT INTO KHACHHANG VALUES ('KH028', '0123456763', N'Nguyễn Thị C1', '1999-04-28', '2024-01-28', N'Bạc', N'Thân thiết')
INSERT INTO KHACHHANG VALUES ('KH029', '0123456762', N'Nguyễn Văn D1', '1999-01-29', '2021-08-29', N'Đồng', N'Kim cương')
INSERT INTO KHACHHANG VALUES ('KH030', '0123456761', N'Nguyễn Thị E1', '1999-03-30', '2021-01-30', N'Thân thiết', N'Bạch Kim')
INSERT INTO KHACHHANG VALUES ('KH031', '0123456760', N'Nguyễn Văn F1', '1999-03-31', '2021-05-01', N'Kim cương', N'Vàng')
INSERT INTO KHACHHANG VALUES ('KH032', '0123456759', N'Nguyễn Thị G1', '1999-03-22', '2022-01-18', N'Bạch Kim', N'Bạc')
INSERT INTO KHACHHANG VALUES ('KH033', '0123456758', N'Nguyễn Văn H1', '1999-03-13', '2021-01-30', N'Vàng', N'Đồng')
INSERT INTO KHACHHANG VALUES ('KH034', '0123456757', N'Nguyễn Thị I1', '1999-01-14', '2016-01-12', N'Bạc', N'Thân thiết')
INSERT INTO KHACHHANG VALUES ('KH035', '0123456756', N'Nguyễn Văn K1', '1999-06-05', '2022-02-01', N'Đồng', N'Kim cương')
INSERT INTO KHACHHANG VALUES ('KH036', '0123456755', N'Nguyễn Thị L1', '1999-01-26', '2012-01-12', N'Thân thiết', N'Bạch Kim')
INSERT INTO KHACHHANG VALUES ('KH037', '0123456754', N'Nguyễn Văn M1', '1999-01-17', '2021-05-30', N'Kim cương', N'Vàng')
INSERT INTO KHACHHANG VALUES ('KH038', '0123456753', N'Nguyễn Thị N1', '1999-06-28', '2021-05-08', N'Bạch Kim', N'Bạc')
INSERT INTO KHACHHANG VALUES ('KH039', '0123456752', N'Nguyễn Văn O1', '1999-04-09', '2021-01-13', N'Vàng', N'Đồng')
INSERT INTO KHACHHANG VALUES ('KH040', '0123456751', N'Nguyễn Thị P1', '1999-01-10', '2021-06-25', N'Bạc', N'Thân thiết')
INSERT INTO KHACHHANG VALUES ('KH041', '0123456750', N'Nguyễn Văn Q1', '1999-01-21', '2021-01-30', N'Đồng', N'Kim cương')
INSERT INTO KHACHHANG VALUES ('KH042', '0123456749', N'Nguyễn Thị R1', '1999-03-02', '2021-01-13', N'Thân thiết', N'Bạch Kim')
INSERT INTO KHACHHANG VALUES ('KH043', '0123456748', N'Nguyễn Văn S1', '1999-02-23', '2021-11-15', N'Kim cương', N'Vàng')
INSERT INTO KHACHHANG VALUES ('KH044', '0123456747', N'Nguyễn Thị T1', '1999-02-14', '2021-10-22', N'Bạch Kim', N'Bạc')
INSERT INTO KHACHHANG VALUES ('KH045', '0123456746', N'Nguyễn Văn U1', '1999-02-25', '2021-01-24', N'Vàng', N'Đồng')
INSERT INTO KHACHHANG VALUES ('KH046', '0123456745', N'Nguyễn Thị V1', '1999-02-16', '2021-12-16', N'Bạc', N'Thân thiết')
INSERT INTO KHACHHANG VALUES ('KH047', '0123456744', N'Nguyễn Văn W1', '1999-07-07', '2021-01-26', N'Đồng', N'Kim cương')
INSERT INTO KHACHHANG VALUES ('KH048', '0123456743', N'Nguyễn Thị X1', '1999-07-18', '2021-08-21', N'Thân thiết', N'Bạch Kim')
INSERT INTO KHACHHANG VALUES ('KH049', '0123456742', N'Nguyễn Văn Y1', '1999-02-19', '2021-09-29', N'Kim cương', N'Vàng')
INSERT INTO KHACHHANG VALUES ('KH050', '0123456741', N'Nguyễn Thị Z1', '1999-06-10', '2021-03-31', N'Bạch Kim', N'Bạc')
go 

select * from KHACHHANG
go

--INSERT DATA TO NHASANXUAT 20 nhà sản xuất mẫu với data khác nhau của hàng tiêu dùng
INSERT INTO NHASANXUAT VALUES ('NSX001', N'Nestle', N'123 Nguyễn Văn Tráng, Quận 7, TP.HCM', '0123456789') --BÁNH KẸO THỰC PHẨM
INSERT INTO NHASANXUAT VALUES ('NSX002', N'Vinamilk', N'456 Trần Hưng Đạo, Quận 10, TP.HCM', '0123456788') --KẸO, SỮA
INSERT INTO NHASANXUAT VALUES ('NSX003', N'Unilever', N'789 Nguyễn Văn Cừ, Quận 6, TP.HCM', '0123456787') --DẦU GỘI, HOÁ MỸ PHẨM
INSERT INTO NHASANXUAT VALUES ('NSX004', N'P&G', N'1011 Nguyễn Văn Linh, Quận 5, TP.HCM', '0123456786') --DẦU GỘI, HOÁ MỸ PHẨM
INSERT INTO NHASANXUAT VALUES ('NSX005', N'Colgate', N'1213 Trần Hưng Đạo, Quận 4, TP.HCM', '0123456785') --KEM ĐÁNH RĂNG
INSERT INTO NHASANXUAT VALUES ('NSX006', N'Pepsi', N'1415 Nguyễn Văn Cừ, Quận 3, TP.HCM', '0123456784') --NƯỚC NGỌT
INSERT INTO NHASANXUAT VALUES ('NSX007', N'Coca Cola', N'161 Cô Giang, Quận 2, TP.HCM', '0123456783') --NƯỚC NGỌT
INSERT INTO NHASANXUAT VALUES ('NSX008', N'Kinh Đô', N'1819 Nguyễn Văn Linh, Quận 1, TP.HCM', '0123456782') --BÁNH KẸO THỰC PHẨM
INSERT INTO NHASANXUAT VALUES ('NSX009', N'Vissan', N'2021 Trần Hưng Đạo, Quận 8, TP.HCM', '0123456781') --XÚC XÍCH, THỊT
INSERT INTO NHASANXUAT VALUES ('NSX010', N'Orion', N'2223 Nguyễn Văn Cừ, Quận Bình Thanh, TP.HCM', '0123456780') --BÁNH KẸO THỰC PHẨM
INSERT INTO NHASANXUAT VALUES ('NSX011', N'Sunhouse', N'2425 Nguyễn Văn Linh, Quận 7, TP.HCM', '0123456779') --ĐỒ GIA DỤNG, ĐIỆN GIA DỤNG
INSERT INTO NHASANXUAT VALUES ('NSX012', N'Panasonic', N'2627 Trần Hưng Đạo, Quận 10, TP.HCM', '0123456778') --ĐIỆN GIA DỤNG
INSERT INTO NHASANXUAT VALUES ('NSX013', N'Samsung', N'2829 Nguyễn Văn Cừ, Quận 6, TP.HCM', '0123456777') --ĐIỆN GIA DỤNG
INSERT INTO NHASANXUAT VALUES ('NSX014', N'LG', N'3031 Nguyễn Văn Linh, Quận 5, TP.HCM', '0123456776') --ĐIỆN GIA DỤNG
INSERT INTO NHASANXUAT VALUES ('NSX015', N'Apple', N'3233 Trần Hưng Đạo, Quận 4, TP.HCM', '0123456775') --ĐIỆN THOẠI
INSERT INTO NHASANXUAT VALUES ('NSX016', N'Xiaomi', N'3435 Nguyễn Văn Cừ, Quận 3, TP.HCM', '0123456774') --ĐIỆN THOẠI, ĐIỆN GIA DỤNG
INSERT INTO NHASANXUAT VALUES ('NSX017', N'Nokia', N'3637 Cô Giang, Quận 2, TP.HCM', '0123456773') --ĐIỆN THOẠI
INSERT INTO NHASANXUAT VALUES ('NSX018', N'Bibica', N'3839 Nguyễn Văn Linh, Quận 1, TP.HCM', '0123456772') --BÁNH KẸO THỰC PHẨM
INSERT INTO NHASANXUAT VALUES ('NSX019', N'Kimdan', N'4041 Trần Hưng Đạo, Quận 8, TP.HCM', '0123456771') --CHĂN GA GỐI
INSERT INTO NHASANXUAT VALUES ('NSX020', N'Trung Nguyên', N'4243 Nguyễn Văn Cừ, Quận Bình Thanh, TP.HCM', '0123456770') --CÀ PHÊ
go

select * from NHASANXUAT
go

--INSERT DATA TO MUC mục mẫu với data khác nhau
--BK - Bánh kẹo (Bánh các loại, Snack, Kẹo, Socola, Ngũ cốc)
--LT - Lương thực (Gạo, Mì, Bún, Mì ăn liền, Bột các loại)
--DR Đồ uống (Nước ngọt, Nước suối, Nước ép, Cà phê, Trà)
--DDGD - Đồ điện gia dụng (Đèn, Quạt, Máy giặt, Tủ lạnh, Máy lạnh)
--DGD - Đồ gia dụng (Bát đĩa, Nồi, Chảo, Bếp, Bàn ăn)
INSERT INTO MUC VALUES ('BK', N'Bánh kẹo', NULL)
INSERT INTO MUC VALUES ('LT', N'Lương thực', NULL)
INSERT INTO MUC VALUES ('DR', N'Đồ uống', NULL)
INSERT INTO MUC VALUES ('DDGD', N'Đồ điện gia dụng', NULL)
INSERT INTO MUC VALUES ('DGD', N'Đồ gia dụng', NULL)
go
INSERT INTO MUC VALUES ('BK1', N'Bánh các loại', 'BK')
INSERT INTO MUC VALUES ('BK2', N'Snack', 'BK')
INSERT INTO MUC VALUES ('BK3', N'Kẹo', 'BK')
INSERT INTO MUC VALUES ('BK4', N'Socola', 'BK')
INSERT INTO MUC VALUES ('BK5', N'Ngũ cốc', 'BK')
INSERT INTO MUC VALUES ('LT1', N'Gạo', 'LT')
INSERT INTO MUC VALUES ('LT2', N'Mì', 'LT')
INSERT INTO MUC VALUES ('LT3', N'Bún', 'LT')
INSERT INTO MUC VALUES ('LT4', N'Mì ăn liền', 'LT')
INSERT INTO MUC VALUES ('LT5', N'Bột các loại', 'LT')
INSERT INTO MUC VALUES ('DR1', N'Nước ngọt', 'DR')
INSERT INTO MUC VALUES ('DR2', N'Nước suối', 'DR')
INSERT INTO MUC VALUES ('DR3', N'Nước ép', 'DR')
INSERT INTO MUC VALUES ('DR4', N'Cà phê', 'DR')
INSERT INTO MUC VALUES ('DR5', N'Trà', 'DR')
INSERT INTO MUC VALUES ('DDGD1', N'Đèn', 'DDGD')
INSERT INTO MUC VALUES ('DDGD2', N'Quạt', 'DDGD')
INSERT INTO MUC VALUES ('DDGD3', N'Máy giặt', 'DDGD')
INSERT INTO MUC VALUES ('DDGD4', N'Tủ lạnh', 'DDGD')
INSERT INTO MUC VALUES ('DDGD5', N'Máy lạnh', 'DDGD')
INSERT INTO MUC VALUES ('DGD1', N'Bát đĩa', 'DGD')
INSERT INTO MUC VALUES ('DGD2', N'Nồi', 'DGD')
INSERT INTO MUC VALUES ('DGD3', N'Chảo', 'DGD')
INSERT INTO MUC VALUES ('DGD4', N'Bếp', 'DGD')
INSERT INTO MUC VALUES ('DGD5', N'Bàn ăn', 'DGD')
go

select * from MUC
go

--trigger kiểm tra tên nhà sản xuất của sản phẩm phải nằm trong danh sách nhà sản xuất và giống với tên trong bảng nhà sản xuất
CREATE TRIGGER TRG_SANPHAM_NHASANXUAT
ON SANPHAM
FOR INSERT
as
begin
    if not exists (select * from NHASANXUAT where TEN_NHASANXUAT in (select NHASANXUAT from inserted))
    --hoặc tên nhà sản xuất không giống với tên nhà sản xuất trong bảng nhà sản xuất so với mã nhà sản xuất tương ứng
    or not exists (select * from NHASANXUAT where MA_NHASANXUAT in (select MA_NHASANXUAT from inserted where NHASANXUAT = TEN_NHASANXUAT))
    begin
        rollback
        raiserror('Tên nhà sản xuất không tồn tại trong danh sách nhà sản xuất hoăc không đúng', 16, 1)
    end
end
go

-- INSERT 50 sản phẩm vào bảng SANPHAM với thông tin ngẫu nhiên
INSERT INTO SANPHAM VALUES 
('SP001', 'BK1', 'NSX001', N'Bánh quy hạnh nhân', 15000, N'Bánh quy hạnh nhân giòn thơm, bổ dưỡng', N'Nestle', '2024-01-01', '2025-01-01', 500, 450),
('SP002', 'BK3', 'NSX002', N'Kẹo dẻo trái cây', 12000, N'Kẹo dẻo nhiều hương vị trái cây', N'Vinamilk', '2024-02-01', '2025-02-01', 300, 280),
('SP003', 'DR1', 'NSX003', N'Nước ngọt Coca Cola', 18000, N'Nước ngọt Coca Cola, giải khát tuyệt vời', N'Coca Cola', '2024-03-01', '2025-03-01', 600, 580),
('SP004', 'LT1', 'NSX004', N'Gạo tám thơm', 40000, N'Gạo tám thơm, đặc sản nổi tiếng', N'P&G', '2024-01-15', '2025-01-15', 1000, 950),
('SP005', 'DGD1', 'NSX005', N'Bát đĩa sứ cao cấp', 50000, N'Bát đĩa sứ cao cấp, bền đẹp, sang trọng', N'Colgate', '2024-02-10', '2025-02-10', 200, 190),
('SP006', 'BK2', 'NSX006', N'Snack khoai tây', 15000, N'Snack khoai tây giòn tan, dễ ăn', N'Pepsi', '2024-03-10', '2025-03-10', 400, 390),
('SP007', 'LT2', 'NSX007', N'Mì ăn liền Hảo Hảo', 5000, N'Mì ăn liền Hảo Hảo, tiện lợi, ngon miệng', N'Coca Cola', '2024-01-20', '2025-01-20', 800, 780),
('SP008', 'DR4', 'NSX008', N'Cà phê hòa tan', 35000, N'Cà phê hòa tan chất lượng, thơm ngon', N'Kinh Đô', '2024-04-01', '2025-04-01', 300, 270),
('SP009', 'DDGD4', 'NSX009', N'Tủ lạnh Samsung', 1200000, N'Tủ lạnh Samsung, tiết kiệm năng lượng', N'Samsung', '2024-05-01', '2025-05-01', 100, 90),
('SP010', 'DGD5', 'NSX010', N'Bàn ăn gỗ tự nhiên', 600000, N'Bàn ăn gỗ tự nhiên, sang trọng và bền vững', N'Orion', '2024-06-01', '2025-06-01', 50, 45),
('SP011', 'BK4', 'NSX011', N'Socola đen', 25000, N'Socola đen thơm ngon, chất lượng cao', N'Sunhouse', '2024-02-20', '2025-02-20', 300, 280),
('SP012', 'LT3', 'NSX012', N'Bún khô', 20000, N'Bún khô thơm ngon, dễ chế biến', N'Panasonic', '2024-03-15', '2025-03-15', 600, 590),
('SP013', 'DR2', 'NSX013', N'Nước suối Lavie', 8000, N'Nước suối Lavie, tinh khiết, thanh mát', N'Samsung', '2024-04-10', '2025-04-10', 1000, 950),
('SP014', 'DDGD3', 'NSX014', N'Máy giặt LG', 800000, N'Máy giặt LG tiết kiệm điện, hiệu quả', N'LG', '2024-05-10', '2025-05-10', 150, 140),
('SP015', 'DGD3', 'NSX015', N'Nồi inox cao cấp', 350000, N'Nồi inox cao cấp, bền, đẹp, an toàn', N'Apple', '2024-06-01', '2025-06-01', 200, 180),
('SP016', 'BK5', 'NSX016', N'Ngũ cốc ăn sáng', 25000, N'Ngũ cốc ăn sáng dinh dưỡng, đầy đủ vitamin', N'Xiaomi', '2024-07-01', '2025-07-01', 500, 480),
('SP017', 'LT4', 'NSX017', N'Mì ăn liền Hảo Hảo', 12000, N'Mì ăn liền Hảo Hảo tiện lợi, thơm ngon', N'Nokia', '2024-08-01', '2025-08-01', 700, 650),
('SP018', 'DR3', 'NSX018', N'Nước ép trái cây', 25000, N'Nước ép trái cây tươi ngon, bổ dưỡng', N'Bibica', '2024-09-01', '2025-09-01', 400, 380),
('SP019', 'DGD4', 'NSX019', N'Bếp gas', 1000000, N'Bếp gas chất lượng, an toàn cho gia đình', N'Kimdan', '2024-10-01', '2025-10-01', 50, 40),
('SP020', 'BK3', 'NSX020', N'Kẹo dẻo trái cây', 20000, N'Kẹo dẻo trái cây nhiều màu sắc, ngọt ngào', N'Trung Nguyên', '2024-11-01', '2025-11-01', 300, 290),
('SP021', 'DDGD2', 'NSX001', N'Quạt điện', 150000, N'Quạt điện hiệu quả, tiết kiệm điện', N'Nestle', '2024-02-15', '2025-02-15', 400, 380),
('SP022', 'LT5', 'NSX002', N'Bột mì', 30000, N'Bột mì đa năng, dùng làm bánh, nấu ăn', N'Vinamilk', '2024-03-01', '2025-03-01', 500, 480),
('SP023', 'DGD2', 'NSX003', N'Nồi inox', 400000, N'Nồi inox chất lượng cao, an toàn cho sức khỏe', N'Unilever', '2024-04-05', '2025-04-05', 250, 230),
('SP024', 'DR5', 'NSX004', N'Trái cây sấy', 22000, N'Trái cây sấy khô, thơm ngon, bổ dưỡng', N'P&G', '2024-05-10', '2025-05-10', 600, 590),
('SP025', 'LT1', 'NSX005', N'Gạo nếp', 45000, N'Gạo nếp dẻo, ngon, thích hợp cho món xôi', N'Colgate', '2024-06-01', '2025-06-01', 300, 280),
('SP026', 'DR4', 'NSX006', N'Cà phê hòa tan', 30000, N'Cà phê hòa tan, thơm ngon, dễ sử dụng', N'Pepsi', '2024-07-10', '2025-07-10', 400, 380),
('SP027', 'DDGD1', 'NSX007', N'Đèn ngủ LED', 120000, N'Đèn ngủ LED, tiết kiệm năng lượng', N'Coca Cola', '2024-08-01', '2025-08-01', 100, 90),
('SP028', 'DGD1', 'NSX008', N'Bát đĩa sứ', 50000, N'Bát đĩa sứ cao cấp, bền đẹp', N'Kinh Đô', '2024-09-01', '2025-09-01', 200, 190),
('SP029', 'LT2', 'NSX009', N'Mì ăn liền', 10000, N'Mì ăn liền, tiện lợi, nhanh chóng', N'Vissan', '2024-10-15', '2025-10-15', 800, 780),
('SP030', 'DR1', 'NSX010', N'Nước ngọt Sprite', 15000, N'Nước ngọt Sprite, vị chua ngọt, sảng khoái', N'Orion', '2024-11-01', '2025-11-01', 500, 480),
('SP031', 'BK1', 'NSX011', N'Bánh quy sô cô la', 18000, N'Bánh quy sô cô la, ngọt ngào, hấp dẫn', N'Sunhouse', '2024-01-10', '2025-01-10', 300, 290),
('SP032', 'LT5', 'NSX012', N'Bột ngũ cốc', 20000, N'Bột ngũ cốc giàu dinh dưỡng, thích hợp cho bữa sáng', N'Panasonic', '2024-02-20', '2025-02-20', 500, 480),
('SP033', 'DGD2', 'NSX013', N'Nồi inox', 350000, N'Nồi inox bền đẹp, an toàn', N'Samsung', '2024-03-10', '2025-03-10', 250, 240),
('SP034', 'BK4', 'NSX014', N'Socola đen', 22000, N'Socola đen, chất lượng cao', N'LG', '2024-04-01', '2025-04-01', 300, 290),
('SP035', 'LT3', 'NSX015', N'Bún tươi', 25000, N'Bún tươi, mềm mại, dễ chế biến', N'Apple', '2024-05-01', '2025-05-01', 600, 590),
('SP036', 'DDGD3', 'NSX016', N'Máy giặt', 700000, N'Máy giặt tiết kiệm điện, hiệu quả', N'Xiaomi', '2024-06-15', '2025-06-15', 100, 90),
('SP037', 'DGD5', 'NSX017', N'Bàn ăn gỗ', 800000, N'Bàn ăn gỗ, sang trọng, bền đẹp', N'Nokia', '2024-07-20', '2025-07-20', 50, 45),
('SP038', 'DR3', 'NSX018', N'Nước ép trái cây', 18000, N'Nước ép trái cây tươi, ngon lành', N'Bibica', '2024-08-10', '2025-08-10', 400, 380),
('SP039', 'BK2', 'NSX019', N'Snack khoai tây', 17000, N'Snack khoai tây giòn tan, ăn là ghiền', N'Kimdan', '2024-09-05', '2025-09-05', 350, 330),
('SP040', 'LT4', 'NSX020', N'Mì ăn liền', 8000, N'Mì ăn liền tiện lợi, ngon miệng', N'Trung Nguyên', '2024-10-10', '2025-10-10', 700, 680),
('SP041', 'DGD3', 'NSX001', N'Nồi inox cao cấp', 350000, N'Nồi inox chất lượng cao, bền đẹp', N'Nestle', '2024-11-15', '2025-11-15', 200, 190),
('SP042', 'DDGD4', 'NSX002', N'Tủ lạnh mini', 1200000, N'Tủ lạnh mini tiện dụng, tiết kiệm điện', N'Vinamilk', '2024-12-01', '2025-12-01', 100, 90),
('SP043', 'DR5', 'NSX003', N'Trà xanh', 15000, N'Trà xanh, thơm ngon, bổ dưỡng', N'Unilever', '2024-01-01', '2025-01-01', 500, 480),
('SP044', 'LT1', 'NSX004', N'Gạo nếp', 45000, N'Gạo nếp dẻo, ngon, thích hợp cho món xôi', N'P&G', '2024-02-01', '2025-02-01', 300, 280),
('SP045', 'DGD1', 'NSX005', N'Bát đĩa sứ', 50000, N'Bát đĩa sứ cao cấp, bền đẹp', N'Colgate', '2024-03-01', '2025-03-01', 200, 190),
('SP046', 'BK2', 'NSX006', N'Snack khoai tây', 15000, N'Snack khoai tây giòn tan, dễ ăn', N'Pepsi', '2024-04-01', '2025-04-01', 400, 380),
('SP047', 'LT2', 'NSX007', N'Mì ăn liền Hảo Hảo', 5000, N'Mì ăn liền Hảo Hảo, tiện lợi, ngon miệng', N'Coca Cola', '2024-05-01', '2025-05-01', 800, 780),
('SP048', 'DR4', 'NSX008', N'Cà phê hòa tan', 35000, N'Cà phê hòa tan chất lượng, thơm ngon', N'Kinh Đô', '2024-06-01', '2025-06-01', 300, 280),
('SP049', 'DDGD4', 'NSX009', N'Tủ lạnh Samsung', 1200000, N'Tủ lạnh Samsung, tiết kiệm năng lượng', N'Samsung', '2024-07-01', '2025-07-01', 100, 90),
('SP050', 'DGD5', 'NSX010', N'Bàn ăn gỗ tự nhiên', 600000, N'Bàn ăn gỗ tự nhiên, sang trọng và bền vững', N'Orion', '2024-08-01', '2025-08-01', 50, 45)
go

select * from SANPHAM


