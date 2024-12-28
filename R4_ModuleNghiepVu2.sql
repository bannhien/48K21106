-- 1. Thủ tục kiểm tra sản phẩm

GO
CREATE OR ALTER PROC kiemTraVaChenSanPham 
    (@tenSP NVARCHAR(50),          -- Tên sản phẩm
     @soLuongSP INT,               -- Số lượng sản phẩm
     @giaNhap NUMERIC(15, 0),      -- Giá nhập
     @giaBan NUMERIC(15, 0),       -- Giá bán
     @hinhAnhSP IMAGE,             -- Hình ảnh sản phẩm
     @HSD DATE,                    -- Hạn sử dụng
     @ret BIT OUT)                 -- Kết quả trả về (1: Thành công, 0: Lỗi)
AS
BEGIN
    -- Kiểm tra sản phẩm đã tồn tại chưa (dựa trên tên sản phẩm)
    IF EXISTS (SELECT 1 FROM sanPham WHERE tenSP = @tenSP)
    BEGIN
        PRINT 'San pham da ton tai!';
        SET @ret = 0;
        RETURN;
    END

    -- Kiểm tra hạn sử dụng có lớn hơn ngày hiện tại không
    IF @HSD <= GETDATE()
    BEGIN
        PRINT 'Han su dung khong hop le( phai lon hon ngay hien tai)';
        SET @ret = 0;
        RETURN;
    END

    -- Chèn sản phẩm mới vào bảng sanPham
    INSERT INTO sanPham (tenSP, soLuongSP, giaNhap, giaBan, hinhAnhSP, HSD)
    VALUES (@tenSP, @soLuongSP, @giaNhap, @giaBan, @hinhAnhSP, @HSD);

	if @@ROWCOUNT > 0
	begin
		PRINT 'Da insert san pham thanh cong';
		SET @ret = 1;
	end
	else
	begin
		PRINT 'Insert that bai';
		SET @ret = 0;
		rollback
	end
END;


--Kiem tra
DECLARE @result BIT;
EXEC kiemTraVaChenSanPham  'San pham moi',    -- Tên sản phẩm
							100,                -- Số lượng sản phẩm
							50000,              -- Giá nhập
							70000,              -- Giá bán
							NULL,               -- Hình ảnh sản phẩm
							'2025-12-31',       -- Hạn sử dụng
							@result OUT;        -- Kết quả trả về

PRINT @result; -- Kết quả: 1 nếu thành công, 0 nếu lỗi
select * from sanPham --San pham moi
--2.  Trigger kiem tra gia ban
Go
CREATE OR ALTER TRIGGER trg_KiemTraGiaBan
ON sanPham
AFTER INSERT, UPDATE
AS
BEGIN
    -- Kiểm tra điều kiện
    IF EXISTS (
        SELECT 1
        FROM inserted i
        WHERE i.giaBan > i.giaNhap
    )
    BEGIN
        -- Rollback thao tác nếu điều kiện vi phạm
        ROLLBACK TRANSACTION;

        -- Thông báo lỗi
        PRINT ' Khong hop le: Gia ban khong duoc lon hon gia nhap. Vui long chinh gia nhap truoc.';
    END
END;
--Kiểm tra
-- insert hop le
INSERT INTO sanPham (tenSP, soLuongSP, giaNhap, giaBan, hinhAnhSP, HSD)
VALUES (N'San pham A', 100, 50000, 40000, NULL, '2025-12-31');
--Ket qua: Thao tac thanh cong
--insert khong hop le
INSERT INTO sanPham (tenSP, soLuongSP, giaNhap, giaBan, hinhAnhSP, HSD)
VALUES (N'San pham B', 100, 50000, 60000, NULL, '2025-12-31');
-- Kết quả: Loi "Khong hop le: Gia ban khong duoc lon hon gia nhap. Vui long chinh gia nhap truoc."
--Update khong  hop le
UPDATE sanPham
SET giaBan = 80000
WHERE maSP = 1 AND giaNhap = 50000;
-- Ket qua: Loi "Khong hop le: Gia ban khong duoc lon hon gia nhap. Vui long chinh gia nhap truoc."
-- Update hop le
UPDATE sanPham
SET giaBan = 45000
WHERE maSP = 1 AND giaNhap = 50000;
-- Thao tac thanh cong

-- 3. Thu tuc kiem tra don hang ban
--input: maKH, ngayTao, tongTien
--output: thất bại: 0, thành công: 1
--process: kiểm tra ngày tạo có hợp lệ (ngayTao= ngày hiện tại (getdate())
		-- Kiểm tra đã tồn tại khach hàng chưa, nếu chưa thì thông báo lỗi
		-- Thêm mới vào bảng ghi --if @@rowcount >0
										--trả về giá trị 1
								 --ngược lại, 
										--trả về giá trị 0
go
create or alter proc kiemTraDonHangBan (@maKH int, @ret bit out)
as
begin
	declare @ngayTao date = getdate()
	declare @tongTien numeric (15, 0) = 0

--Kiểm tra đã tồn tại khach hàng chưa, nếu chưa thì thông báo lỗi
	if not exists (select 1 from donHangBan where maKH=@maKH)
	begin
		print N'Không tồn tại khach hang'
		set @ret = 0
		return
	end 

	insert into donHangBan(maKH, ngayTao, tongTien)
	values (@maKH, @ngayTao, @tongTien)

	if @@ROWCOUNT > 0
	begin
		PRINT 'Da insert thanh cong';
		SET @ret = 1;
	end
	else
	begin
		PRINT 'Insert that bai';
		SET @ret = 0;
		rollback
	end
end

declare @a bit 
exec kiemTraDonHangBan '568', @a out
print @a

select * from donHangBan

-- 4. Trigger tong tien DHB
--loai: after trigger 
--su kien: insert, delete
--bang: donHangBanCT
--process: 
 --1. Lay thanhTienIS, maDHBIS tu bang INSERTED 
 --2. lay thanhTienDL, maDHBDL tu bang DELETED 
 --3. update bảng donHangBan voi tongTien = tongTien + @thanhTienIS
							-- dieu kien: maDHB = @maDHBIS
--4. update bảng donHangBan voi tongTien = tongTien - @thanhTienDL
							-- dieu kien: maDHB = @maDHBDL

go
create or alter trigger tinhTongTien
on donHangBanCT
after insert, delete
as
begin
	declare @thanhTienIS numeric(15, 0), @thanhTienDL numeric(15, 0)
	declare @maDHBIS int, @maDHBDL int

	select @thanhTienIS = thanhTien, @maDHBIS = maDHB
	from inserted

	select @thanhTienDL = thanhTien, @maDHBDL = maDHB
	from deleted

	update donHangBan
	set tongTien = tongTien + @thanhTienIS
	where maDHB = @maDHBIS

	update donHangBan
	set tongTien = tongTien - @thanhTienDL
	where maDHB = @maDHBDL
end
-- 5. Thủ tục kiểm tra đơn hàng bán chi tiết
go
create or alter proc themDHBCT(@maDHB int, @tenSP nvarchar(100), @soLuong int, @ret bit out)
as
begin

	declare @maSP int
	select @maSP = maSP from sanPham where tenSP = @tenSP
	-- 1. Kiem tra maDHB ton tai chua
	if not exists (select 1 from donHangBan where maDHB = @maDHB)
	begin
		print N'Chua ton tai maDHB'
		set @ret = 0
		return
	end

	-- 2. Kiem tra SP ton tai chua
	if not exists (select 1 from sanPham where maSP = @maSP)
	begin
		print N'Khong ton tai san pham'
		set @ret = 0
		return
	end

	-- 3. Kiem tra soLuong
	declare @soLuongTonKho int
	select @soLuongTonKho = soLuongSP
	from sanPham
	where maSP = @maSP

	if @soLuong > @soLuongTonKho
	begin
		print N'So luong ton kho khong du'
		set @ret = 0
		return
	end
	
	declare @giaBan numeric(15,0)
	select @giaBan = giaBan
	from sanPham
	where maSP = @maSP

	declare @thanhTien int
	set @thanhTien = @soLuong*@giaBan

	insert into donHangBanCT(maDHB, maSP, giaBan, soLuong, thanhTien)
	values (@maDHB, @maSP, @giaBan, @soLuong, @thanhTien)
	if @@ROWCOUNT>0
	begin
		print N'Thêm dữ liệu thành công'
		set @ret = 1
	end
	else
	begin
		print N'Thất bại'
		set @ret = 0
		rollback
	end
end


exec themDHBCT '1000', '123', 3, @ret

-- 6. Trigger cập nhật số lượng tồn kho
go
create or alter trigger updateTonKho
on donHangBanCT
after insert
as
begin
	declare @soLuongDaBan int, @maSP int

	select @soLuongDaBan = soLuong, @maSP = maSP
	from inserted

	update sanPham
	set soLuongSP = soLuongSP - @soLuongDaBan
	where maSP = @maSP
end

-- 7. Thu tuc them moi no khach hang
go
create proc spNPTKH (@maDHB int , @tienNo numeric (15,0) , @ngayNoTien date,@ret bit output)
as
begin
	-- kiểm tra maDHb tồn tại chưa, chưa thì báo lỗi
	if not exists (select 1 from donHangBan where @maDHB = maDHB)
	begin
		print N'Mã DHB không tồn tại'
		set @ret = 0
		return
	end
	--kiểm tra tiền nợ có lớn hơn tiền nợ của maDHB đó không, lớn hơn thì báo lỗi
	declare @tongtien numeric (15,0)	
	select @tongtien = tongTien
	from donHangBan
	where @maDHB = maDHB

	if @tienNo > @tongtien
	begin
		print N'Lỗi tiền nợ'
		set @ret = 0
		return
	end
	--ngày nợ tiền <= getdate
	if @ngayNoTien > CAST(GETDATE() as date)
	begin
		print N'Lỗi ngày trả tiền'
		set @ret =0
		return
	end
	--set trạng thái trả tiền mặc định là 0
	declare @trangThaiTraTien bit = 0
	--thêm nợ phải trả
	insert into noPhaiTraKH(maDHB,tienNo,ngayNoTien,trangThaiTraTien)
	values (@maDHB,@tienNo,@ngayNoTien,@trangThaiTraTien)
	if @@ROWCOUNT > 0 
	begin
		print N'Thêm thành công'
		set @ret =1
	end
	else
	begin
		print N'Thêm thất bại'
		set @ret =0
	end
end

select * from [dbo].[noPhaiTraKH] where maDHB = '6'
select * from [dbo].[donHangBan] where maDHB = '6'

declare @a bit
exec spNPTKH 6,'927427','2025-11-14' , @a output
print @a


exec spNPTKH 6,'127427','2025-11-14' , @a output
print @a


exec spNPTKH 6,'127427','2024-11-14' , @a output
print @a

-- 8. Trigger kiem tra no khach hang
go
create trigger tnoKH
on [dbo].[noPhaiTraKH]
after update
as
begin
	declare @ngayNoTien date,
			@ngayTraTien date,
			@trangThaiTraTien bit,
			@maDHB int
	select	@ngayNoTien	= ngayNoTien,
			@ngayTraTien = ngayTraTien,
			@trangThaiTraTien = trangThaiTraTien,
			@maDHB = maDHB
			from inserted
	if @ngayNoTien > @ngayTraTien
	begin
		print N'Lỗi : ngày nợ tiền không thể lớn hơn ngày trả tiền'
		rollback
	end
	else
	begin
		update [dbo].[noPhaiTraKH]
		set trangThaiTraTien = 1
		where maDHB = @maDHB
	end
end

update [dbo].[noPhaiTraKH]
set ngayTraTien = '2024-11-17'
where maDHB = 340

select * from [dbo].[noPhaiTraKH]
where maDHB = 340


-- 9. Thu tuc kiem tra don hang nhap
--input: maNCC, ngayTao, tongTien
--output: thất bại: 0, thành công: 1
--process: kiểm tra ngày tạo đơn hàng có hợp lệ (ngayTao= ngày hiện tại (getdate())
		-- Kiểm tra đã tồn hàng chưa, nếu chưa thì thông báo lỗi
		-- Thêm mới vào bảng ghi --if @@rowcount >0
										--trả về giá trị 1
								 --ngược lại, 
										--trả về giá trị 0

go
create or alter proc kiemTraDonHangNhap (@maNCC int, @ret bit out)
as
begin
	declare @ngayTao date =  getdate()
	declare @tongTien numeric(15, 0) = 0
--Kiểm tra ngày tạo đơn hàng có hợp lệ hay không

--Kiểm tra đã tồn tại hàng chưa, nếu chưa thì thông báo lỗi
	if not exists (select 1 from donHangNhap where maNCC=@maNCC)
	begin
		print N'Không tồn tại'
		set @ret = 0
		return
	end 

	insert into donHangNhap(maNCC, ngayTao, tongTien)
	values (@maNCC, @ngayTao, @tongTien)

	if @@ROWCOUNT > 0
	begin
		PRINT 'Da insert thanh cong';
		SET @ret = 1;
	end
	else
	begin
		PRINT 'Insert that bai';
		SET @ret = 0;
		rollback
	end
end

declare @a bit 
exec kiemTraDonHangNhap '677','2024-11-08', @a out
print @a

-- 10. Trigger tinh tong tien nhap
--loai: after trigger 
--su kien: insert, delete
--bang: donHangNhapCT
--process: 
 --1. Lay thanhTienIS, maDHNIS tu bang INSERTED 
 --2. lay thanhTienDL, maDHNDL tu bang DELETED 
 --3. update bảng donHangNhap voi tongTien = tongTien + @thanhTienIS
							-- dieu kien: maDHN = @maDHNIS
--4. update bảng donHangNhap voi tongTien = tongTien - @thanhTienDL
							-- dieu kien: maDHN = @maDHNDL

go
create or alter trigger tinhTongTienNhap
on donHangNhapCT
after insert, delete
as
begin
	declare @thanhTienIS numeric(15, 0), @thanhTienDL numeric(15, 0)
	declare @maDHNIS int, @maDHNDL int

	select @thanhTienIS = thanhTien, @maDHNIS = maDHN
	from inserted

	select @thanhTienDL = thanhTien, @maDHNDL = maDHN
	from deleted

	update donHangNhap
	set tongTien = tongTien + @thanhTienIS
	where maDHN = @maDHNIS

	update donHangNhap
	set tongTien = tongTien - @thanhTienDL
	where maDHN = @maDHNDL
end

-- 11. Thu tuc kiem tra don hang chi tiet
go
create proc spDHNct (@maDHN int, @maSP int , @giaNhap numeric (15,0) , @soLuong int , @ret bit output)
as
begin
	-- 1. kiểm tra maDHN tồn tại chưa, chưa thì báo lỗi
	if not exists ( select 1 from [dbo].[donHangNhapCT] where @maDHN = maDHN )
	begin
		print N'maDHN chưa tồn tại'
		set @ret = 0 
		return
	end
	-- 2. kiểm tra maSP tồn tại chưa, chưa thì báo lỗi
	if not exists ( select 1 from [dbo].[donHangNhapCT] where @maSP = maSP )
	begin
		print N'maSP chưa tồn tại'
		set @ret = 0 
		return
	end
	-- 3. kiểm tra giá nhập có < 0 ko, bé hơn thì báo lỗi
	if @giaNhap < 0
	begin
		print N'Lỗi : giaNhap '
		set @ret = 0 
		return
	end
	-- 4.kiểm tra số lượng có <0 ko, bé hơn thì báo lỗi
		if @soLuong < 0
	begin
		print N'Lỗi : giaNhap '
		set @ret = 0 
		return
	end
	-- 5.  set thành tiền = số lượng * giaNhap
	declare @thanhTien numeric(15,0) 
	set @thanhTien = @giaNhap * @soLuong

	--Thêm đơn hàng chi tiết mới 
	insert into [dbo].[donHangNhapCT] (maDHN,maSP,giaNhap,soLuong,thanhTien)
	values (@maDHN,@maSP,@giaNhap,@soLuong,@thanhTien)
	if @@ROWCOUNT > 0
	begin
		print N'Thêm thành công '
		set @ret = 1 
	end
	else 
	begin
		print N'Thêm thất bại '
		set @ret = 0 
	end
end

select * from [dbo].[donHangNhapCT]

declare @a bit
exec spDHNct '527' , '708' ,'1000' , 10 , @a output
print @a 

-- 12. Trigger kiem tra hang ton kho
go
create trigger tDHNct
on [dbo].[donHangNhapCT]
after insert
as
begin
	declare @maSP int , @soLuong int 
	select @soLuong= soLuong,@maSP = maSP
	from inserted
	update [dbo].[sanPham]
	set soLuongSP = soLuongSP + @soLuong
end

insert into [dbo].[donHangNhapCT] values (1,708,'89688',10,'500000')

select * from [dbo].[donHangNhapCT]

select * from [dbo].[sanPham]

-- 13. Thu tuc kiem tra no phai tra ncc
GO
CREATE OR ALTER PROC kiemTraVaCapNhatNoPhaiTraNCC 
    (@maDHN INT,                 -- Mã đơn hàng nhập
     @tienNo NUMERIC(15, 0),     -- Số tiền nợ
     @ngayNoTien DATE,           -- Ngày nợ tiền
     @ret BIT OUT)               -- Trả về kết quả (1: Thành công, 0: Lỗi)
AS
BEGIN
    -- Kiểm tra mã đơn hàng nhập có tồn tại không
    IF NOT EXISTS (SELECT 1 FROM donHangNhap WHERE maDHN = @maDHN)
    BEGIN
        PRINT 'Loi: Ma don hang nhap khong ton tai!';
        SET @ret = 0;
        RETURN;
    END

    -- Kiểm tra tiền nợ có lớn hơn tổng tiền của đơn hàng nhập hay không
    DECLARE @tongTien NUMERIC(15, 0);
    SELECT @tongTien = tongTien FROM donHangNhap WHERE maDHN = @maDHN;

    IF @tienNo > @tongTien
    BEGIN
        PRINT 'Loi: Tien no vuot qua tong tien cua don hang nhap!';
        SET @ret = 0;
        RETURN;
    END

    -- Kiểm tra ngày nợ tiền có hợp lệ hay không
    IF @ngayNoTien > GETDATE()
    BEGIN
        PRINT 'Loi: Ngay no tien phai nho hon hoac bang ngay hien tai!';
        SET @ret = 0;
        RETURN;
    END

    -- Chèn thông tin nợ vào bảng noPhaiTraNCC với trạng thái trả tiền mặc định là 0
    INSERT INTO noPhaiTraNCC (maDHN, tienNo, ngayNoTien, trangThaiTraTien, ngayTraTien)
    VALUES (@maDHN, @tienNo, @ngayNoTien, 0, NULL);

    PRINT 'Thong tin no phai tra da duoc cap nhat thanh cong!';
    SET @ret = 1;
END;

--Kiem tra
DECLARE @result BIT;			-- Gọi thủ tục với dữ liệu hợp lệ
EXEC kiemTraVaCapNhatNoPhaiTraNCC 
					1,             -- Mã đơn hàng nhập
					500000,        -- Tiền nợ
					'2024-11-15',  -- Ngày nợ tiền
					@result OUT;   -- Kết quả trả về

	-- In kết quả
PRINT @result;  -- 1: Thành công, 0: Lỗi

-- 14. Trigger kiem tra ngay tra tien no NCC
GO
CREATE OR ALTER TRIGGER trg_KiemTraNgayTraTien
ON noPhaiTraNCC
AFTER INSERT, UPDATE
AS
BEGIN
    -- Kiểm tra điều kiện ngày trả tiền > ngày nợ tiền
    IF EXISTS (
        SELECT 1
        FROM inserted i
        WHERE i.ngayTraTien IS NOT NULL AND i.ngayTraTien <= i.ngayNoTien
    )
    BEGIN
        -- Rollback thao tác nếu vi phạm
        ROLLBACK TRANSACTION;

        -- Thông báo lỗi
        PRINT 'Loi: Ngay tra tien phai lon hon ngay no tien!';
    END
END;

-- Kiểm tra
-- Insert hop le
INSERT INTO noPhaiTraNCC (maDHN, tienNo, ngayNoTien, trangThaiTraTien, ngayTraTien)
VALUES (1, 500000, '2024-11-10', 0, '2024-11-15');
-- Thao tac thanh cong

-- Insert khong hop le
INSERT INTO noPhaiTraNCC (maDHN, tienNo, ngayNoTien, trangThaiTraTien, ngayTraTien)
VALUES (1, 500000, '2024-11-10', 0, '2024-11-05');
-- Ket qua: Loi "Ngay tra tien phai lon hon ngay no tien!"

-- Update hop le
INSERT INTO noPhaiTraNCC (maDHN, tienNo, ngayNoTien, trangThaiTraTien, ngayTraTien)
VALUES (1, 500000, '2024-11-10', 0, '2024-11-05');
-- Ket qua: Loi "Ngay tra tien phai lon hon ngay no tien!"

-- Update khong hop le
UPDATE noPhaiTraNCC
SET ngayTraTien = '2024-11-05'
WHERE maNPTNCC = 1;
-- Ket qua: Loi "Ngay tra tien phai lon hon ngay no tien!"

-- 15. Trigger cap nhat trang thai tra tien
GO
CREATE OR ALTER PROC capNhatTrangThaiTraTien
					(@maNPTNCC INT,          -- Mã nợ phải trả nhà cung cấp
					 @ngayTraTien DATE,      -- Ngày trả tiền
					 @ret BIT OUT)           -- Trả về kết quả (1: Thành công, 0: Lỗi)
AS
BEGIN
    -- Kiểm tra mã nợ phải trả có tồn tại không
    IF NOT EXISTS (SELECT 1 FROM noPhaiTraNCC WHERE maNPTNCC = @maNPTNCC)
    BEGIN
        PRINT 'Loi: Ma no phai tra khong ton tai!';
        SET @ret = 0;
        RETURN;
    END

    -- Kiểm tra ngày trả tiền có hợp lệ không (ngày trả tiền > ngày nợ tiền)
    DECLARE @ngayNoTien DATE;
    SELECT @ngayNoTien = ngayNoTien FROM noPhaiTraNCC WHERE maNPTNCC = @maNPTNCC;

    IF @ngayTraTien <= @ngayNoTien
    BEGIN
        PRINT 'Loi: Ngay tra tien phai lon hon ngay no tien!';
        SET @ret = 0;
        RETURN;
    END

    -- Cập nhật ngày trả tiền và trạng thái trả tiền
    UPDATE noPhaiTraNCC
    SET ngayTraTien = @ngayTraTien,
        trangThaiTraTien = 1
    WHERE maNPTNCC = @maNPTNCC;

    PRINT 'Cap nhat trang thai tra tien thanh cong!';
    SET @ret = 1;
END;
--Kiem tra 
--Cap nhat thanh cong
DECLARE @result BIT;
EXEC capNhatTrangThaiTraTien 
				1,               -- Mã nợ phải trả nhà cung cấp
				'2024-11-20',    -- Ngày trả tiền
				@result OUT;     -- Kết quả trả về
PRINT @result;					 -- Kết quả: 1 nếu thành công
--Loi ma khong ton tai
EXEC capNhatTrangThaiTraTien 
				999,             -- Mã nợ không tồn tại
				'2024-11-20',
				@result OUT;
-- Ket qua: Loi "Ma no phai tra khong ton tai!"
--Loi tra tien khong hop le
EXEC capNhatTrangThaiTraTien 
				1,               -- Mã nợ hợp lệ
				'2024-11-05',    -- Ngày trả tiền không hợp lệ (<= ngày nợ tiền)
				@result OUT;
-- Ket qua: Loi "Ngay tra tien phai lon hon ngay no tien!"


