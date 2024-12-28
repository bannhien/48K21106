USE Nhom48K21106;

-- Tạo Dữ Liệu cho Bảng taiKhoan
GO
DECLARE @i INT = 1;
WHILE @i <= 1000
BEGIN
    INSERT INTO taiKhoan (tenDangNhap, matKhau)
    VALUES (
        'user' + CAST(@i AS VARCHAR(50)),             -- Tên đăng nhập từ user1 đến user100
        'password' + CAST(@i AS VARCHAR(50))          -- Mật khẩu từ password1 đến password100
    );
    SET @i = @i + 1;
END;

-- Tạo Dữ Liệu cho Bảng nguoiDung
GO
DECLARE @i INT = 1;
SET @i = 1;
WHILE @i <= 1000
BEGIN
    INSERT INTO nguoiDung (SDT, tenDangNhap, hoTen, email, diaChi)
    VALUES (
        RIGHT('090' + CAST(@i AS VARCHAR(10)), 10),    -- Số điện thoại từ 0900000001 đến 0900000100
        'user' + CAST(@i AS VARCHAR(50)),              -- Liên kết tên đăng nhập với bảng taiKhoan
        'Nguoi Dung ' + CAST(@i AS VARCHAR(50)),       -- Họ tên
        'nguoidung' + CAST(@i AS VARCHAR(50)) + '@email.com',  -- Email
        'Dia Chi ' + CAST(@i AS VARCHAR(100))           -- Địa chỉ
    );
    SET @i = @i + 1;
END;
-- Tạo Dữ Liệu cho Bảng sanPham
GO
DECLARE @i INT = 1;
SET @i = 1;
WHILE @i <= 1000
BEGIN
    INSERT INTO sanPham (tenSP, soLuongSP, hinhAnhSP, giaNhap, giaBan, HSD)
    VALUES (
        'San Pham ' + CAST(@i AS VARCHAR(50)),        -- Tên sản phẩm
        ROUND(RAND() * 100, 0),                      -- Số lượng ngẫu nhiên từ 0 đến 100
		Null,                                          -- Hình ảnh sản phẩm (dữ liệu rỗng)
		ROUND(RAND() * 1000000, 0),					-- Giá nhập sản phẩm
		ROUND(RAND() * 1000000, 0),					-- Giá bán sản phẩm
        DATEADD(DAY, @i, GETDATE())					-- Hạn sử dụng
    );
    SET @i = @i + 1;
END;

SELECT * FROM sanPham

-- Tạo Dữ Liệu cho Bảng khachHang
GO
DECLARE @i INT = 1;
SET @i = 1;
WHILE @i <= 1000
BEGIN
    INSERT INTO khachHang (hoTen, SDT)
    VALUES (
        'Khach Hang ' + CAST(@i AS VARCHAR(50)),      -- Họ tên khách hàng
        '012345' + RIGHT('0000' + CAST(@i AS VARCHAR(4)), 4)    -- Số điện thoại
    );
    SET @i = @i + 1;
END;

SELECT * FROM khachHang

-- Tạo Dữ Liệu cho Bảng nhaCungCap
GO
DECLARE @i INT = 1;
SET @i = 1;
WHILE @i <= 1000
BEGIN
    INSERT INTO nhaCungCap (tenNCC, SDT)
    VALUES (
        'Nha Cung Cap ' + CAST(@i AS VARCHAR(50)),    -- Tên nhà cung cấp
        '098765' + RIGHT('0000' + CAST(@i AS VARCHAR(4)), 4)    -- Số điện thoại nhà cung cấp
    );
    SET @i = @i + 1;
END;

SELECT * FROM nhaCungCap

-- Tạo Dữ Liệu cho Bảng donHangBan
GO
DECLARE @i INT = 1;
DECLARE @tongTien NUMERIC(15, 0);

WHILE @i <= 1000
BEGIN
    -- Tạo tổng tiền bằng tổng các thanhTien từ bảng donHangBanCT
    SET @tongTien = (
        SELECT SUM(thanhTien)
        FROM donHangBanCT
        WHERE maDHB = @i
    );

    -- Nếu chưa có dòng nào trong bảng chi tiết, mặc định tổng tiền = 0
    IF @tongTien IS NULL
        SET @tongTien = 0;

    INSERT INTO donHangBan (maKH, ngayTao, tongTien)
    VALUES (
        ROUND(RAND() * 1000, 0) + 1, -- Mã khách hàng ngẫu nhiên
        DATEADD(DAY, @i, GETDATE()), -- Ngày tạo ngẫu nhiên tăng dần
        @tongTien                    -- Tổng tiền từ bảng chi tiết
    );

    SET @i = @i + 1;
END;

SELECT * FROM donHangBan;

-- Tạo Dữ Liệu cho Bảng donHangBanCT
GO
DECLARE @i INT = 1;
DECLARE @maSP INT, @giaBan NUMERIC(15,0), @soLuong INT, @thanhTien NUMERIC(15,0);
SET @i = 1;

WHILE @i <= 1000
BEGIN
    -- Lấy mã sản phẩm ngẫu nhiên từ bảng sanPham
    SET @maSP = ROUND(RAND() * 1000, 0) + 1;

    -- Lấy giá bán từ bảng sanPham
    SET @giaBan = (
        SELECT giaBan
        FROM sanPham
        WHERE maSP = @maSP
    );

    -- Tạo số lượng ngẫu nhiên từ 1 đến 10
    SET @soLuong = ROUND(RAND() * 10, 0) + 1;

    -- Tính thành tiền
    SET @thanhTien = @giaBan * @soLuong;

    -- Thêm dữ liệu vào bảng donHangBanCT
    INSERT INTO donHangBanCT (maDHB, maSP, giaBan, soLuong, thanhTien)
    VALUES (
        ROUND(RAND() * 1000, 0) + 1, -- Mã đơn hàng bán ngẫu nhiên từ 1-1000
        @maSP,                      -- Mã sản phẩm ngẫu nhiên
        @giaBan,                    -- Giá bán lấy từ bảng sanPham
        @soLuong,                   -- Số lượng
        @thanhTien                  -- Thành tiền (giaBan * soLuong)
    );

    SET @i = @i + 1;
END;

SELECT * FROM donHangBanCT;

-- Tạo Dữ Liệu cho Bảng donHangNhap
GO
DECLARE @i INT = 1;
DECLARE @tongTien NUMERIC(15, 0);

WHILE @i <= 1000
BEGIN
    -- Tạo tổng tiền bằng tổng các thanhTien từ bảng donHangNhapCT
    SET @tongTien = (
        SELECT SUM(thanhTien)
        FROM donHangNhapCT
        WHERE maDHN = @i
    );

    -- Nếu chưa có dòng nào trong bảng chi tiết, mặc định tổng tiền = 0
    IF @tongTien IS NULL
        SET @tongTien = 0;

    INSERT INTO donHangNhap (maNCC, ngayTao, tongTien)
    VALUES (
        ROUND(RAND() * 100, 0) + 1, -- Mã nhà cung cấp ngẫu nhiên
        DATEADD(DAY, @i, GETDATE()), -- Ngày tạo ngẫu nhiên tăng dần
        @tongTien                    -- Tổng tiền từ bảng chi tiết
    );

    SET @i = @i + 1;
END;

SELECT * FROM donHangNhap;

-- Tạo Dữ Liệu cho Bảng donHangNhapCT
GO
DECLARE @i INT = 1;
DECLARE @maSP INT, @giaNhap NUMERIC(15,0), @soLuong INT, @thanhTien NUMERIC(15,0);
SET @i = 1;

WHILE @i <= 1000
BEGIN
    -- Lấy mã sản phẩm ngẫu nhiên từ bảng sanPham
    SET @maSP = ROUND(RAND() * 1000, 0) + 1;

    -- Lấy giá nhập từ bảng sanPham
    SET @giaNhap = (
        SELECT giaNhap
        FROM sanPham
        WHERE maSP = @maSP
    );

    -- Tạo số lượng ngẫu nhiên từ 1 đến 10
    SET @soLuong = ROUND(RAND() * 10, 0) + 1;

    -- Tính thành tiền
    SET @thanhTien = @giaNhap * @soLuong;

    -- Thêm dữ liệu vào bảng donHangNhapCT
    INSERT INTO donHangNhapCT (maDHN, maSP, giaNhap, soLuong, thanhTien)
    VALUES (
        ROUND(RAND() * 1000, 0) + 1, -- Mã đơn hàng nhập ngẫu nhiên từ 1-1000
        @maSP,                      -- Mã sản phẩm ngẫu nhiên
        @giaNhap,                   -- Giá nhập lấy từ bảng sanPham
        @soLuong,                   -- Số lượng
        @thanhTien                  -- Thành tiền (giaNhap * soLuong)
    );

    SET @i = @i + 1;
END;

SELECT * FROM donHangNhapCT;

-- Tạo Dữ Liệu cho Bảng noPhaiTraKH
GO
DECLARE @i INT = 1;
SET @i = 1;
WHILE @i <= 1000
BEGIN
    INSERT INTO noPhaiTraKH (maDHB, tienNo, ngayNoTien, trangThaiTraTien, ngayTraTien)
    VALUES (
        ROUND(RAND() * 1000, 0) + 1,                   -- Mã đơn hàng bán ngẫu nhiên
        ROUND(RAND() * 1000000, 0),                    -- Tiền nợ ngẫu nhiên
        DATEADD(DAY, -(@i % 365), GETDATE()),         -- Ngày nợ tiền
        0,                                            -- Trạng thái chưa trả tiền
        NULL                                          -- Ngày trả tiền
    );
    SET @i = @i + 1;
END;

SELECT * FROM noPhaiTraKH

-- Tạo Dữ Liệu cho Bảng noPhaiTraNCC
GO
DECLARE @i INT = 1;
SET @i = 1;
WHILE @i <= 1000
BEGIN
    INSERT INTO noPhaiTraNCC (maDHN, tienNo, ngayNoTien, trangThaiTraTien, ngayTraTien)
    VALUES (
        ROUND(RAND() * 1000, 0) + 1,                    -- Mã đơn hàng nhập ngẫu nhiên
        ROUND(RAND() * 1000000, 0),                      -- Tiền nợ ngẫu nhiên
        DATEADD(DAY, -(@i % 365), GETDATE()),         -- Ngày nợ tiền
        0,                                            -- Trạng thái chưa trả tiền
        NULL                                          -- Ngày trả tiền
    );
    SET @i = @i + 1;
END;

SELECT * FROM noPhaiTraNCC
