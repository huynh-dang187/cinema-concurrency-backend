# 🎬 CINEMA CONCURRENCY & TRANSACTION DEMO

## 📌 Giới Thiệu
Đây là **hệ thống quản lý đặt vé rạp chiếu phim** tập trung vào:
- ✓ **Concurrency Control** (Kiểm soát tương tranh)
- ✓ **Transaction Management** (Quản lý giao dịch)
- ✓ **Lock Mechanisms** (Cơ chế khóa)

Dự án có 3 phần:
1. **SQL Server Backend** - Database + Stored Procedures
2. **Node.js Server** - Express API
3. **Frontend** - Admin Kiosk (HTML + CSS + Vanilla JS)

---

## 🚀 QUICK START

### Yêu cầu
- SQL Server 2019+
- Node.js 14+
- npm hoặc yarn

### Bước 1: Tạo Database

```bash
# Mở SQL Server Management Studio (SSMS)
# File > Open > database.sql
# Chạy (F5)
```

**Kết quả**: CinemaDB được tạo với:
- 4 bảng: Users, ShowTimes, Seats, Payments
- 2 Procedures: sp_HoldSeat_Demo, sp_Payment
- 2 Index để tối ưu tốc độ

### Bước 2: Cài đặt Dependencies

```bash
cd cinema-concurrency-backend
npm install
```

### Bước 3: Cấu hình SQL Server Connection

Tạo file `.env` tại thư mục gốc dự án (cùng cấp `server.js`):

```env
SQL_SERVER=localhost
SQL_DATABASE=CinemaDB
SQL_USER=sa
SQL_PASSWORD=YourPassword123
PORT=3000
```

Lưu ý: Không commit `.env` lên git.

### Bước 4: Khởi động Server

```bash
npm start
# Output:
# [SUCCESS] Server chạy trên http://localhost:3000
# [INFO] Sẵn sàng nhận request!
```

### Bước 5: Mở Frontend

```bash
# Cách 1: Trực tiếp mở file
file:///d:/Nam_3/Hệ Quản Trị CSDL/Demo_TL/cinema-concurrency-backend/frontend/index.html

# Cách 2: Dùng Python Simple Server
python -m http.server 8000 -d frontend
# Rồi truy cập http://localhost:8000/
```

Ghi chú realtime:
- Frontend mặc định có polling 5s để fallback.
- Khi backend chạy, frontend sẽ tự bật realtime bằng Socket.IO và tắt polling.

---

## 🧪 HƯỚNG DẪN TEST

### Test 1: Lost Update (Unsafe Mode)

**Mục đích**: Chứng minh lỗi Lost Update khi không dùng Lock.

**Các bước**:

1. Mở **2 cửa sổ SSMS** (hoặc 2 tab Query)
2. **Tab 1** - Chạy:
```sql
USE CinemaDB;
UPDATE Seats SET [Status] = 0, UserIDHeld = NULL WHERE SeatID = 5;
GO
EXEC sp_HoldSeat_Demo @SeatID = 5, @UserID = 1, @IsSafeMode = 0;
```

3. **Tab 2** - VỪA LÚC Tab 1 đang WAITFOR (giây 1-4), chạy:
```sql
USE CinemaDB;
EXEC sp_HoldSeat_Demo @SeatID = 5, @UserID = 2, @IsSafeMode = 0;
```

4. **Kết quả**: 
   - ✗ Cả 2 Tab đều "thành công"
   - ✗ Nhưng ghế 5 chỉ thuộc về người update CUỐI CÙNG
   - ✗ Người kia sẽ bị lỗi khi thanh toán

---

### Test 2: Pessimistic Lock (Safe Mode)

**Mục đích**: Chứng minh Lock bảo vệ khỏi Lost Update.

**Các bước**:

1. **Tab 1** - Chạy:
```sql
USE CinemaDB;
UPDATE Seats SET [Status] = 0, UserIDHeld = NULL WHERE SeatID = 10;
GO
EXEC sp_HoldSeat_Demo @SeatID = 10, @UserID = 1, @IsSafeMode = 1;
```

2. **Tab 2** - VỪA LÚC Tab 1 giữ Lock, chạy:
```sql
USE CinemaDB;
BEGIN TRY
    EXEC sp_HoldSeat_Demo @SeatID = 10, @UserID = 2, @IsSafeMode = 1;
END TRY
BEGIN CATCH
    PRINT 'ERROR: ' + ERROR_MESSAGE();
END CATCH
```

3. **Kết quả**:
   - ✓ Tab 1 hoàn tất (giữ được ghế)
   - ✓ Tab 2 bị từ chối (nhận lỗi 1222 Lock Timeout)
   - ✓ **BẢO VỆ THÀNH CÔNG!**

---

### Test 3: Transaction Rollback

**Mục đích**: Chứng minh ACID - Rollback tự động khi lỗi.

**Các bước**:

1. Tạo một ghế ở trạng thái "Đang giữ":
```sql
USE CinemaDB;
UPDATE Seats SET [Status] = 0, UserIDHeld = NULL WHERE SeatID = 20;
GO
EXEC sp_HoldSeat_Demo @SeatID = 20, @UserID = 1, @IsSafeMode = 1;
```

2. Cố tình thanh toán với lỗi:
```sql
BEGIN TRY
    EXEC sp_Payment @SeatID = 20, @UserID = 1, @SimulateError = 1;
END TRY
BEGIN CATCH
    PRINT 'PAYMENT FAILED: ' + ERROR_MESSAGE();
END CATCH
GO

-- Kiểm tra trạng thái
SELECT SeatID, [Status], UserIDHeld FROM Seats WHERE SeatID = 20;
SELECT * FROM Payments WHERE SeatID = 20;
```

3. **Kết quả**:
   - ✓ Ghế vẫn Status = 1 (Đang giữ) - không bị update
   - ✓ Bảng Payments không có bản ghi mới
   - ✓ **ROLLBACK THÀNH CÔNG!**

---

## 📊 FRONTEND USAGE

### Bảng Điều Khiển

| Tên | Mô Tả |
|-----|-------|
| **Bật UPDLOCK** | Checkbox bật/tắt SafeMode |
| **Giả lập lỗi Thanh Toán** | Checkbox để test Rollback |
| **Vai Trò** | Chọn "Khách A" hay "Khách B" |

### Lưới Ghế

- **⚪ Trắng** = Trống (có thể click)
- **🟡 Vàng** = Đang giữ (bị khóa)
- **⚫ Xám** = Đã bán (bán hết)
- **🟢 Xanh** = Ghế tôi vừa chọn

### Nút Hành Động

- **Giữ Ghế** = POST /api/hold (gọi sp_HoldSeat_Demo)
- **Thanh Toán** = POST /api/payment (gọi sp_Payment)
- **Làm Mới** = Reset lựa chọn hiện tại

### Nhật Ký Hành Động

Textarea phía dưới in ra tất cả sự kiện:
```
[10:23:45] 📋 Tải danh sách ghế từ server...
[10:23:46] ✓ Tải thành công 64 ghế
[10:23:47] 📋 Đã chọn ghế: A1 (ID: 1)
[10:23:48] 🔄 Đang gọi API /api/hold... (SafeMode: true)
[10:23:53] ✓ Ghế A1 được giữ thành công!
```

---

## 🔄 API ENDPOINTS

### GET /api/seats
Lấy danh sách tất cả ghế.

**Response**:
```json
[
  {
    "SeatID": 1,
    "SeatName": "A1",
    "Status": 0,
    "UserIDHeld": null,
    "UserName": null,
    "MovieName": "Phim Hành Động 1",
    "ShowTimeID": 1
  },
  ...
]
```

### POST /api/hold
Gọi Stored Procedure sp_HoldSeat_Demo để giữ ghế.

**Request**:
```json
{
  "seatId": 5,
  "userId": 1,
  "isSafeMode": true
}
```

**Response (Success 200)**:
```json
{
  "success": true,
  "message": "Ghế được giữ thành công!",
  "seatId": 5,
  "userId": 1
}
```

**Response (Error 400)** - Nếu bị Lock:
```json
{
  "error": "Ghế đang có người giao dịch",
  "message": "Vui lòng chọn ghế khác!",
  "seatId": 5,
  "errorCode": 1222
}
```

### POST /api/payment
Gọi Stored Procedure sp_Payment để hoàn tất thanh toán.

**Request**:
```json
{
  "seatId": 5,
  "userId": 1,
  "simulateError": false
}
```

**Response (Success 200)**:
```json
{
  "success": true,
  "message": "Thanh toán thành công!",
  "seatId": 5,
  "userId": 1,
  "amount": 150000
}
```

**Response (Error 400)** - Nếu Transaction Rollback:
```json
{
  "error": "Thanh toán thất bại",
  "message": "Lỗi giả lập: Kết nối mạng bị gián đoạn!",
  "seatId": 5,
  "errorCode": 50005
}
```

---

## 📚 LÝ THUYẾT

### Lost Update (Mất cập nhật)

```
T1: SELECT Status (=0)
                        T2: SELECT Status (=0)
T1: WAITFOR 5s
                        T2: WAITFOR 5s
T1: UPDATE Status=1
                        T2: UPDATE Status=1
T1: COMMIT (Khách A)
                        T2: COMMIT (Khách B)

❌ Kết quả: Cả 2 nghĩ "Tôi giữ được ghế"
           Nhưng chỉ T2 thực sự nắm giữ!
           T1 bị Lost Update!
```

### Pessimistic Lock

```
T1: SELECT WITH (UPDLOCK, NOWAIT) - LOCK tại đây ✓
T1: Status = 0 ✓
                        T2: SELECT WITH (UPDLOCK, NOWAIT)
                        ❌ ERROR 1222 (Lock Timeout)
                        ❌ T2 bị từ chối ngay lập tức
T1: WAITFOR 5s (giữ Lock)
T1: UPDATE Status=1
T1: COMMIT ✓

✓ Kết quả: Chỉ T1 nắm được
          T2 bị từ chối từ đầu
          NO LOST UPDATE!
```

### Transaction ROLLBACK

```
BEGIN TRAN
  ├─ UPDATE Seats Status=2
  ├─ INSERT Payments
  └─ Nếu lỗi ở bước nào đó:
     ROLLBACK TỰ ĐỘNG
     → Trở lại trạng thái ban đầu
     
ACID đảm bảo:
✓ Atomicity: Tất cả hoặc không gì
✓ Consistency: Dữ liệu luôn hợp lệ
✓ Isolation: Transaction độc lập
✓ Durability: Dữ liệu bền vững
```

---

## 🎯 CẤU TRÚC FOLDER

```
cinema-concurrency-backend/
│
├── 📄 database.sql
│   └─ Tạo DB, bảng, procedures, index
│
├── 📄 test-scripts.sql
│   └─ Test scripts cho 2 tab (copy-paste)
│
├── 📄 seed-data.sql
│   └─ Tạo 1 triệu rows để test Index performance
│
├── 📄 server.js
│   └─ Express Server + API endpoints
│
├── 📄 package.json
│   └─ Dependencies: express, cors, mssql
│
├── 📄 DOCUMENTATION.md
│   └─ Tài liệu kỹ thuật (Data Dictionary, Algorithms)
│
├── 📄 README.md
│   └─ File này
│
└── 📁 frontend/
    └── 📄 index.html
        └─ Admin Kiosk UI (Bootstrap 5 + Vanilla JS)
```

---

## ⚠️ NOTES & TROUBLESHOOTING

### Lỗi: "Connection to database failed"

```
Nguyên nhân: Thông tin SQL Server sai
Giải pháp:
1. Kiểm tra server name: (local), localhost, hoặc COMPUTER\SQLEXPRESS
2. Kiểm tra username/password
3. Kiểm tra tên database là CinemaDB
4. Mở SQL Server Configuration Manager → Services → Check SQL Server (MSSQLSERVER) đang chạy
```

### Lỗi: "CORS policy blocked"

```
Nguyên nhân: Frontend và Backend ở domain khác
Giải pháp:
1. Kiểm tra server.js có app.use(cors()) không
2. Kiểm tra origin trong CORS config
3. Frontend phải ở http://localhost:3000 (hoặc cấu hình CORS cho domain khác)
```

### Lỗi: "Transaction (Process ID ...) was deadlocked"

```
Nguyên nhân: 2 Transaction lock nhau (circular)
Giải pháp:
1. Tránh lock nhiều bảng cùng lúc
2. Dùng NOWAIT thay vì chờ vô hạn
3. Đặt timeout trên Connection Pool
```

---

## 📖 TÀI LIỆU THAM KHẢO

- **SQL Server Locks**: https://learn.microsoft.com/sql/relational-databases/locks
- **ACID Transactions**: https://en.wikipedia.org/wiki/ACID
- **Concurrency Control**: https://learn.microsoft.com/sql/relational-databases/sql-server-transaction-locking-and-row-versioning-guide

---

## 👨‍💻 TÁC GIẢ

Sinh viên môn **Hệ Quản Trị Cơ Sở Dữ Liệu**  
Ngày: 2026-05-05

---

## 📝 GHI CHÚ

Dự án này chỉ để **học tập & kiểm thử**. Không dùng trong production mà không có thay đổi:
- ✗ Chế độ UNSAFE chỉ demo - TUYỆT ĐỐI cấm dùng thực tế
- ✓ SAFE mode (UPDLOCK) là tiêu chuẩn - nên dùng
- ⚠️ Cần thêm error handling, logging, monitoring trước production

---

**Happy Learning! 🚀**