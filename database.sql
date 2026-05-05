-- ============================================================================
-- CINEMA CONCURRENCY & TRANSACTION DEMONSTRATION
-- Database: CinemaDB
-- Mục đích: Demonstrating Lost Update vs Pessimistic Lock & Transaction Rollback
-- ============================================================================

-- ============================================================================
-- BLOCK 1: TẠOA DATABASE VÀ CẤU TRÚC BẢNG
-- ============================================================================
USE master;
GO

-- Drop database nếu tồn tại
IF EXISTS (SELECT name FROM sys.databases WHERE name = 'CinemaDB')
    DROP DATABASE CinemaDB;
GO

-- Tạo database
CREATE DATABASE CinemaDB;
GO

USE CinemaDB;
GO

-- Bảng Users (Người dùng)
CREATE TABLE Users (
    UserID INT PRIMARY KEY IDENTITY(1,1),
    UserName NVARCHAR(100) NOT NULL,
    Email NVARCHAR(100),
    CreatedAt DATETIME DEFAULT GETDATE()
);

-- Bảng ShowTimes (Suất chiếu)
CREATE TABLE ShowTimes (
    ShowTimeID INT PRIMARY KEY IDENTITY(1,1),
    MovieName NVARCHAR(200) NOT NULL,
    StartTime DATETIME NOT NULL,
    EndTime DATETIME NOT NULL,
    CreatedAt DATETIME DEFAULT GETDATE()
);

-- Bảng Seats (Ghế ngồi)
-- Status: 0=Trống, 1=Đang giữ, 2=Đã bán
CREATE TABLE Seats (
    SeatID INT PRIMARY KEY IDENTITY(1,1),
    ShowTimeID INT NOT NULL,
    SeatName NVARCHAR(10) NOT NULL,
    [Status] INT DEFAULT 0,  -- 0=Trống, 1=Đang giữ, 2=Đã bán
    UserIDHeld INT NULL,     -- Người đang giữ ghế
    CreatedAt DATETIME DEFAULT GETDATE(),
    FOREIGN KEY (ShowTimeID) REFERENCES ShowTimes(ShowTimeID),
    FOREIGN KEY (UserIDHeld) REFERENCES Users(UserID)
);

-- Bảng Payments (Thanh toán)
CREATE TABLE Payments (
    PaymentID INT PRIMARY KEY IDENTITY(1,1),
    SeatID INT NOT NULL,
    UserID INT NOT NULL,
    Amount DECIMAL(10,2),
    PaymentStatus INT DEFAULT 0,  -- 0=Pending, 1=Success, 2=Failed
    CreatedAt DATETIME DEFAULT GETDATE(),
    FOREIGN KEY (SeatID) REFERENCES Seats(SeatID),
    FOREIGN KEY (UserID) REFERENCES Users(UserID)
);

PRINT '✓ Database và bảng được tạo thành công!';
GO

-- ============================================================================
-- BLOCK 2: THÊMDỮ LIỆU MẪU
-- ============================================================================

-- Thêm Users
INSERT INTO Users (UserName, Email) VALUES
    (N'Khách A', 'customerA@cinema.vn'),
    (N'Khách B', 'customerB@cinema.vn'),
    (N'Admin', 'admin@cinema.vn');

-- Thêm ShowTimes
INSERT INTO ShowTimes (MovieName, StartTime, EndTime) VALUES
    (N'Phim Hành Động 1', '2026-05-05 10:00:00', '2026-05-05 12:00:00'),
    (N'Phim Hành Động 1', '2026-05-05 14:00:00', '2026-05-05 16:00:00');

-- Thêm Seats (8x8 = 64 ghế)
DECLARE @ShowTimeID INT = 1;
DECLARE @Row INT = 1;
DECLARE @Col INT = 1;

WHILE @Row <= 8
BEGIN
    SET @Col = 1;
    WHILE @Col <= 8
    BEGIN
        INSERT INTO Seats (ShowTimeID, SeatName, [Status]) 
        VALUES (@ShowTimeID, CHAR(64 + @Row) + CAST(@Col AS NVARCHAR(2)), 0);
        SET @Col = @Col + 1;
    END
    SET @Row = @Row + 1;
END

PRINT '✓ Dữ liệu mẫu được thêm thành công!';
GO

-- ============================================================================
-- BLOCK 3: PROCEDURE sp_HoldSeat_Demo (CÓ CHỦ ĐÍCH CÓ CONCURRENCY ISSUE)
-- ============================================================================

CREATE PROCEDURE sp_HoldSeat_Demo
    @SeatID INT,
    @UserID INT,
    @IsSafeMode BIT = 0
AS
BEGIN
    SET NOCOUNT ON;
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

    BEGIN TRY
        BEGIN TRAN

        DECLARE @CurrentStatus INT;

        -- Nhánh 1: CÓ CHỦ ĐÍCH gây LOST UPDATE (IsSafeMode = 0)
        IF @IsSafeMode = 0
        BEGIN
            PRINT '⚠️ [UNSAFE MODE] Không dùng Lock - Dễ bị Lost Update!';
            
            -- Đọc trạng thái ghế (không Lock)
            SELECT @CurrentStatus = [Status]
            FROM Seats
            WHERE SeatID = @SeatID;

            -- Kiểm tra ghế có trống không
            IF @CurrentStatus != 0
            BEGIN
                THROW 50001, N'Ghế không trống!', 1;
            END

            -- Giả lập độ trễ mạng (5 giây) - Race condition xảy ra ở đây!
            PRINT '⏳ Chờ 5 giây (giả lập độ trễ mạng) - 2 Transaction có thể cùng lọt vào!';
            WAITFOR DELAY '00:00:05';

            -- Cập nhật ghế thành "Đang giữ" (Status = 1)
            UPDATE Seats
            SET [Status] = 1, UserIDHeld = @UserID
            WHERE SeatID = @SeatID;

            PRINT '✓ [UNSAFE] Ghế đã được giữ (nhưng có thể bị trùng lặp!)';
        END

        -- Nhánh 2: BẢO VỆ AN TOÀN (IsSafeMode = 1)
        ELSE
        BEGIN
            PRINT '🔒 [SAFE MODE] Dùng UPDLOCK & NOWAIT - Pessimistic Lock!';

            BEGIN TRY
                -- Đọc ghế với UPDLOCK & NOWAIT
                SELECT @CurrentStatus = [Status]
                FROM Seats WITH (UPDLOCK, NOWAIT)
                WHERE SeatID = @SeatID;
            END TRY
            BEGIN CATCH
                IF ERROR_NUMBER() = 1222  -- Lock timeout (NOWAIT)
                BEGIN
                    THROW 50002, N'Ghế đang được giao dịch bởi người khác!', 1;
                END
                ELSE
                BEGIN
                    THROW;
                END
            END CATCH

            -- Kiểm tra ghế có trống không
            IF @CurrentStatus != 0
            BEGIN
                THROW 50003, N'Ghế không trống!', 1;
            END

            -- Giả lập độ trễ (5 giây) nhưng đã được LOCK - các giao dịch khác phải chờ
            PRINT '⏳ Chờ 5 giây (giữ Lock) - các giao dịch khác bị chặn!';
            WAITFOR DELAY '00:00:05';

            -- Cập nhật ghế thành "Đang giữ" (Status = 1)
            UPDATE Seats
            SET [Status] = 1, UserIDHeld = @UserID
            WHERE SeatID = @SeatID;

            PRINT '✓ [SAFE] Ghế được Lock và Update an toàn!';
        END

        COMMIT TRAN
        RETURN 0;

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRAN;

        PRINT '❌ LỖI: ' + ERROR_MESSAGE();
        THROW;
    END CATCH
END
GO

PRINT '✓ Procedure sp_HoldSeat_Demo được tạo thành công!';
GO

-- ============================================================================
-- BLOCK 4: PROCEDURE sp_Payment (XỬ LÝ GIAO DỊCH)
-- ============================================================================

CREATE PROCEDURE sp_Payment
    @SeatID INT,
    @UserID INT,
    @SimulateError BIT = 0
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        BEGIN TRAN

        DECLARE @CurrentStatus INT;
        DECLARE @PaymentAmount DECIMAL(10,2) = 150000;  -- 150k VND

        -- Kiểm tra ghế đang được giữ
        SELECT @CurrentStatus = [Status]
        FROM Seats
        WHERE SeatID = @SeatID AND UserIDHeld = @UserID;

        IF @CurrentStatus != 1
        BEGIN
            THROW 50004, N'Ghế không trong trạng thái "Đang giữ" hoặc không phải của bạn!', 1;
        END

        -- Giả lập lỗi thanh toán (Optional)
        IF @SimulateError = 1
        BEGIN
            PRINT '⚠️ [SIMULATE ERROR] Cố tình ném lỗi để test Rollback!';
            THROW 50005, N'Lỗi giả lập: Kết nối mạng bị gián đoạn!', 1;
        END

        -- Cập nhật ghế thành "Đã bán" (Status = 2)
        UPDATE Seats
        SET [Status] = 2
        WHERE SeatID = @SeatID;

        -- Thêm bản ghi thanh toán
        INSERT INTO Payments (SeatID, UserID, Amount, PaymentStatus)
        VALUES (@SeatID, @UserID, @PaymentAmount, 1);

        COMMIT TRAN
        PRINT '✓ Thanh toán thành công! Ghế chuyển thành "Đã bán"';
        RETURN 0;

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRAN;

        PRINT '❌ Thanh toán thất bại, ghi vé được Rollback!';
        PRINT '❌ LỖI: ' + ERROR_MESSAGE();
        THROW;
    END CATCH
END
GO

PRINT '✓ Procedure sp_Payment được tạo thành công!';
GO

-- ============================================================================
-- BLOCK 5: TẠO INDEX ĐỂ TỐI ƯU
-- ============================================================================

CREATE NONCLUSTERED INDEX IX_Seats_Status 
ON Seats([Status])
INCLUDE (SeatID, UserIDHeld);

CREATE NONCLUSTERED INDEX IX_Seats_ShowTimeID_Status
ON Seats(ShowTimeID, [Status]);

PRINT '✓ Index được tạo thành công!';
GO

-- ============================================================================
-- BLOCK 6: VIEW để dễ kiểm tra trạng thái
-- ============================================================================

CREATE VIEW vw_SeatStatus AS
SELECT 
    S.SeatID,
    S.SeatName,
    CASE S.[Status] 
        WHEN 0 THEN 'Trống'
        WHEN 1 THEN 'Đang giữ'
        WHEN 2 THEN 'Đã bán'
    END AS StatusName,
    S.[Status],
    U.UserName,
    ST.MovieName
FROM Seats S
LEFT JOIN Users U ON S.UserIDHeld = U.UserID
LEFT JOIN ShowTimes ST ON S.ShowTimeID = ST.ShowTimeID;

PRINT '✓ View vw_SeatStatus được tạo!';
GO

-- ============================================================================
-- BLOCK 7: TEST PROCEDURES
-- ============================================================================

-- Test đơn giản
PRINT '========== TEST SP_HOLDSEAT_DEMO (Safe Mode) ==========';
EXEC sp_HoldSeat_Demo @SeatID = 1, @UserID = 1, @IsSafeMode = 1;
GO

-- Kiểm tra trạng thái
SELECT TOP 10 * FROM vw_SeatStatus WHERE [Status] IN (0, 1);
GO

PRINT '✓ Database CinemaDB đã sẵn sàng cho testing!';
