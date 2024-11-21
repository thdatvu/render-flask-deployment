-- TRigger

select *from tbAnhSanPham
Drop trigger trg_InsertKhachHangFromUser
CREATE TRIGGER trg_InsertFromUser
ON tbUser
AFTER INSERT
AS
BEGIN
    DECLARE @SĐT INT;
    DECLARE @Email NVARCHAR(50);
    DECLARE @Type INT;
    DECLARE @newMaKH NVARCHAR(50);
    DECLARE @newMaNV NVARCHAR(50);
    DECLARE @maxSoThuTuKH INT;
    DECLARE @maxSoThuTuNV INT;

    -- Lấy thông tin từ bản ghi mới được chèn vào bảng tbUser
    SELECT @SĐT = i.SĐT, @Email = i.PassWord, @Type = i.[Type]
    FROM inserted i;

    -- Nếu Type = 1, chèn vào bảng tbKhachHang
    IF @Type = 1
    BEGIN
        -- Lấy số thứ tự lớn nhất hiện tại từ tbKhachHang
        SELECT @maxSoThuTuKH = ISNULL(MAX(CAST(SUBSTRING(MaKH, 3, LEN(MaKH) - 2) AS INT)), 0)
        FROM tbKhachHang;

        -- Tạo MaKH mới: 'KH' + số thứ tự lớn nhất + 1
        SET @newMaKH = 'KH' + CAST(@maxSoThuTuKH + 1 AS NVARCHAR(50));

        -- Thêm khách hàng mới vào bảng tbKhachHang
        INSERT INTO tbKhachHang (MaKH, SĐT, Email)
        VALUES (@newMaKH, @SĐT, @Email);
    END
    -- Nếu Type = 0, chèn vào bảng tbNhanVien
    ELSE IF @Type = 0
    BEGIN
        -- Lấy số thứ tự lớn nhất hiện tại từ tbNhanVien
        SELECT @maxSoThuTuNV = ISNULL(MAX(CAST(SUBSTRING(MaNV, 3, LEN(MaNV) - 2) AS INT)), 0)
        FROM tbNhanVien;

        -- Tạo MaNV mới: 'NV' + số thứ tự lớn nhất + 1
        SET @newMaNV = 'NV' + CAST(@maxSoThuTuNV + 1 AS NVARCHAR(50));

        -- Thêm nhân viên mới vào bảng tbNhanVien
        INSERT INTO tbNhanVien (MaNV, SĐT, Email)
        VALUES (@newMaNV, @SĐT, @Email);
    END
END;
Drop procedure proc_AddUser
CREATE PROCEDURE proc_AddUser
    @SĐT NVARCHAR(15),
    @Email NVARCHAR(50),
    @Type INT,
    @Password NVARCHAR(50)  -- Thêm tham số mật khẩu
AS
BEGIN
    SET NOCOUNT ON;  -- Tắt thông báo số lượng hàng ảnh hưởng

    -- Thêm thông tin vào bảng tbUser trước
    INSERT INTO tbUser (SĐT, PassWord, [Type])
    VALUES (@SĐT, @Password, @Type);  -- Sử dụng mật khẩu từ tham số

    -- Kiểm tra và thêm thông tin vào tbKhachHang hoặc tbNhanVien
    IF @Type = 1
    BEGIN
        DECLARE @newMaKH NVARCHAR(50);

        -- Lấy số thứ tự lớn nhất hiện tại từ tbKhachHang
        SELECT @newMaKH = 'KH' + CAST(ISNULL(MAX(CAST(SUBSTRING(MaKH, 3, LEN(MaKH) - 2) AS INT)), 0) + 1 AS NVARCHAR(50))
        FROM tbKhachHang;

        -- Thêm khách hàng mới vào bảng tbKhachHang
        INSERT INTO tbKhachHang (MaKH, SĐT, Email)
        VALUES (@newMaKH, @SĐT, @Email);
    END
    ELSE IF @Type = 0
    BEGIN
        DECLARE @newMaNV NVARCHAR(50);

        -- Lấy số thứ tự lớn nhất hiện tại từ tbNhanVien
        SELECT @newMaNV = 'NV' + CAST(ISNULL(MAX(CAST(SUBSTRING(MaNV, 3, LEN(MaNV) - 2) AS INT)), 0) + 1 AS NVARCHAR(50))
        FROM tbNhanVien;

        -- Thêm nhân viên mới vào bảng tbNhanVien
        INSERT INTO tbNhanVien (MaNV, SĐT, Email)
        VALUES (@newMaNV, @SĐT, @Email);
    END
END;

EXEC proc_AddUser 
    @SĐT = '0123456344', 
    @Email = 'nguyenvana@example.com', 
    @Type = 1,  -- 1 cho khách hàng, 0 cho nhân viên
    @Password='Oke'

CREATE PROCEDURE proc_UpdateUser
    @SĐT NVARCHAR(15),
    @Email NVARCHAR(50),
    @Type INT,
    @NewPassword NVARCHAR(50)  -- Tham số để cập nhật mật khẩu
AS
BEGIN
    SET NOCOUNT ON;  -- Tắt thông báo số lượng hàng ảnh hưởng

    -- Cập nhật thông tin trong bảng tbUser
    UPDATE tbUser
    SET PassWord = @NewPassword,  -- Cập nhật mật khẩu
        [Type] = @Type
    WHERE SĐT = @SĐT;  -- Tìm người dùng dựa trên SĐT

    -- Kiểm tra loại người dùng và cập nhật thông tin trong tbKhachHang hoặc tbNhanVien
    IF @Type = 1
    BEGIN
        -- Cập nhật thông tin trong tbKhachHang
        UPDATE tbKhachHang
        SET Email = @Email
        WHERE SĐT = @SĐT;  -- Giả sử có trường SĐT trong tbKhachHang
    END
    ELSE IF @Type = 0
    BEGIN
        -- Cập nhật thông tin trong tbNhanVien
        UPDATE tbNhanVien
        SET Email = @Email
        WHERE SĐT = @SĐT;  -- Giả sử có trường SĐT trong tbNhanVien
    END
END;

EXEC proc_UpdateUser
	@SĐT = '0123456344', 
	@Email = 'new_email@mail.com', 
	@Type = 1, 
	@NewPassword = 'new_password';

CREATE PROCEDURE proc_DeleteUser
    @SĐT NVARCHAR(15)
AS
BEGIN
    SET NOCOUNT ON;  -- Tắt thông báo số lượng hàng ảnh hưởng

    -- Xóa thông tin trong tbKhachHang nếu có
    DELETE FROM tbKhachHang
    WHERE SĐT = @SĐT;

    -- Xóa thông tin trong tbNhanVien nếu có
    DELETE FROM tbNhanVien
    WHERE SĐT = @SĐT;

    -- Xóa thông tin trong bảng tbUser
    DELETE FROM tbUser
    WHERE SĐT = @SĐT;
END;

EXEC proc_DeleteUser @SĐT = '123';




INSERT INTO tbUser (SĐT, PassWord, [Type])
VALUES (123, 'password123', 0);
Select * from tbKhachHang
Select * from tbNhanVien
Select * from tbUser

-- thêm danh mục
CREATE TRIGGER trg_InsertDanhMuc
ON tbSanPham
AFTER INSERT
AS
BEGIN
    DECLARE @MaDanhMuc NVARCHAR(50);
    DECLARE @TenDanhMuc NVARCHAR(100);

    -- Lặp qua tất cả các bản ghi mới được chèn vào bảng SanPham
    DECLARE cur CURSOR FOR
    SELECT i.MaDanhMuc, d.TenDanhMuc
    FROM inserted i
    LEFT JOIN tbDanhMuc d ON i.MaDanhMuc = d.MaDanhMuc
    WHERE d.MaDanhMuc IS NULL; -- Chỉ thêm nếu MaDanhMuc chưa tồn tại trong bảng DanhMuc

    OPEN cur;

    FETCH NEXT FROM cur INTO @MaDanhMuc, @TenDanhMuc;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        -- Thêm dữ liệu vào bảng DanhMuc
        INSERT INTO tbDanhMuc (MaDanhMuc, TenDanhMuc)
        VALUES (@MaDanhMuc, 'Danh mục mới');

        FETCH NEXT FROM cur INTO @MaDanhMuc, @TenDanhMuc;
    END;

    CLOSE cur;
    DEALLOCATE cur;
END;

--						San Pham
--Hien thi san pham theo danh muc
CREATE PROCEDURE GetSanPhamByMaDanhMuc
    @MaDanhMuc NVARCHAR(50)  -- Tham số đầu vào
AS
BEGIN
    SET NOCOUNT ON;  -- Ngăn chặn thông báo số dòng bị ảnh hưởng

    SELECT 
        sp.MaSP,
        sp.TenSP,
        sp.MoTa,
        sp.GiaBan,
        sp.GiaNhap,
        sp.SL
    FROM 
        tbSanPham sp
    WHERE 
        sp.MaDanhMuc = @MaDanhMuc;  -- Lọc theo MaDanhMuc
END;
EXEC GetSanPhamByMaDanhMuc @MaDanhMuc = 'BB';
-- Truy vấn thông tin chi tiết của một sản phẩm cụ thể.
CREATE PROCEDURE GetChiTietSanPham
    @MaSP NVARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;

    -- Truy vấn thông tin chi tiết của sản phẩm
    SELECT 
        sp.MaSP,
        sp.TenSP,
        sp.MoTa,
        sp.GiaBan,
        sp.MaDanhMuc,
        sp.SL,
        dm.TenDanhMuc
    FROM 
        tbSanPham sp
    INNER JOIN 
        tbDanhMuc dm ON sp.MaDanhMuc = dm.MaDanhMuc
    WHERE 
        sp.MaSP = @MaSP;
END;
-- Insert sản phẩm mới
drop procedure InsertNewSanPhamAndDetails
CREATE PROCEDURE InsertNewSanPhamAndDetails
    @TenSP NVARCHAR(100),
    @MoTa NVARCHAR(255),
    @GiaBan DECIMAL(18, 2),
    @GiaNhap DECIMAL(18, 2),
    --@MaDanhMuc NVARCHAR(50),
    @SoLuong INT
   /* @MaNCC NVARCHAR(50),   -- Nhà cung cấp
    @MaNV NVARCHAR(50),    -- Nhân viên nhập hóa đơn
    @NgayLap DATE,         -- Ngày lập hóa đơn nhập
    @SoLuongNhap INT       -- Số lượng nhập vào kho*/
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

       /* -- 1. Kiểm tra sự tồn tại của MaDanhMuc và MaNCC
        IF NOT EXISTS (SELECT 1 FROM tbDanhMuc WHERE MaDanhMuc = @MaDanhMuc)
        BEGIN
            RAISERROR('Mã danh mục không tồn tại.', 16, 1);
            RETURN;
        END

        IF NOT EXISTS (SELECT 1 FROM tbNhaCungCap WHERE MaNCC = @MaNCC)
        BEGIN
            RAISERROR('Mã nhà cung cấp không tồn tại.', 16, 1);
            RETURN;
        END*/

        -- 2. Thêm sản phẩm mới vào bảng tbSanPham
        DECLARE @NewMaSP NVARCHAR(50);
		DECLARE @NextID NVARCHAR(2);

		-- Tính toán giá trị stt cho MaSP mới
		SET @NextID = RIGHT('00' + CAST((SELECT ISNULL(MAX(CAST(SUBSTRING(MaSP, 3, LEN(MaSP) - 2) AS INT)), 0) + 1 from tbSanPham )AS NVARCHAR), 2) ;

		-- Kết hợp với tiền tố "SP" để tạo mã sản phẩm mới
		SET @NewMaSP = 'SP' + @NextID;



        INSERT INTO tbSanPham (MaSP, TenSP, MoTa, GiaBan, GiaNhap, MaDanhMuc, SL)
        VALUES (@NewMaSP, @TenSP, @MoTa, @GiaBan, @GiaNhap, @SoLuong);

        -- 3. Tạo hóa đơn nhập mới trong bảng tbHoaDonNhap
        DECLARE @NewMaHDN NVARCHAR(50);
		DECLARE @NextHDNID NVARCHAR(2);

		-- Calculate the next ID in two-digit format for MaHDN
		SET @NextHDNID = RIGHT('00' + CAST((SELECT ISNULL(MAX(CAST(SUBSTRING(MaHDN, 4, LEN(MaHDN) - 3) AS INT)), 0) + 1 FROM tbHoaDonNhap) AS NVARCHAR), 2);

		-- Combine with the "HDN" prefix to create the new MaHDN
		SET @NewMaHDN = 'HDN' + @NextHDNID;

        INSERT INTO tbHoaDonNhap (MaHDN, NgayLap, MaNV, MaNCC, TongTien)
        VALUES (@NewMaHDN, @GiaNhap * @SoLuong);

        -- 4. Thêm chi tiết hóa đơn nhập vào bảng tbChiTietHoaDonNhap
        INSERT INTO tbChiTietHoaDonNhap (MaHDN, MaSP, SL)
        VALUES (@NewMaHDN, @NewMaSP, @SoLuong);

        -- 5. Cập nhật số lượng tồn kho (SL) trong bảng tbSanPham
        UPDATE tbSanPham
        SET SL = SL + @SoLuong
        WHERE MaSP = @NewMaSP;

        -- Hoàn tất giao dịch
        COMMIT TRANSACTION;

        PRINT 'Sản phẩm và chi tiết hóa đơn đã được thêm thành công';

    END TRY
    BEGIN CATCH
        -- Nếu có lỗi, rollback giao dịch
        ROLLBACK TRANSACTION;
        RAISERROR('Có lỗi xảy ra trong quá trình thêm sản phẩm và chi tiết hóa đơn.', 16, 1);
    END CATCH
END;

CREATE PROCEDURE InsertNewSanPhamtoMenu
    @TenSP NVARCHAR(100),
    @MoTa NVARCHAR(255),
    @GiaBan DECIMAL(18, 2),
    @GiaNhap DECIMAL(18, 2),
    @SLNhap INT       -- Số lượng nhập vào kho
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        -- 1. Generate new MaSP
        DECLARE @NewMaSP NVARCHAR(50);
        DECLARE @NextID NVARCHAR(2);

        -- Calculate the next ID for MaSP
        SET @NextID = RIGHT('00' + CAST((SELECT ISNULL(MAX(CAST(SUBSTRING(MaSP, 3, LEN(MaSP) - 2) AS INT)), 0) + 1 FROM tbSanPham) AS NVARCHAR), 2);

        -- Combine with the "SP" prefix to create a new MaSP
        SET @NewMaSP = 'SP' + @NextID;

        -- 2. Insert the new product with the specified fields
        INSERT INTO tbSanPham (MaSP, TenSP, MoTa, GiaBan, GiaNhap, SL)
        VALUES (@NewMaSP, @TenSP, @MoTa, @GiaBan, @GiaNhap, @SLNhap);

        -- Commit the transaction
        COMMIT TRANSACTION;

        PRINT 'Product has been added successfully with the specified fields';

    END TRY
    BEGIN CATCH
        -- Rollback the transaction if there's an error
        ROLLBACK TRANSACTION;
        RAISERROR('An error occurred while adding the product.', 16, 1);
    END CATCH
END;
EXEC InsertNewSanPhamtoMenu
    @TenSP = N'Bim Bim Hung',
    @MoTa = N'Snack gồm những miếng bánh phồng giòn rụm, thơm vị mực, mang lại cho bé cảm giác ngon miệng, thích thú khi ăn',
    @GiaBan = 5000,
    @GiaNhap = 4000,
    @SLNhap = 200
-- Update sản phẩm
CREATE PROCEDURE UpdateSanPham
    @MaSP NVARCHAR(50),        -- Mã sản phẩm cần cập nhật
    @TenSP NVARCHAR(100),       -- Tên sản phẩm mới
    @MoTa NVARCHAR(255),        -- Mô tả mới
    @GiaBan DECIMAL(18, 2),     -- Giá bán mới
    @GiaNhap DECIMAL(18, 2),    -- Giá nhập mới
   -- @MaDanhMuc NVARCHAR(50),    -- Mã danh mục mới
    @SoLuong INT                -- Số lượng mới
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        -- 1. Kiểm tra xem sản phẩm với MaSP có tồn tại hay không
        IF NOT EXISTS (SELECT 1 FROM tbSanPham WHERE MaSP = @MaSP)
        BEGIN
            RAISERROR('Sản phẩm không tồn tại.', 16, 1);
            RETURN;
        END

        -- 2. Cập nhật thông tin sản phẩm
        UPDATE tbSanPham
        SET TenSP = @TenSP,
            MoTa = @MoTa,
            GiaBan = @GiaBan,
            GiaNhap = @GiaNhap,
           -- MaDanhMuc = @MaDanhMuc,
            SL = @SoLuong
        WHERE MaSP = @MaSP;

        -- Hoàn tất giao dịch
        COMMIT TRANSACTION;

        PRINT 'Cập nhật sản phẩm thành công';

    END TRY
    BEGIN CATCH
        -- Nếu có lỗi, rollback giao dịch
        ROLLBACK TRANSACTION;
        RAISERROR('Có lỗi xảy ra trong quá trình cập nhật sản phẩm.', 16, 1);
    END CATCH
END;
EXEC UpdateSanPham
	@MaSP= 'SP02',
    @TenSP = N'Bim Bim Oishi Indo Chips',
    @MoTa = N'Snack gồm những miếng bánh phồng giòn rụm, thơm vị mực, mang lại cho bé cảm giác ngon miệng, thích thú khi ăn',
    @GiaBan = 5000,
    @GiaNhap = 4000,
    @MaDanhMuc = 'BB',
    @SoLuong = 200
 -- update sản phẩm new
DROP PROCEDURE UpdateSanPhamNew
CREATE PROCEDURE UpdateSanPhamNew
    @MaSP NVARCHAR(50),         -- Mã sản phẩm cần cập nhật
    @TenSP NVARCHAR(100),       -- Tên sản phẩm mới
    @MoTa NVARCHAR(255),        -- Mô tả mới
    @GiaBan DECIMAL(18, 2),     -- Giá bán mới
    @GiaNhap DECIMAL(18, 2),    -- Giá nhập mới
    @MaDanhMuc NVARCHAR(50),    -- Mã danh mục mới
    @SoLuong INT,               -- Số lượng mới
    @FileAnh NVARCHAR(300)     -- Dữ liệu ảnh mới (URL ảnh)
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        -- 1. Kiểm tra xem sản phẩm với MaSP có tồn tại hay không
        IF NOT EXISTS (SELECT 1 FROM tbSanPham WHERE MaSP = @MaSP)
        BEGIN
            RAISERROR('Sản phẩm không tồn tại.', 16, 1);
            RETURN;
        END

        -- 2. Cập nhật thông tin sản phẩm
        UPDATE tbSanPham
        SET TenSP = @TenSP,
            MoTa = @MoTa,
            GiaBan = @GiaBan,
            GiaNhap = @GiaNhap,
            MaDanhMuc = @MaDanhMuc,
            SL = @SoLuong
        WHERE MaSP = @MaSP;

        -- 3. Cập nhật ảnh sản phẩm trong bảng ảnh (nếu có)
        IF @FileAnh IS NOT NULL
        BEGIN
            -- Kiểm tra nếu sản phẩm đã có ảnh trong bảng tbAnhSanPham
            IF EXISTS (SELECT 1 FROM tbAnhSanPham WHERE MaSP = @MaSP)
            BEGIN
                -- Nếu có ảnh, thực hiện cập nhật ảnh
                UPDATE tbAnhSanPham
                SET TenFileAnh = @FileAnh
                WHERE MaSP = @MaSP;
            END
            ELSE
            BEGIN
                -- Nếu chưa có ảnh, thêm ảnh mới vào bảng
                INSERT INTO tbAnhSanPham (MaSP, TenFileAnh)
                VALUES (@MaSP, @FileAnh);
            END
        END

        -- Hoàn tất giao dịch
        COMMIT TRANSACTION;

        PRINT 'Cập nhật sản phẩm và ảnh sản phẩm thành công';

    END TRY
    BEGIN CATCH
        -- Nếu có lỗi, rollback giao dịch
        ROLLBACK TRANSACTION;
        RAISERROR('Có lỗi xảy ra trong quá trình cập nhật sản phẩm hoặc ảnh sản phẩm.', 16, 1);
    END CATCH
END;


select * from tbSanPham
select * from tbAnhSanPham
select * from vwDanhSachSanPhamVaAnh 
EXEC UpdateSanPhamNew 
    @MaSP = 'SP12',           -- Mã sản phẩm cần cập nhật
    @TenSP = 'Bánh đa',       -- Tên sản phẩm mới
    @MoTa = N'Ngon khi ăn với bia',  -- Mô tả mới
    @GiaBan = 6000.00,         -- Giá bán mới
    @GiaNhap = 5000.00,        -- Giá nhập mới
    @MaDanhMuc = 'DM01',       -- Mã danh mục mới
    @SoLuong = 100,            -- Số lượng mới
    @FileAnh = N'https://lh3.googleusercontent.com/q9JW0H9vfT9C087YRleVY2vftv3wOdSst28SvgCFfiempG5SiYKKxCOXB0WuzFfJ3t6lGWpMGF7oCQ7fGuHPA-Fq3gEVWZU=w1000-rw';  -- URL ảnh
            -- Dữ liệu ảnh mới (nếu có, nếu không để NULL)
SELECT * FROM tbSanPham WHERE MaSP = 'SP12';
SELECT * FROM tbAnhSanPham WHERE MaSP = 'SP12';

-- delete San Pham
Drop PROCEDURE DeleteSanPham

CREATE PROCEDURE DeleteSanPham
    @MaSP NVARCHAR(50)   -- Mã sản phẩm cần xóa
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        -- Kiểm tra nếu sản phẩm có tồn tại
        IF NOT EXISTS (SELECT 1 FROM tbSanPham WHERE MaSP = @MaSP)
        BEGIN
            -- Rollback trước khi ném lỗi
            ROLLBACK TRANSACTION;
            RAISERROR('Sản phẩm không tồn tại.', 16, 1);
            RETURN;
        END;
        -- Xóa sản phẩm khỏi bảng chính (tbSanPham)
        UPDATE tbSanPham 
		SET MoTa ='Deleted' 
		WHERE MaSP = @MaSP;

        -- Hoàn tất giao dịch
        COMMIT TRANSACTION;

        PRINT 'Xóa sản phẩm thành công';

    END TRY
    BEGIN CATCH
        -- Rollback nếu có lỗi xảy ra
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        -- Hiển thị lỗi chi tiết
        DECLARE @ErrorMessage NVARCHAR(4000), @ErrorSeverity INT, @ErrorState INT;
        SELECT @ErrorMessage = ERROR_MESSAGE(), @ErrorSeverity = ERROR_SEVERITY(), @ErrorState = ERROR_STATE();
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH;
END;
select *from tbSanPham
select *from tbAnhSanPham
select *from tbChiTietHoaDonNhap
EXEC DeleteSanPham @MaSP = 'SP15';

EXEC SearchSanPhamByName @TenSP = 'Oishi';
drop PROCEDURE SearchSanPhamByName
-- procedure truyền vào mã sản phẩm thì trả về ảnh sản phẩm đó 
CREATE PROCEDURE GetAnhSanPhamByMaSP
    @MaSP NVARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;

    -- Truy vấn lấy ảnh của sản phẩm theo MaSP
    SELECT 
        sp.MaSP,
        sp.TenSP,
        asp.TenFileAnh,
        asp.IdAnh
    FROM 
        tbSanPham sp
    INNER JOIN 
        tbAnhSanPham asp ON sp.MaSP = asp.MaSP
    WHERE 
        sp.MaSP = @MaSP;
END;
EXEC GetAnhSanPhamByMaSP @MaSP='SP01'


-- Hoá đơn nhập
		-- Tạo bảng tạm để lưu danh sách sản phẩm
-- Khai báo biến và gán giá trị JSON
CREATE TABLE TempDanhSachSanPham (
    TenSP NVARCHAR(100),
    GiaNhap DECIMAL(18, 2),
    SoLuongNhap INT
);
DECLARE @DanhSachSanPham NVARCHAR(MAX) = 
    '{"SanPham":[
        {"TenSP":"Nho","GiaNhap":5000,"SoLuongNhap":10},
        {"TenSP":"Biggie","GiaNhap":7000,"SoLuongNhap":5}
    ]}';

-- Chèn dữ liệu từ JSON vào bảng tạm
INSERT INTO TempDanhSachSanPham (TenSP, GiaNhap, SoLuongNhap)
SELECT 
    JSON_VALUE(value, '$.TenSP') AS TenSP,
    JSON_VALUE(value, '$.GiaNhap') AS GiaNhap,
    JSON_VALUE(value, '$.SoLuongNhap') AS SoLuongNhap
FROM OPENJSON(@DanhSachSanPham, '$.SanPham');
delete TempDanhSachSanPham
select * from TempDanhSachSanPham
drop procedure CreateHoaDonNhap

CREATE PROCEDURE CreateHoaDonNhap
    @MaNV NVARCHAR(50),
    @MaNCC NVARCHAR(50),
    @NgayLap DATE
AS
BEGIN
    SET NOCOUNT ON;

    -- 1. Tạo mã hóa đơn nhập (MaHDN) theo định dạng 'HDN' + 2 chữ số
    DECLARE @MaHDN NVARCHAR(50);
    SET @MaHDN = 'HDN' + RIGHT('00' + CAST((SELECT ISNULL(MAX(CAST(SUBSTRING(MaHDN, 4, LEN(MaHDN)) AS INT)), 0) + 1 FROM tbHoaDonNhap) AS NVARCHAR), 2);

    -- 2. Tính tổng tiền hóa đơn từ bảng tạm và kiểm tra sản phẩm
    DECLARE @TongTien DECIMAL(18, 2) = 0;
    DECLARE @TenSP NVARCHAR(100), @GiaNhap DECIMAL(18, 2), @SoLuongNhap INT;
    DECLARE @MaSP NVARCHAR(50);

    -- Con trỏ để duyệt qua bảng tạm TempDanhSachSanPham
    DECLARE cur CURSOR FOR
    SELECT TenSP, GiaNhap, SoLuongNhap
    FROM TempDanhSachSanPham;

    OPEN cur;
    FETCH NEXT FROM cur INTO @TenSP, @GiaNhap, @SoLuongNhap;

    -- Bắt đầu giao dịch
    BEGIN TRANSACTION;
    BEGIN TRY
        -- 3. Chèn hóa đơn nhập vào tbHoaDonNhap
        INSERT INTO tbHoaDonNhap (MaHDN, NgayLap, MaNV, MaNCC, TongTien)
        VALUES (@MaHDN, @NgayLap, @MaNV, @MaNCC, 0);  -- Tạm thời đặt TongTien là 0, sẽ cập nhật sau

        WHILE @@FETCH_STATUS = 0
        BEGIN
            -- Kiểm tra tồn tại sản phẩm và lấy MaSP
            SET @MaSP = NULL;
            SELECT @MaSP = MaSP FROM tbSanPham WHERE TenSP = @TenSP AND GiaNhap = @GiaNhap;

            IF @MaSP IS NULL
            BEGIN
                -- Nếu sản phẩm chưa tồn tại, tạo MaSP mới và thêm vào tbSanPham
                DECLARE @NewMaSP NVARCHAR(50);
                SET @NewMaSP = 'SP' + RIGHT('00' + CAST((SELECT ISNULL(MAX(CAST(SUBSTRING(MaSP, 3, LEN(MaSP)) AS INT)), 0) + 1 FROM tbSanPham) AS NVARCHAR), 2);

                INSERT INTO tbSanPham (MaSP, TenSP, GiaNhap, SL)
                VALUES (@NewMaSP, @TenSP, @GiaNhap, 0);

                SET @MaSP = @NewMaSP;
            END

            -- Cập nhật tổng tiền hóa đơn
            SET @TongTien = @TongTien + (@GiaNhap * @SoLuongNhap);

            -- Cập nhật số lượng tồn kho trong tbSanPham
            UPDATE tbSanPham
            SET SL = SL + @SoLuongNhap
            WHERE MaSP = @MaSP;

            -- Chèn chi tiết hóa đơn nhập vào tbChiTietHoaDonNhap
            INSERT INTO tbChiTietHoaDonNhap (MaHDN, MaSP, SL)
            VALUES (@MaHDN, @MaSP, @SoLuongNhap);

            FETCH NEXT FROM cur INTO @TenSP, @GiaNhap, @SoLuongNhap;
        END

        CLOSE cur;
        DEALLOCATE cur;

        -- 4. Cập nhật tổng tiền trong tbHoaDonNhap
        UPDATE tbHoaDonNhap
        SET TongTien = @TongTien
        WHERE MaHDN = @MaHDN;

        COMMIT TRANSACTION;  -- Xác nhận giao dịch khi mọi thứ thành công
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;  -- Hoàn tác nếu có lỗi
        CLOSE cur;
        DEALLOCATE cur;
        THROW;  -- Báo lỗi
    END CATCH;
END;

EXEC CreateHoaDonNhap
    @MaNV = 'NV1',
    @MaNCC = 'NCC01',
    @NgayLap = '2024-11-12';
DROP TABLE TempDanhSachSanPham;
select *from tbNhacungCap
select *from tbHoaDonNhap
select *from tbSanPham
		--Update hoa don nhap

Drop procedure UpdateHoaDonNhap
CREATE TABLE TempDanhSachSanPham (
    TenSP NVARCHAR(100),
    GiaNhap DECIMAL(18, 2),
    SoLuongNhap INT
);

INSERT INTO TempDanhSachSanPham (TenSP, GiaNhap, SoLuongNhap)
VALUES 
    ('Bim Bim Hung', 4000, 15),
    ('Trà Đào', 12000, 8);

CREATE PROCEDURE UpdateHoaDonNhap
    @MaHDN NVARCHAR(50), -- Mã hóa đơn cần cập nhật
    @MaNV NVARCHAR(50),  -- Mã nhân viên
    @MaNCC NVARCHAR(50), -- Mã nhà cung cấp
    @NgayLap DATE         -- Ngày lập mới
AS
BEGIN
    SET NOCOUNT ON;

    -- Bắt đầu giao dịch
    BEGIN TRANSACTION;
    BEGIN TRY
        -- 1. Cập nhật thông tin cơ bản của hóa đơn nhập
        UPDATE tbHoaDonNhap
        SET 
            NgayLap = @NgayLap,
            MaNV = @MaNV,
            MaNCC = @MaNCC
        WHERE MaHDN = @MaHDN;

        -- 2. Xóa các chi tiết hóa đơn cũ
        DELETE FROM tbChiTietHoaDonNhap
        WHERE MaHDN = @MaHDN;

        -- 3. Duyệt qua bảng tạm và thêm các chi tiết hóa đơn mới
        DECLARE @TongTien DECIMAL(18, 2) = 0;
        DECLARE @TenSP NVARCHAR(100), @GiaNhap DECIMAL(18, 2), @SoLuongNhap INT, @MaSP NVARCHAR(50);

        -- Con trỏ để duyệt qua bảng tạm TempDanhSachSanPham
        DECLARE cur CURSOR FOR
        SELECT TenSP, GiaNhap, SoLuongNhap
        FROM TempDanhSachSanPham;

        OPEN cur;
        FETCH NEXT FROM cur INTO @TenSP, @GiaNhap, @SoLuongNhap;

        WHILE @@FETCH_STATUS = 0
        BEGIN
            -- Kiểm tra tồn tại sản phẩm và lấy MaSP
            SET @MaSP = NULL;
            SELECT @MaSP = MaSP FROM tbSanPham WHERE TenSP = @TenSP AND GiaNhap = @GiaNhap;

            IF @MaSP IS NULL
            BEGIN
                -- Nếu sản phẩm chưa tồn tại, tạo MaSP mới và thêm vào tbSanPham
                DECLARE @NewMaSP NVARCHAR(50);
                SET @NewMaSP = 'SP' + RIGHT('00' + CAST((SELECT ISNULL(MAX(CAST(SUBSTRING(MaSP, 3, LEN(MaSP)) AS INT)), 0) + 1 FROM tbSanPham) AS NVARCHAR), 2);

                INSERT INTO tbSanPham (MaSP, TenSP, GiaNhap, SL)
                VALUES (@NewMaSP, @TenSP, @GiaNhap, 0);

                SET @MaSP = @NewMaSP;
            END

            -- Cập nhật tổng tiền
            SET @TongTien = @TongTien + (@GiaNhap * @SoLuongNhap);

            -- Cập nhật số lượng tồn kho trong tbSanPham
            UPDATE tbSanPham
            SET SL = SL + @SoLuongNhap
            WHERE MaSP = @MaSP;

            -- Chèn chi tiết hóa đơn mới vào tbChiTietHoaDonNhap
            INSERT INTO tbChiTietHoaDonNhap (MaHDN, MaSP, SL)
            VALUES (@MaHDN, @MaSP, @SoLuongNhap);

            FETCH NEXT FROM cur INTO @TenSP, @GiaNhap, @SoLuongNhap;
        END

        CLOSE cur;
        DEALLOCATE cur;

        -- 4. Cập nhật tổng tiền của hóa đơn
        UPDATE tbHoaDonNhap
        SET TongTien = @TongTien
        WHERE MaHDN = @MaHDN;

        -- Xác nhận giao dịch
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        -- Hoàn tác nếu có lỗi
        ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
EXEC UpdateHoaDonNhap 
    @MaHDN = 'HDN01', 
    @MaNV = 'NV1', 
    @MaNCC = 'NCC01', 
    @NgayLap = '2024-09-07';
DROP TABLE TempDanhSachSanPham;

		--DeleteHĐN
CREATE PROCEDURE DeleteHoaDonNhap
    @MaHDN NVARCHAR(50) -- Mã hóa đơn cần xóa
AS
BEGIN
    SET NOCOUNT ON;

    -- Bắt đầu giao dịch
    BEGIN TRANSACTION;
    BEGIN TRY
        -- 1. Trừ số lượng sản phẩm trong tồn kho từ chi tiết hóa đơn
        DECLARE @MaSP NVARCHAR(50), @SL INT;

        -- Con trỏ để duyệt qua các sản phẩm trong chi tiết hóa đơn
        DECLARE cur CURSOR FOR
        SELECT MaSP, SL
        FROM tbChiTietHoaDonNhap
        WHERE MaHDN = @MaHDN;

        OPEN cur;
        FETCH NEXT FROM cur INTO @MaSP, @SL;

        WHILE @@FETCH_STATUS = 0
        BEGIN
            -- Cập nhật tồn kho sản phẩm
            UPDATE tbSanPham
            SET SL = SL - @SL
            WHERE MaSP = @MaSP;

            FETCH NEXT FROM cur INTO @MaSP, @SL;
        END

        CLOSE cur;
        DEALLOCATE cur;

        -- 2. Xóa chi tiết hóa đơn nhập
        DELETE FROM tbChiTietHoaDonNhap
        WHERE MaHDN = @MaHDN;

        -- 3. Xóa hóa đơn nhập
        DELETE FROM tbHoaDonNhap
        WHERE MaHDN = @MaHDN;

        -- Xác nhận giao dịch
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        -- Hoàn tác giao dịch nếu xảy ra lỗi
        ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
EXEC DeleteHoaDonNhap @MaHDN = 'HDN07';

delete tbHoaDonNhap
select* from tbHoaDonNhap
select * from tbNhacungCap
select * from tbNhanVien
select* from tbSanPham
select* from tbChiTietHoaDonNhap


	-- Hoá đơn bán
CREATE TABLE TempChiTietDonHang (
    MaSP NVARCHAR(50),
    SoLuongBan INT,
    DonGia DECIMAL(18, 2),
    GiamGia DECIMAL(18, 2),
    GhiChu NVARCHAR(255)
);
DECLARE @DanhSachChiTietDon NVARCHAR(MAX) = 
    '{"ChiTietDon":[
        {"MaSP":"SP01","SoLuongBan":2,"DonGia":50000,"GiamGia":0.1,"GhiChu":"Ghi chú 1"}   
    ]}';

-- Chèn dữ liệu từ JSON vào bảng tạm
INSERT INTO TempChiTietDonHang (MaSP, SoLuongBan, DonGia, GiamGia, GhiChu)
SELECT 
    JSON_VALUE(value, '$.MaSP') AS MaSP,
    JSON_VALUE(value, '$.SoLuongBan') AS SoLuongBan,
    JSON_VALUE(value, '$.DonGia') AS DonGia,
    JSON_VALUE(value, '$.GiamGia') AS GiamGia,
    JSON_VALUE(value, '$.GhiChu') AS GhiChu
FROM OPENJSON(@DanhSachChiTietDon, '$.ChiTietDon');
drop procedure CreateDonHang
delete from TempChiTietDonHang
CREATE PROCEDURE CreateDonHang
    @MAKH NVARCHAR(50),
    @MaNV NVARCHAR(50),
    @NgayLap DATE,
    @TrangThai NVARCHAR(50),
    @PhuongThucThanhToan NVARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;

    -- 1. Tạo mã đơn hàng (MaDH) theo định dạng 'DH' + 2 chữ số
    DECLARE @MaDH NVARCHAR(50);
    SET @MaDH = 'DH' + RIGHT('00' + CAST((SELECT ISNULL(MAX(CAST(SUBSTRING(MaDH, 3, LEN(MaDH)) AS INT)), 0) + 1 FROM tbDonHang) AS NVARCHAR), 2);

    -- 2. Tính tổng tiền đơn hàng từ bảng tạm và kiểm tra sản phẩm
    DECLARE @TongTien DECIMAL(18, 2) = 0;
    DECLARE @MaSP NVARCHAR(50), @SoLuongBan INT, @DonGia DECIMAL(18, 2), @GiamGia DECIMAL(18, 2), @GhiChu NVARCHAR(255);

    -- Con trỏ để duyệt qua bảng tạm TempChiTietDonHang
    DECLARE cur CURSOR FOR
    SELECT MaSP, SoLuongBan, DonGia, GiamGia, GhiChu
    FROM TempChiTietDonHang;

    OPEN cur;
    FETCH NEXT FROM cur INTO @MaSP, @SoLuongBan, @DonGia, @GiamGia, @GhiChu;

    -- Bắt đầu giao dịch
    BEGIN TRANSACTION;
    BEGIN TRY
        -- 3. Chèn đơn hàng vào bảng DonHang
        INSERT INTO tbDonHang (MaDH, MAKH, MaNV, NgayLap, TrangThai, TongTien, PhuongThucThanhToan)
        VALUES (@MaDH, @MAKH, @MaNV, @NgayLap, @TrangThai, 0, @PhuongThucThanhToan); -- Tạm đặt TongTien là 0

        WHILE @@FETCH_STATUS = 0
        BEGIN
            -- Tính tổng tiền sau giảm giá cho mỗi sản phẩm
            DECLARE @ThanhTien DECIMAL(18, 2) = @SoLuongBan * @DonGia * (1 - @GiamGia);

            -- Cộng vào tổng tiền của đơn hàng
            SET @TongTien = @TongTien + @ThanhTien;

            -- Chèn chi tiết đơn hàng vào ChiTietDonHang
            INSERT INTO tbChiTietDonHang (MaDH, MaSP, SLBan, DonGia, GiamGia, GhiChu)
            VALUES (@MaDH, @MaSP, @SoLuongBan, @DonGia, @GiamGia, @GhiChu);

            FETCH NEXT FROM cur INTO @MaSP, @SoLuongBan, @DonGia, @GiamGia, @GhiChu;
        END

        CLOSE cur;
        DEALLOCATE cur;

        -- 4. Cập nhật tổng tiền vào bảng DonHang
        UPDATE tbDonHang
        SET TongTien = @TongTien
        WHERE MaDH = @MaDH;

        COMMIT TRANSACTION;  -- Xác nhận giao dịch
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;  -- Hoàn tác nếu có lỗi
        CLOSE cur;
        DEALLOCATE cur;
        THROW;  -- Ném lỗi để báo cáo
    END CATCH;
END;

EXEC CreateDonHang 
    @MAKH = 'KH3',
    @MaNV = 'NV1',
    @NgayLap = '2024-11-12',
    @TrangThai = 'Đã giao',
    @PhuongThucThanhToan = N'Tiền mặt';
delete  from TempChiTietDonHang
select *from tbKhachHang
select *from tbDonHang
	--Update hoá đơn bán

-- Thêm dữ liệu mẫu vào bảng tạm
INSERT INTO TempChiTietDonHang (MaSP, SoLuongBan, DonGia, GiamGia, GhiChu)
VALUES 
    ('SP01', 5, 5000, 0.1, 'Ghi chú 1'),
    ('SP02', 2, 15000, 0.2, 'Ghi chú 2');

CREATE PROCEDURE UpdateHoaDonBan
    @MaHD NVARCHAR(50),           -- Mã hóa đơn cần cập nhật
    @MaNV NVARCHAR(50),           -- Mã nhân viên
    @MaKH NVARCHAR(50),           -- Mã khách hàng
    @NgayLap DATE,                -- Ngày lập mới
    @TrangThai NVARCHAR(50),      -- Trạng thái hóa đơn mới
    @PhuongThucThanhToan NVARCHAR(50) -- Phương thức thanh toán
AS
BEGIN
    SET NOCOUNT ON;

    -- Bắt đầu giao dịch
    BEGIN TRANSACTION;
    BEGIN TRY
        -- 1. Cập nhật thông tin cơ bản của hóa đơn bán
        UPDATE tbDonHang
        SET 
            MaNV = @MaNV,
            MaKH = @MaKH,
            NgayLap = @NgayLap,
            TrangThai = @TrangThai,
            PhuongThucThanhToan = @PhuongThucThanhToan
        WHERE MaDH = @MaHD;

        -- 2. Xóa các chi tiết hóa đơn cũ
        DELETE FROM tbChiTietDonHang
        WHERE MaDH = @MaHD;

        -- 3. Duyệt qua bảng tạm TempChiTietDonHang và thêm các chi tiết hóa đơn mới
        DECLARE @TongTien DECIMAL(18, 2) = 0;
        DECLARE @MaSP NVARCHAR(50), @SoLuongBan INT, @DonGia DECIMAL(18, 2), @GiamGia DECIMAL(18, 2), @GhiChu NVARCHAR(255);

        -- Con trỏ để duyệt qua bảng tạm TempChiTietDonHang
        DECLARE cur CURSOR FOR
        SELECT MaSP, SoLuongBan, DonGia, GiamGia, GhiChu
        FROM TempChiTietDonHang;

        OPEN cur;
        FETCH NEXT FROM cur INTO @MaSP, @SoLuongBan, @DonGia, @GiamGia, @GhiChu;

        WHILE @@FETCH_STATUS = 0
        BEGIN
            -- Kiểm tra tồn tại sản phẩm trong tbSanPham
            IF NOT EXISTS (SELECT 1 FROM tbSanPham WHERE MaSP = @MaSP)
            BEGIN
                THROW 50001, 'Sản phẩm không tồn tại trong danh sách!', 1;
            END

            -- Tính tổng tiền (bao gồm giảm giá)
            DECLARE @ThanhTien DECIMAL(18, 2) = @SoLuongBan * @DonGia * (1 - @GiamGia);
            SET @TongTien = @TongTien + @ThanhTien;

            -- Cập nhật tồn kho sản phẩm trong tbSanPham
            UPDATE tbSanPham
            SET SL = SL - @SoLuongBan
            WHERE MaSP = @MaSP;

            -- Thêm chi tiết hóa đơn vào tbChiTietDonHang
            INSERT INTO tbChiTietDonHang (MaDH, MaSP, SLBan, DonGia, GiamGia, GhiChu)
            VALUES (@MaHD, @MaSP, @SoLuongBan, @DonGia, @GiamGia, @GhiChu);

            FETCH NEXT FROM cur INTO @MaSP, @SoLuongBan, @DonGia, @GiamGia, @GhiChu;
        END

        CLOSE cur;
        DEALLOCATE cur;

        -- 4. Cập nhật tổng tiền hóa đơn vào tbDonHang
        UPDATE tbDonHang
        SET TongTien = @TongTien
        WHERE MaDH = @MaHD;

        -- Xác nhận giao dịch
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        -- Hoàn tác nếu có lỗi
        ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
select *from tbHoaDonNhap
select *from tbDonHang
EXEC UpdateHoaDonBan 
    @MaHD = 'DH02',
    @MaNV = 'NV1',
    @MaKH = 'KH2',
    @NgayLap = '2024-11-11',
    @TrangThai = 'Đã giao',
    @PhuongThucThanhToan = N'Tiền mặt';
delete from TempChiTietDonHang
	--Xoa hoá đơn
CREATE PROCEDURE DeleteDonHang
    @MaHD NVARCHAR(50) -- Mã đơn hàng cần xóa
AS
BEGIN
    SET NOCOUNT ON;

    -- Bắt đầu giao dịch
    BEGIN TRANSACTION;
    BEGIN TRY
        -- 1. Xóa chi tiết đơn hàng liên quan trong tbChiTietDonHang
        DELETE FROM tbChiTietDonHang
        WHERE MaDH = @MaHD;

        -- 2. Xóa đơn hàng trong tbDonHang
        DELETE FROM tbDonHang
        WHERE MaDH = @MaHD;

        -- Xác nhận giao dịch
        COMMIT TRANSACTION;

        PRINT 'Đơn hàng và các chi tiết liên quan đã được xóa thành công.';
    END TRY
    BEGIN CATCH
        -- Hoàn tác nếu có lỗi
        ROLLBACK TRANSACTION;

        -- Ném lỗi để báo cáo
        THROW;
    END CATCH;
END;
EXEC DeleteDonHang @MaHD = 'DH01';

select* from tbDonHang
select* from tbChiTietDonHang
select* from tbKhachHang
select* from tbNhanVien
select * from TempChiTietDonHang;


-- Tính doanh thu theo ngay
-- Tính doanh thu theo ngày
CREATE PROCEDURE GetDoanhThuTheoNgay
    @Ngay DATE  -- Ngày cần tính doanh thu
AS
BEGIN
    SET NOCOUNT ON;

    SELECT @Ngay AS Ngay,
           SUM(TongTien) AS TongDoanhThu
    FROM tbDonHang
    WHERE CONVERT(DATE, NgayLap) = @Ngay
          
END;
CREATE PROCEDURE GetDoanhThuTheoThang
    @Thang INT,  -- Tháng cần tính doanh thu (1-12)
    @Nam INT     -- Năm cần tính doanh thu
AS
BEGIN
    SET NOCOUNT ON;

    SELECT @Thang AS Thang,
           @Nam AS Nam,
           SUM(TongTien) AS TongDoanhThu
    FROM tbDonHang
    WHERE MONTH(NgayLap) = @Thang
          AND YEAR(NgayLap) = @Nam
         
END;
CREATE PROCEDURE GetDoanhThuTheoNam
    @Nam INT  -- Năm cần tính doanh thu
AS
BEGIN
    SET NOCOUNT ON;

    SELECT @Nam AS Nam,
           SUM(TongTien) AS TongDoanhThu
    FROM tbDonHang
    WHERE YEAR(NgayLap) = @Nam
         
END;
drop procedure GetDoanhThuTheoNgay
drop procedure GetDoanhThuTheoThang
drop procedure GetDoanhThuTheoNam
EXEC GetDoanhThuTheoNgay @Ngay = '2024-11-17';
EXEC GetDoanhThuTheoThang @Thang = 11, @Nam = 2024;
EXEC GetDoanhThuTheoNam @Nam = 2024;
select *from tbDanhMuc 

