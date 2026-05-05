-- ============================================================================
-- TEST SCRIPTS - CONCURRENCY DEMO
-- Chạy các script này trong 2 tab khác nhau (hoặc 2 connection) để test
-- ============================================================================

-- ============================================================================
-- TEST 1: LOST UPDATE (Unsafe Mode = 0)
-- Chạy cả 2 script này ĐỒNG THỜI trong 2 tab khác nhau
-- ============================================================================

-- ============== TAB 1: KHÁCH A (UNSAFE MODE) ==============
-- Thực thi script này trong Tab 1
USE CinemaDB;
GO

PRINT '╔════════════════════════════════════════╗';
PRINT '║  TAB 1: KHÁCH A - ĐÃ BẮT ĐẦU GIỮ GHẾ  ║';
PRINT '║  Mode: UNSAFE (Lost Update Risk!)      ║';
PRINT '╚════════════════════════════════════════╝';

-- Reset ghế 5 về trạng thái trống trước
UPDATE Seats SET [Status] = 0, UserIDHeld = NULL WHERE SeatID = 5;
GO

EXEC sp_HoldSeat_Demo @SeatID = 5, @UserID = 1, @IsSafeMode = 0;

SELECT SeatID, SeatName, [Status], UserIDHeld 
FROM Seats WHERE SeatID = 5;

PRINT '✓ TAB 1 HOÀN THÀNH';
GO

-- ============== TAB 2: KHÁCH B (UNSAFE MODE) ==============
-- Chạy script này trong Tab 2 VỪA LÚC Tab 1 đang WAITFOR DELAY
-- (Chạy trước khi Tab 1 kết thúc - Cơ hội xảy ra Lost Update!)
USE CinemaDB;
GO

PRINT '╔════════════════════════════════════════╗';
PRINT '║  TAB 2: KHÁCH B - CŨNG MUỐN GIỮ GHẾ   ║';
PRINT '║  Mode: UNSAFE (Lost Update Risk!)      ║';
PRINT '╚════════════════════════════════════════╝';

EXEC sp_HoldSeat_Demo @SeatID = 5, @UserID = 2, @IsSafeMode = 0;

SELECT SeatID, SeatName, [Status], UserIDHeld 
FROM Seats WHERE SeatID = 5;

PRINT '✓ TAB 2 HOÀN THÀNH';
GO

-- ⚠️ KẾT QUẢ: Cả 2 tab đều think "Mình giữ được ghế 5"
-- Nhưng thực tế: Ai Update cuối cùng sẽ chiến thắng (UserID = 2)
-- Khách A sẽ đi thanh toán nhưng ghế không phải của mình → ERROR!

---PRINT '┌─────────────────────────────────────────┐';
PRINT 'KẾT LUẬN: Cả 2 đều vào được vì không có Lock!';
PRINT '         Update cuối cùng thắng (UserID = 2)';
PRINT '         Khách A sẽ bị lỗi khi thanh toán!';
PRINT '└─────────────────────────────────────────┘';
GO

-- ============================================================================
-- TEST 2: PESSIMISTIC LOCK (Safe Mode = 1)
-- Chạy cả 2 script này ĐỒNG THỜI trong 2 tab khác nhau
-- ============================================================================

-- ============== TAB 1: KHÁCH A (SAFE MODE) ==============
-- Thực thi script này trong Tab 1
USE CinemaDB;
GO

PRINT '╔════════════════════════════════════════╗';
PRINT '║  TAB 1: KHÁCH A - GIỮ GHẾ (SAFE MODE) ║';
PRINT '║  Mode: SAFE (Pessimistic Lock!)        ║';
PRINT '╚════════════════════════════════════════╝';

-- Reset ghế 10 về trạng thái trống trước
UPDATE Seats SET [Status] = 0, UserIDHeld = NULL WHERE SeatID = 10;
GO

EXEC sp_HoldSeat_Demo @SeatID = 10, @UserID = 1, @IsSafeMode = 1;

SELECT SeatID, SeatName, [Status], UserIDHeld 
FROM Seats WHERE SeatID = 10;

PRINT '✓ TAB 1 HOÀN THÀNH - GHẾ ĐÃ LOCK XONG!';
GO

-- ============== TAB 2: KHÁCH B (SAFE MODE) ==============
-- Chạy script này trong Tab 2 VỪA LÚC Tab 1 đang giữ Lock
-- TAB 2 SẼ BỊ CHẶN HOẶC NHẬN LỖI!
USE CinemaDB;
GO

PRINT '╔════════════════════════════════════════╗';
PRINT '║  TAB 2: KHÁCH B - CŨNG MUỐN GIỮ GHẾ   ║';
PRINT '║  Mode: SAFE (Pessimistic Lock!)        ║';
PRINT '║  ⚠️ BỊ LOCK - Phải CHỜ hoặc LỖI!      ║';
PRINT '╚════════════════════════════════════════╝';

BEGIN TRY
    EXEC sp_HoldSeat_Demo @SeatID = 10, @UserID = 2, @IsSafeMode = 1;
    
    SELECT SeatID, SeatName, [Status], UserIDHeld 
    FROM Seats WHERE SeatID = 10;
    
    PRINT '✓ TAB 2 HOÀN THÀNH';
END TRY
BEGIN CATCH
    PRINT '❌ TAB 2 NHẬN LỖI: ' + ERROR_MESSAGE();
    PRINT '   Ghế đang bị Tab 1 Lock - Không thể vào cùng lúc!';
END CATCH
GO

PRINT '┌─────────────────────────────────────────┐';
PRINT '✓ KẾT LUẬN: Lock thành công!';
PRINT '           Tab 1 Hold được ghế';
PRINT '           Tab 2 Chờ hoặc nhận lỗi';
PRINT '           BẢO VỆ an toàn!';
PRINT '└─────────────────────────────────────────┘';
GO

-- ============================================================================
-- TEST 3: TRANSACTION ROLLBACK (Payment Error Simulation)
-- ============================================================================

PRINT '╔════════════════════════════════════════╗';
PRINT '║  TEST 3: PAYMENT ROLLBACK TEST         ║';
PRINT '╚════════════════════════════════════════╝';

USE CinemaDB;
GO

-- Chuẩn bị: Hold ghế 15 trước
UPDATE Seats SET [Status] = 0, UserIDHeld = NULL WHERE SeatID = 15;
GO

EXEC sp_HoldSeat_Demo @SeatID = 15, @UserID = 1, @IsSafeMode = 1;
GO

-- Test 3A: Payment thành công
PRINT '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
PRINT 'Test 3A: Payment thành công (SimulateError = 0)';
PRINT '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';

EXEC sp_Payment @SeatID = 15, @UserID = 1, @SimulateError = 0;

-- Kiểm tra trạng thái
SELECT SeatID, SeatName, [Status], UserIDHeld FROM Seats WHERE SeatID = 15;
SELECT * FROM Payments WHERE SeatID = 15;

PRINT '✓ Ghế 15 đã chuyển sang "Đã bán" - Payment ghi thành công';
PRINT '';
GO

-- Test 3B: Payment thất bại → Rollback
PRINT '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
PRINT 'Test 3B: Payment thất bại (SimulateError = 1)';
PRINT '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';

-- Chuẩn bị: Hold ghế 20
UPDATE Seats SET [Status] = 0, UserIDHeld = NULL WHERE SeatID = 20;
GO

EXEC sp_HoldSeat_Demo @SeatID = 20, @UserID = 2, @IsSafeMode = 1;
GO

-- Chạy Payment với SimulateError = 1 (sẽ fail)
BEGIN TRY
    EXEC sp_Payment @SeatID = 20, @UserID = 2, @SimulateError = 1;
END TRY
BEGIN CATCH
    PRINT '❌ Payment failed: ' + ERROR_MESSAGE();
END CATCH
GO

-- Kiểm tra trạng thái (vẫn là "Đang giữ" chứ không phải "Đã bán")
SELECT SeatID, SeatName, [Status], UserIDHeld FROM Seats WHERE SeatID = 20;
SELECT * FROM Payments WHERE SeatID = 20;

PRINT '✓ Ghế 20 vẫn là "Đang giữ" (Status = 1) - Payment bị Rollback!';
PRINT '✓ Không có bản ghi Payment được ghi - Transaction an toàn!';
GO

-- ============================================================================
-- SUMMARY: KIỂM TRA TOÀN BỘ TRẠNG THÁI
-- ============================================================================

PRINT '';
PRINT '╔════════════════════════════════════════════════════════════╗';
PRINT '║  KIỂM TRA TOÀN BỘ TRẠNG THÁI GHẾ SAU KHI TEST             ║';
PRINT '╚════════════════════════════════════════════════════════════╝';

SELECT 
    SeatID,
    SeatName,
    CASE [Status]
        WHEN 0 THEN '⚪ Trống'
        WHEN 1 THEN '🟡 Đang giữ'
        WHEN 2 THEN '⚫ Đã bán'
    END AS StatusName,
    UserIDHeld,
    (SELECT UserName FROM Users WHERE UserID = Seats.UserIDHeld) AS UserName
FROM Seats
WHERE SeatID IN (5, 10, 15, 20)
ORDER BY SeatID;
GO
