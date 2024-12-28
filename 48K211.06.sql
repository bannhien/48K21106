GO
CREATE DATABASE Nhom48K21106;
GO
USE Nhom48K21106;
-- Tạo bảng taiKhoan
CREATE TABLE taiKhoan (
    tenDangNhap VARCHAR(50) PRIMARY KEY,
    matKhau VARCHAR(50)
);

-- Tạo bảng nguoiDung
CREATE TABLE nguoiDung (
    SDT CHAR(10) NOT NULL PRIMARY KEY,
    tenDangNhap VARCHAR(50) NOT NULL,
    hoTen VARCHAR(50) NOT NULL,
    email VARCHAR(100) NOT NULL,
    diaChi VARCHAR(100) NOT NULL,
    FOREIGN KEY (tenDangNhap) REFERENCES taiKhoan(tenDangNhap)
);

-- Tạo bảng khachHang
CREATE TABLE khachHang (
    maKH INT NOT NULL PRIMARY KEY IDENTITY(1,1),    
    hoTen VARCHAR(50) NOT NULL,
    SDT CHAR(10) NOT NULL
);

-- Tạo bảng nhaCungCap
CREATE TABLE nhaCungCap (
    maNCC INT NOT NULL PRIMARY KEY IDENTITY(1,1),    
    tenNCC VARCHAR(50) NOT NULL,
    SDT CHAR(10) NOT NULL
);

-- Tạo bảng sanPham
CREATE TABLE sanPham (
    maSP INT NOT NULL PRIMARY KEY IDENTITY(1,1),    
    tenSP VARCHAR(50) NOT NULL,
    soLuongSP INT NOT NULL,                           
    hinhAnhSP IMAGE,  
	giaBan NUMERIC(15,0),
	giaNhap NUMERIC(15,0),
    HSD DATE NOT NULL                                  
);

-- Tạo bảng donHangBan
CREATE TABLE donHangBan (
    maDHB INT NOT NULL PRIMARY KEY IDENTITY(1,1),    
    maKH INT NOT NULL,
    ngayTao DATE NOT NULL,
    tongTien NUMERIC(15,0) NOT NULL,
    FOREIGN KEY (maKH) REFERENCES khachHang(maKH)
);

-- Tạo bảng donHangBanCT
CREATE TABLE donHangBanCT (
    maDHBCT INT NOT NULL PRIMARY KEY IDENTITY(1,1),   
    maDHB INT NOT NULL,
    maSP INT NOT NULL,
	giaBan NUMERIC(15,0),
    soLuong INT NOT NULL,
    thanhTien NUMERIC(15,0),
    FOREIGN KEY (maDHB) REFERENCES donHangBan(maDHB),
    FOREIGN KEY (maSP) REFERENCES sanPham(maSP)
);

-- Tạo bảng donHangNhap
CREATE TABLE donHangNhap (
    maDHN INT NOT NULL PRIMARY KEY IDENTITY(1,1),      
    maNCC INT NOT NULL,                                  
    ngayTao DATE NOT NULL,                              
    tongTien NUMERIC(15,0),                              
    FOREIGN KEY (maNCC) REFERENCES nhaCungCap(maNCC) 
);

-- Tạo bảng donHangNhapCT
CREATE TABLE donHangNhapCT (
    maDHNCT INT NOT NULL PRIMARY KEY IDENTITY(1,1),    
    maDHN INT NOT NULL,                                  
    maSP INT NOT NULL,  
	giaNhap NUMERIC(15,0),
    soLuong INT NOT NULL,                                
    thanhTien NUMERIC(15,0),                            
    FOREIGN KEY (maDHN) REFERENCES donHangNhap(maDHN),  
    FOREIGN KEY (maSP) REFERENCES sanPham(maSP)        
);

-- Tạo bảng noPhaiTraKH
CREATE TABLE noPhaiTraKH (
    maNPTKH INT NOT NULL PRIMARY KEY IDENTITY(1,1),      
    maDHB INT NOT NULL,
    tienNo NUMERIC(15,0) NOT NULL,
    ngayNoTien DATE NOT NULL,
    trangThaiTraTien BIT NOT NULL,
    ngayTraTien DATE,
    FOREIGN KEY (maDHB) REFERENCES donHangBan(maDHB)
);

-- Tạo bảng noPhaiTraNCC
CREATE TABLE noPhaiTraNCC (
    maNPTNCC INT NOT NULL PRIMARY KEY IDENTITY(1,1),     
    maDHN INT NOT NULL,
    tienNo NUMERIC(15,0) NOT NULL,
    ngayNoTien DATE NOT NULL,
    trangThaiTraTien BIT NOT NULL,
    ngayTraTien DATE,
    FOREIGN KEY (maDHN) REFERENCES donHangNhap(maDHN)
);
