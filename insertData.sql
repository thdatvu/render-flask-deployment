insert into tbUser Values(0123456789,'Nguoidung@1',1);
insert into tbUser Values(0524224132,'Nguoidung@2',1);
insert into tbUser Values(0925523612,'Nhanvien@1',0);
insert into tbUser Values(0964124361,'Nhanvien@2',0);
select* from tbUser
--KhachHang
insert into tbKhachHang Values('Nguyễn Sơn Tùng',0123456789,'Cầu Giấy, Hà Nội', 'skyoi123@gmail.com');
select * from tbKhachHang
--NhanVien
insert into tbNhanVien Values('NV01',N'Đặng Quý Hưng','2003-01-01',0964124361,N'Cầu Giấy, Hà Nội',N'quản lí','dqhung@gmail.com', 'nữ');
select * from tbNhanVien
-- Danh muc
insert into tbDanhMuc Values('BB',N'Bim Bim');
insert into tbDanhMuc Values('NN',N'Nước Ngọt')

-- Sản phẩm
insert into tbSanPham Values(N'Bim Bim Oishi vị cà chua',N'Snack Oishi với từng miếng snack tròn thiết kế hình dạng của lát cà chua lạ mắt, gia vị đậm đà được phủ kín mặt bánh, càng ăn càng ngon',5000,4000,'BB',200)
insert into tbSanPham Values(N'Bim Bim Oishi Indo Chips',N'Snack gồm những miếng bánh phồng giòn rụm, thơm vị mực, mang lại cho bé cảm giác ngon miệng, thích thú khi ăn',5000,4000,'BB',225)
select * from tbSanPham
-- anh san pham
Delete from tbAnhSanPham
INSERT INTO tbAnhSanPham (MaSP, TenFileAnh,IdAnh)
VALUES 
('SP01', (SELECT * FROM OPENROWSET(BULK N'D:\Ki1Nam4\Project1\photos\MSP01.jpg', SINGLE_BLOB) AS Image1),'SP01.1'),
('SP01', (SELECT * FROM OPENROWSET(BULK N'D:\Ki1Nam4\Project1\photos\MSP01.2.jpg', SINGLE_BLOB) AS Image2),'SP01.2'),
('SP01', (SELECT * FROM OPENROWSET(BULK N'D:\Ki1Nam4\Project1\photos\MSP01.3.jpg', SINGLE_BLOB) AS Image3),'SP01.3')

INSERT INTO tbAnhSanPham (MaSP, TenFileAnh,IdAnh)
VALUES 
('SP02', (SELECT * FROM OPENROWSET(BULK N'D:\Ki1Nam4\Project1\photos\MSP02.jpg', SINGLE_BLOB) AS Image1),'SP02.1'),
('SP02', (SELECT * FROM OPENROWSET(BULK N'D:\Ki1Nam4\Project1\photos\MSP02.1.jpg', SINGLE_BLOB) AS Image2),'SP02.2'),
('SP02', (SELECT * FROM OPENROWSET(BULK N'D:\Ki1Nam4\Project1\photosh\MSP02.2.jpg', SINGLE_BLOB) AS Image3),'SP02.3')
select * from tbAnhSanPham

-- Nha cung cap
insert into tbNhacungCap Values('NCC01',N'Nhà máy sản xuất Cocacola');
insert into tbNhacungCap Values('NCC02',N'Nhà máy sản xuất Bim Bim Oishi');
-- HoaDonNhap
insert into tbHoaDonNhap Values('HDN01','2024-08-05','NV01',800000,'NCC02');
insert into tbHoaDonNhap Values('HDN02','2024-08-05','NV01',900000,'NCC02');

-- chitietHoaDonNhap
insert into tbChiTietHoaDonNhap Values('HDN01','SP01',200);
insert into tbChiTietHoaDonNhap Values('HDN02','SP02',225);
--DonHang
insert into tbDonHang Values('DH01',N'Nguyen Van A','NV01','2024-09-05',N'Hoàn Thành',10000,'Banking');
select * from tbDonHang

--chiTietDonHang
insert into tbChiTietDonHang Values('DH01','SP01',2,10000,0,N'');

