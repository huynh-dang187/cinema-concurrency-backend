-- ============================================================================
-- SEED DATA SCRIPT: TẠO 1 TRIỆU DÒNG DỮ LIỆU TỐI ƯU HIỆU SUẤT
-- Sử dụng WHILE LOOP và BATCH PROCESSING
-- Mục đích: Test tốc độ Index
-- ============================================================================

USE CinemaDB;
GO

DECLARE @BatchSize INT = 1000;          -- Batch size: 1000 rows mỗi lần
DECLARE @TotalRows INT = 1000000;       -- Tổng cộng 1 triệu rows
DECLARE @RowCount INT = 0;
DECLARE @ShowTimeID INT;
DECLARE @Row INT = 1;
DECLARE @Col INT = 1;
DECLARE @Status INT;
DECLARE @SeatName NVARCHAR(10);
DECLARE @StartTime DATETIME = GETDATE();

-- Tạo 5 ShowTime trước
INSERT INTO ShowTimes (MovieName, StartTime, EndTime) VALUES
    (N'Phim 1', '2026-05-05 10:00:00', '2026-05-05 12:00:00'),
    (N'Phim 2', '2026-05-05 14:00:00', '2026-05-05 16:00:00'),
    (N'Phim 3', '2026-05-06 10:00:00', '2026-05-06 12:00:00'),
    (N'Phim 4', '2026-05-06 14:00:00', '2026-05-06 16:00:00'),
    (N'Phim 5', '2026-05-07 10:00:00', '2026-05-07 12:00:00');

PRINT '✓ Đã tạo 5 ShowTime';
GO

-- Bắt đầu vòng lặp
PRINT 'Đang tạo 1 triệu rows... (Batch processing)';
GO

DECLARE @RowCount INT = 0;
DECLARE @BatchSize INT = 1000;
DECLARE @TotalRows INT = 1000000;
DECLARE @StartTime DATETIME = GETDATE();

WHILE @RowCount < @TotalRows
BEGIN
    -- BEGIN TRANSACTION cho mỗi batch
    BEGIN TRAN
    
    DECLARE @I INT = 0;
    WHILE @I < @BatchSize AND @RowCount < @TotalRows
    BEGIN
        DECLARE @ShowTimeID INT = (@RowCount % 5) + 1;
        DECLARE @Row INT = (@RowCount / 8) % 8 + 1;
        DECLARE @Col INT = (@RowCount % 8) + 1;
        DECLARE @Status INT = @RowCount % 3;  -- 0, 1, hoặc 2
        DECLARE @SeatName NVARCHAR(10) = CHAR(64 + @Row) + CAST(@Col AS NVARCHAR(2));
        
        INSERT INTO Seats (ShowTimeID, SeatName, [Status])
        VALUES (@ShowTimeID, @SeatName, @Status);
        
        SET @I = @I + 1;
        SET @RowCount = @RowCount + 1;
    END
    
    -- COMMIT batch
    COMMIT TRAN
    
    -- In tiến độ mỗi 100,000 rows
    IF @RowCount % 100000 = 0
    BEGIN
        DECLARE @PercentDone INT = (@RowCount * 100) / @TotalRows;
        DECLARE @ElapsedSeconds INT = DATEDIFF(SECOND, @StartTime, GETDATE());
        PRINT 'Tiến độ: ' + CAST(@RowCount AS NVARCHAR(10)) + '/' + CAST(@TotalRows AS NVARCHAR(10)) + 
              ' (' + CAST(@PercentDone AS NVARCHAR(3)) + '%) - ' + CAST(@ElapsedSeconds AS NVARCHAR(10)) + 's';
    END
END

DECLARE @EndTime DATETIME = GETDATE();
DECLARE @TotalSeconds INT = DATEDIFF(SECOND, @StartTime, @EndTime);

PRINT '';
PRINT '╔═══════════════════════════════════════════╗';
PRINT '✓ Hoàn thành! Tạo ' + CAST(@RowCount AS NVARCHAR(10)) + ' rows';
PRINT '✓ Tổng thời gian: ' + CAST(@TotalSeconds AS NVARCHAR(10)) + ' giây';
DECLARE @RowsPerSec INT = @RowCount / NULLIF(@TotalSeconds, 0);
PRINT '✓ Tốc độ: ' + CAST(@RowsPerSec AS NVARCHAR(10)) + ' rows/giây';
PRINT '╚═══════════════════════════════════════════╝';

-- Kiểm tra kết quả
SELECT COUNT(*) AS TotalSeats FROM Seats;
SELECT ShowTimeID, COUNT(*) AS SeatCount FROM Seats GROUP BY ShowTimeID;
GO

-- Kiểm tra Index performance
PRINT '';
PRINT 'Kiểm tra hiệu suất Index:';
PRINT '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';

SET STATISTICS IO ON;
SET STATISTICS TIME ON;

-- Query 1: Tìm tất cả ghế trống
SELECT COUNT(*) FROM Seats WHERE [Status] = 0;

-- Query 2: Tìm ghế theo ShowTime
SELECT COUNT(*) FROM Seats WHERE ShowTimeID = 1 AND [Status] = 0;

SET STATISTICS IO OFF;
SET STATISTICS TIME OFF;

PRINT '✓ Kiểm tra xong - Có thể so sánh Performance!';
GO
