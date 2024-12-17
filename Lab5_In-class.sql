-- Lab 5 

-- Bài tập 1
-- 11.
CREATE TRIGGER trg_Check_NGHD_NGDK
ON HOADON
FOR INSERT, UPDATE
AS
BEGIN
    IF EXISTS (
        SELECT 1
        FROM inserted i
        JOIN KHACHHANG k ON i.MAKH = k.MAKH
        WHERE i.NGHD < k.NGDK
    )
    BEGIN
        RAISERROR ('Ngày mua hàng phải lớn hơn hoặc bằng ngày đăng ký thành viên.', 16, 1);
        ROLLBACK TRANSACTION;
    END
END;

-- 12.
CREATE TRIGGER trg_Check_NGHD_NGVL
ON HOADON
FOR INSERT, UPDATE
AS
BEGIN
    IF EXISTS (
        SELECT 1
        FROM inserted i
        JOIN NHANVIEN n ON i.MANV = n.MANV
        WHERE i.NGHD < n.NGVL
    )
    BEGIN
        RAISERROR ('Ngày mua hàng phải lớn hơn hoặc bằng ngày vào làm của nhân viên.', 16, 1);
        ROLLBACK TRANSACTION;
    END
END;

-- 13.
CREATE TRIGGER trg_Check_TRIGIA_TONGTIEN
ON HOADON
FOR INSERT, UPDATE
AS
BEGIN
    IF EXISTS (
        SELECT 1
        FROM inserted i
        CROSS APPLY (
            SELECT SUM(c.SL * s.GIA) AS Total
            FROM CTHD c
            JOIN SANPHAM s ON c.MASP = s.MASP
            WHERE c.SOHD = i.SOHD
        ) AS TotalCalc
        WHERE i.TRIGIA <> ISNULL(TotalCalc.Total, 0)
    )
    BEGIN
        RAISERROR ('Trị giá hóa đơn không khớp với tổng thành tiền của các chi tiết hóa đơn.', 16, 1);
        ROLLBACK TRANSACTION;
    END
END;

-- 14.
CREATE TRIGGER trg_Update_DOANHSO
ON HOADON
FOR INSERT, UPDATE, DELETE
AS
BEGIN
    UPDATE KHACHHANG
    SET DOANHSO = ISNULL((
        SELECT SUM(TRIGIA)
        FROM HOADON
        WHERE HOADON.MAKH = KHACHHANG.MAKH
    ), 0)
    WHERE EXISTS (
        SELECT 1
        FROM HOADON h
        WHERE h.MAKH = KHACHHANG.MAKH
    );
END;

-- Bài tập 2
-- 9.
CREATE TRIGGER trg_Check_TRGLOP_InClass
ON LOP
FOR INSERT, UPDATE
AS
BEGIN
    IF EXISTS (
        SELECT 1
        FROM inserted i
        LEFT JOIN HOCVIEN h ON i.TRGLOP = h.MAHV AND i.MALOP = h.MALOP
        WHERE h.MAHV IS NULL
    )
    BEGIN
        RAISERROR ('Lớp trưởng phải là học viên của lớp đó.', 16, 1);
        ROLLBACK TRANSACTION;
    END
END;

-- 10.
CREATE TRIGGER trg_Check_TRGKHOA
ON KHOA
FOR INSERT, UPDATE
AS
BEGIN
    IF EXISTS (
        SELECT 1
        FROM inserted i
        JOIN GIAOVIEN g ON i.TRGKHOA = g.MAGV
        WHERE g.MAKHOA <> i.MAKHOA OR g.HOCVI NOT IN ('TS', 'PTS')
    )
    BEGIN
        RAISERROR ('Trưởng khoa phải là giáo viên thuộc khoa và có học vị "TS" hoặc "PTS".', 16, 1);
        ROLLBACK TRANSACTION;
    END
END;

-- 15.
CREATE TRIGGER trg_Check_ThiLai
ON KETQUATHI
FOR INSERT, UPDATE
AS
BEGIN
    IF EXISTS (
        SELECT 1
        FROM inserted i
        JOIN KETQUATHI k ON i.MAHV = k.MAHV AND i.MAMH = k.MAMH
        WHERE i.LANTHI > 1 AND k.LANTHI = i.LANTHI - 1 AND k.DIEM >= 5
    )
    BEGIN
        RAISERROR ('Học viên chỉ được thi lại nếu điểm của lần thi trước dưới 5.', 16, 1);
        ROLLBACK TRANSACTION;
    END
END;

-- 16.
CREATE TRIGGER trg_Check_MaxSubjects_PerTerm
ON GIANGDAY
FOR INSERT, UPDATE
AS
BEGIN
    IF EXISTS (
        SELECT MALOP, HOCKY, NAM, COUNT(MAMH) AS MonHoc
        FROM GIANGDAY
        GROUP BY MALOP, HOCKY, NAM
        HAVING COUNT(MAMH) > 3
    )
    BEGIN
        RAISERROR ('Mỗi lớp chỉ được học tối đa 3 môn trong một học kỳ.', 16, 1);
        ROLLBACK TRANSACTION;
    END
END;

-- 17.
CREATE TRIGGER trg_Check_SISO
ON HOCVIEN
FOR INSERT, UPDATE, DELETE
AS
BEGIN
    UPDATE LOP
    SET SISO = (
        SELECT COUNT(*)
        FROM HOCVIEN
        WHERE HOCVIEN.MALOP = LOP.MALOP
    );
END;

-- 18.
CREATE TRIGGER trg_Check_DIEUKIEN
ON DIEUKIEN
FOR INSERT, UPDATE
AS
BEGIN
    IF EXISTS (
        SELECT 1
        FROM inserted i
        WHERE i.MAMH = i.MAMH_TRUOC
           OR EXISTS (
                SELECT 1
                FROM DIEUKIEN d
                WHERE (d.MAMH = i.MAMH_TRUOC AND d.MAMH_TRUOC = i.MAMH)
            )
    )
    BEGIN
        RAISERROR ('Điều kiện môn học không hợp lệ (trùng hoặc vòng lặp).', 16, 1);
        ROLLBACK TRANSACTION;
    END
END;

-- 19.
CREATE TRIGGER trg_Check_MUCLUONG
ON GIAOVIEN
FOR INSERT, UPDATE
AS
BEGIN
    IF EXISTS (
        SELECT 1
        FROM inserted i
        JOIN GIAOVIEN g
        ON i.HOCVI = g.HOCVI AND i.HOCHAM = g.HOCHAM AND i.HESO = g.HESO
        WHERE i.MUCLUONG <> g.MUCLUONG
    )
    BEGIN
        RAISERROR ('Giáo viên có cùng học vị, học hàm, hệ số lương thì mức lương phải bằng nhau.', 16, 1);
        ROLLBACK TRANSACTION;
    END
END;

-- 20.
CREATE TRIGGER trg_Check_ThiNgay
ON KETQUATHI
FOR INSERT, UPDATE
AS
BEGIN
    IF EXISTS (
        SELECT 1
        FROM inserted i
        JOIN KETQUATHI k ON i.MAHV = k.MAHV AND i.MAMH = k.MAMH
        WHERE i.LANTHI > k.LANTHI AND i.NGTHI <= k.NGTHI
    )
    BEGIN
        RAISERROR ('Ngày thi của lần thi sau phải lớn hơn ngày thi của lần thi trước.', 16, 1);
        ROLLBACK TRANSACTION;
    END
END;

-- 21.
CREATE TRIGGER trg_Check_TuThuMonHoc
ON GIANGDAY
FOR INSERT, UPDATE
AS
BEGIN
    IF EXISTS (
        SELECT 1
        FROM inserted i
        JOIN DIEUKIEN d ON i.MAMH = d.MAMH
        JOIN GIANGDAY gd ON gd.MAMH = d.MAMH_TRUOC AND gd.MALOP = i.MALOP
        WHERE gd.DENNGAY > i.TUNGAY
    )
    BEGIN
        RAISERROR ('Môn học trước phải kết thúc trước khi học môn sau.', 16, 1);
        ROLLBACK TRANSACTION;
    END
END;

-- 22.
CREATE TRIGGER trg_Check_GiaoVien_ThuocKhoa
ON GIANGDAY
FOR INSERT, UPDATE
AS
BEGIN
    IF EXISTS (
        SELECT 1
        FROM inserted i
        JOIN GIAOVIEN g ON i.MAGV = g.MAGV
        JOIN MONHOC m ON i.MAMH = m.MAMH
        WHERE g.MAKHOA <> m.MAKHOA
    )
    BEGIN
        RAISERROR ('Giáo viên chỉ được dạy các môn thuộc khoa của mình.', 16, 1);
        ROLLBACK TRANSACTION;
    END
END;

-- 23.
CREATE TRIGGER trg_Update_MUCLUONG
ON GIAOVIEN
FOR INSERT, UPDATE
AS
BEGIN
    UPDATE GIAOVIEN
    SET MUCLUONG = HESO * 450000
    WHERE MAGV IN (SELECT MAGV FROM inserted);
END;

-- 24.
CREATE TRIGGER trg_Check_MaxSISO
ON LOP
FOR INSERT, UPDATE
AS
BEGIN
    IF EXISTS (
        SELECT 1
        FROM inserted i
        WHERE i.SISO > 50
    )
    BEGIN
        RAISERROR ('Sĩ số lớp không được vượt quá 50 học viên.', 16, 1);
        ROLLBACK TRANSACTION;
    END
END;
