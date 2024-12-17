-- Câu hỏi và ví dụ về Triggers (101-110)

-- 101. Tạo một trigger để tự động cập nhật trường NgayCapNhat trong bảng ChuyenGia mỗi khi có sự thay đổi thông tin.
CREATE TRIGGER trg_UpdateNgayCapNhat
ON ChuyenGia
AFTER UPDATE
AS
BEGIN
    UPDATE ChuyenGia
    SET NgayCapNhat = GETDATE()
    FROM ChuyenGia c
    INNER JOIN inserted i ON c.MaChuyenGia = i.MaChuyenGia;
END;

-- 102. Tạo một trigger để ghi log mỗi khi có sự thay đổi trong bảng DuAn.
CREATE TABLE DuAn_Log (
    LogID INT IDENTITY PRIMARY KEY,
    MaDuAn INT,
    HanhDong NVARCHAR(50),
    NgayThayDoi DATETIME,
    NguoiThucHien NVARCHAR(100)
);

CREATE TRIGGER trg_LogDuAn
ON DuAn
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    INSERT INTO DuAn_Log (MaDuAn, HanhDong, NgayThayDoi, NguoiThucHien)
    SELECT 
        ISNULL(i.MaDuAn, d.MaDuAn),
        CASE 
            WHEN EXISTS (SELECT * FROM inserted) AND EXISTS (SELECT * FROM deleted) THEN 'UPDATE'
            WHEN EXISTS (SELECT * FROM inserted) THEN 'INSERT'
            ELSE 'DELETE'
        END,
        GETDATE(),
        SYSTEM_USER
    FROM inserted i
    FULL OUTER JOIN deleted d ON i.MaDuAn = d.MaDuAn;
END;

-- 103. Tạo một trigger để đảm bảo rằng một chuyên gia không thể tham gia vào quá 5 dự án cùng một lúc.
CREATE TRIGGER trg_LimitChuyenGiaDuAn
ON ChuyenGia_DuAn
AFTER INSERT
AS
BEGIN
    IF EXISTS (
        SELECT 1
        FROM ChuyenGia_DuAn
        GROUP BY MaChuyenGia
        HAVING COUNT(*) > 5
    )
    BEGIN
        RAISERROR ('Một chuyên gia không thể tham gia quá 5 dự án!', 16, 1);
        ROLLBACK TRANSACTION;
    END;
END;

-- 104. Tạo một trigger để tự động cập nhật số lượng nhân viên trong bảng CongTy mỗi khi có sự thay đổi trong bảng ChuyenGia.
CREATE TRIGGER trg_UpdateSoLuongNhanVien
ON ChuyenGia
AFTER INSERT, DELETE
AS
BEGIN
    UPDATE CongTy
    SET SoLuongNhanVien = (
        SELECT COUNT(*) 
        FROM ChuyenGia
        WHERE ChuyenGia.MaCongTy = CongTy.MaCongTy
    );
END;

-- 105. Tạo một trigger để ngăn chặn việc xóa các dự án đã hoàn thành.
CREATE TRIGGER trg_PreventDeleteCompletedProjects
ON DuAn
INSTEAD OF DELETE
AS
BEGIN
    IF EXISTS (
        SELECT 1
        FROM deleted
        WHERE TrangThai = 'HoanThanh'
    )
    BEGIN
        RAISERROR ('Không thể xóa dự án đã hoàn thành!', 16, 1);
    END
    ELSE
    BEGIN
        DELETE FROM DuAn
        WHERE MaDuAn IN (SELECT MaDuAn FROM deleted);
    END;
END;

-- 106. Tạo một trigger để tự động cập nhật cấp độ kỹ năng của chuyên gia khi họ tham gia vào một dự án mới.
CREATE TRIGGER trg_UpdateSkillLevel
ON ChuyenGia_DuAn
AFTER INSERT
AS
BEGIN
    UPDATE ck
    SET CapDo = CapDo + 1
    FROM ChuyenGia_KyNang ck
    JOIN inserted i ON ck.MaChuyenGia = i.MaChuyenGia;
END;

-- 107. Tạo một trigger để ghi log mỗi khi có sự thay đổi cấp độ kỹ năng của chuyên gia.
CREATE TABLE KyNang_Log (
    LogID INT IDENTITY PRIMARY KEY,
    MaChuyenGia INT,
    MaKyNang INT,
    CapDoCu INT,
    CapDoMoi INT,
    NgayThayDoi DATETIME
);

CREATE TRIGGER trg_LogSkillLevelChange
ON ChuyenGia_KyNang
AFTER UPDATE
AS
BEGIN
    INSERT INTO KyNang_Log (MaChuyenGia, MaKyNang, CapDoCu, CapDoMoi, NgayThayDoi)
    SELECT d.MaChuyenGia, d.MaKyNang, d.CapDo, i.CapDo, GETDATE()
    FROM inserted i
    JOIN deleted d ON i.MaChuyenGia = d.MaChuyenGia AND i.MaKyNang = d.MaKyNang
    WHERE i.CapDo <> d.CapDo;
END;

-- 108. Tạo một trigger để đảm bảo rằng ngày kết thúc của dự án luôn lớn hơn ngày bắt đầu.
CREATE TRIGGER trg_CheckProjectDates
ON DuAn
AFTER INSERT, UPDATE
AS
BEGIN
    IF EXISTS (
        SELECT 1
        FROM inserted
        WHERE NgayKetThuc <= NgayBatDau
    )
    BEGIN
        RAISERROR ('Ngày kết thúc phải lớn hơn ngày bắt đầu!', 16, 1);
        ROLLBACK TRANSACTION;
    END;
END;

-- 109. Tạo một trigger để tự động xóa các bản ghi liên quan trong bảng ChuyenGia_KyNang khi một kỹ năng bị xóa.
CREATE TRIGGER trg_DeleteSkillDependencies
ON KyNang
AFTER DELETE
AS
BEGIN
    DELETE FROM ChuyenGia_KyNang
    WHERE MaKyNang IN (SELECT MaKyNang FROM deleted);
END;

-- 110. Tạo một trigger để đảm bảo rằng một công ty không thể có quá 10 dự án đang thực hiện cùng một lúc.
CREATE TRIGGER trg_LimitCompanyProjects
ON DuAn
AFTER INSERT, UPDATE
AS
BEGIN
    IF EXISTS (
        SELECT 1
        FROM DuAn
        WHERE TrangThai = 'DangThucHien'
        GROUP BY MaCongTy
        HAVING COUNT(*) > 10
    )
    BEGIN
        RAISERROR ('Công ty không thể có quá 10 dự án đang thực hiện!', 16, 1);
        ROLLBACK TRANSACTION;
    END;
END;

-- Câu hỏi và ví dụ về Triggers bổ sung (123-135)

-- 123. Tạo một trigger để tự động cập nhật lương của chuyên gia dựa trên cấp độ kỹ năng và số năm kinh nghiệm.


-- 124. Tạo một trigger để tự động gửi thông báo khi một dự án sắp đến hạn (còn 7 ngày).

-- Tạo bảng ThongBao nếu chưa có


-- 125. Tạo một trigger để ngăn chặn việc xóa hoặc cập nhật thông tin của chuyên gia đang tham gia dự án.


-- 126. Tạo một trigger để tự động cập nhật số lượng chuyên gia trong mỗi chuyên ngành.

-- Tạo bảng ThongKeChuyenNganh nếu chưa có

-- 127. Tạo một trigger để tự động tạo bản sao lưu của dự án khi nó được đánh dấu là hoàn thành.

-- Tạo bảng DuAnHoanThanh nếu chưa có


-- 128. Tạo một trigger để tự động cập nhật điểm đánh giá trung bình của công ty dựa trên điểm đánh giá của các dự án.



-- 129. Tạo một trigger để tự động phân công chuyên gia vào dự án dựa trên kỹ năng và kinh nghiệm.



-- 130. Tạo một trigger để tự động cập nhật trạng thái "bận" của chuyên gia khi họ được phân công vào dự án mới.



-- 131. Tạo một trigger để ngăn chặn việc thêm kỹ năng trùng lặp cho một chuyên gia.



-- 132. Tạo một trigger để tự động tạo báo cáo tổng kết khi một dự án kết thúc.


-- 133. Tạo một trigger để tự động cập nhật thứ hạng của công ty dựa trên số lượng dự án hoàn thành và điểm đánh giá.



-- 133. (tiếp tục) Tạo một trigger để tự động cập nhật thứ hạng của công ty dựa trên số lượng dự án hoàn thành và điểm đánh giá.


-- 134. Tạo một trigger để tự động gửi thông báo khi một chuyên gia được thăng cấp (dựa trên số năm kinh nghiệm).


-- 135. Tạo một trigger để tự động cập nhật trạng thái "khẩn cấp" cho dự án khi thời gian còn lại ít hơn 10% tổng thời gian dự án.


-- 136. Tạo một trigger để tự động cập nhật số lượng dự án đang thực hiện của mỗi chuyên gia.


-- 137. Tạo một trigger để tự động tính toán và cập nhật tỷ lệ thành công của công ty dựa trên số dự án hoàn thành và tổng số dự án.

-- 138. Tạo một trigger để tự động ghi log mỗi khi có thay đổi trong bảng lương của chuyên gia.

-- 139. Tạo một trigger để tự động cập nhật số lượng chuyên gia cấp cao trong mỗi công ty.


-- 140. Tạo một trigger để tự động cập nhật trạng thái "cần bổ sung nhân lực" cho dự án khi số lượng chuyên gia tham gia ít hơn yêu cầu.


