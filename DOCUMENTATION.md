CINEMA CONCURRENCY & TRANSACTION DEMONSTRATION
================================================

Đây là một dự án toàn diện để học tập và kiểm thử:
1. Concurrency Control (Kiểm soát Tương tranh)
2. Transaction Management (Quản lý Giao dịch)
3. Lock Mechanisms (Cơ chế Khóa)

---

## PHẦN 1: DATA DICTIONARY (Từ ĐIỂN DỮ LIỆU)

### Bảng: Users (Người Dùng)
| Cột | Kiểu Dữ Liệu | Nullable | Mô Tả |
|-----|--------------|----------|-------|
| UserID | INT | NO | Mã người dùng (Primary Key, IDENTITY) |
| UserName | NVARCHAR(100) | NO | Tên người dùng |
| Email | NVARCHAR(100) | YES | Email liên hệ |
| CreatedAt | DATETIME | NO | Thời gian tạo (DEFAULT GETDATE()) |

**Ý Nghĩa**: Bảng lưu trữ thông tin người dùng hệ thống (Khách hàng).

---

### Bảng: ShowTimes (Suất Chiếu)
| Cột | Kiểu Dữ Liệu | Nullable | Mô Tả |
|-----|--------------|----------|-------|
| ShowTimeID | INT | NO | Mã suất chiếu (Primary Key, IDENTITY) |
| MovieName | NVARCHAR(200) | NO | Tên phim |
| StartTime | DATETIME | NO | Giờ bắt đầu |
| EndTime | DATETIME | NO | Giờ kết thúc |
| CreatedAt | DATETIME | NO | Thời gian tạo (DEFAULT GETDATE()) |

**Ý Nghĩa**: Bảng quản lý các suất chiếu phim (lịch chiếu).

---

### Bảng: Seats (Ghế Ngồi)
| Cột | Kiểu Dữ Liệu | Nullable | Mô Tả |
|-----|--------------|----------|-------|
| SeatID | INT | NO | Mã ghế (Primary Key, IDENTITY) |
| ShowTimeID | INT | NO | Mã suất chiếu (Foreign Key) |
| SeatName | NVARCHAR(10) | NO | Tên ghế (ví dụ: "A1", "B5") |
| Status | INT | NO | Trạng thái ghế (0=Trống, 1=Đang giữ, 2=Đã bán) |
| UserIDHeld | INT | YES | Mã người đang giữ ghế (Foreign Key) |
| CreatedAt | DATETIME | NO | Thời gian tạo (DEFAULT GETDATE()) |

**Ý Nghĩa**: Bảng quản lý ghế ngồi. Status là cột **QUAN TRỌNG** để demo Concurrency:
- 0: Trống - Có thể được giữ
- 1: Đang giữ - Người dùng đã lock ghế, đang chuẩn bị thanh toán
- 2: Đã bán - Giao dịch hoàn tất

---

### Bảng: Payments (Thanh Toán)
| Cột | Kiểu Dữ Liệu | Nullable | Mô Tả |
|-----|--------------|----------|-------|
| PaymentID | INT | NO | Mã thanh toán (Primary Key, IDENTITY) |
| SeatID | INT | NO | Mã ghế (Foreign Key) |
| UserID | INT | NO | Mã người thanh toán (Foreign Key) |
| Amount | DECIMAL(10,2) | YES | Số tiền (VND) |
| PaymentStatus | INT | NO | Trạng thái (0=Pending, 1=Success, 2=Failed) |
| CreatedAt | DATETIME | NO | Thời gian ghi nhận (DEFAULT GETDATE()) |

**Ý Nghĩa**: Ghi lại các giao dịch thanh toán. Được sử dụng trong Procedure sp_Payment.

---

## PHẦN 2: GIẢI THÍCH THUẬT TOÁN

### 2.1: Stored Procedure sp_HoldSeat_Demo
**Mục đích**: Demo cơ chế giữ ghế với 2 kịch bản (Unsafe vs Safe).

#### Nhánh 1: IsSafeMode = 0 (CÓ CHỦ ĐÍCH GÂY LOST UPDATE)
```
Bước 1: Đọc Status của ghế (không Lock)
        ⚠️ LỖI: Không sử dụng WITH (UPDLOCK, NOWAIT)
        
Bước 2: Kiểm tra xem Status == 0 (trống)?
        Nếu không → Ném lỗi
        
Bước 3: WAITFOR DELAY '00:00:05'
        ⚠️ ĐÂY LÀ ĐIỂM RACE CONDITION!
        
        Tại thời điểm này:
        - Transaction 1 (Khách A) đã đọc Status=0 ✓
        - Transaction 2 (Khách B) cũng đọc Status=0 ✓ (cùng lúc!)
        - Cả 2 đều nghĩ "Tôi là người đầu tiên"
        
Bước 4: UPDATE Status = 1
        Ai Update CUỐI CÙNG sẽ thắng!
        Người kia sẽ bị ERROR khi thanh toán
```

**Hình ảnh Lost Update**:
```
Thời gian  | Transaction A (Khách A)    | Transaction B (Khách B)
-----------|---------------------------|------------------------
00:00:00   | SELECT Status (= 0) ✓     |
00:00:01   | WAITFOR DELAY...           | SELECT Status (= 0) ✓
00:00:02   |                            | WAITFOR DELAY...
00:00:05   | UPDATE Status = 1          |
00:00:06   | COMMIT A✓ (A owns seat)    |
00:00:06   |                            | UPDATE Status = 1
00:00:07   |                            | COMMIT B✓ (B owns seat!)
           | ❌ LOST UPDATE DETECTED!   |
```

#### Nhánh 2: IsSafeMode = 1 (PESSIMISTIC LOCK)
```
Bước 1: SELECT Status WITH (UPDLOCK, NOWAIT)
        ✓ UPDLOCK: Khóa ghế để chuẩn bị UPDATE
        ✓ NOWAIT: Nếu đã bị lock, ngay lập tức ném lỗi (Error 1222)
                  thay vì chờ
        
Bước 2: Nếu bị LOCK (Error 1222):
        THROW 50002: "Ghế đang được giao dịch bởi người khác!"
        ❌ Người kia không thể vào
        
Bước 3: Kiểm tra xem Status == 0 (trống)?
        
Bước 4: WAITFOR DELAY '00:00:05'
        ✓ LOCK ĐÃ GIỮ CHẶT
        Transaction khác sẽ bị CHẶN hoặc ERROR
        
Bước 5: UPDATE Status = 1 (SAFE)
        ✓ Chỉ TRANSACTION này mới có quyền update
```

**Hình ảnh Pessimistic Lock**:
```
Thời gian  | Transaction A (Khách A)    | Transaction B (Khách B)
-----------|---------------------------|------------------------
00:00:00   | SELECT WITH (UPDLOCK)  ✓  |
           | Lock đã được nắm giữ       |
00:00:01   |                            | SELECT WITH (UPDLOCK)
           |                            | ❌ LOCK TIMEOUT (Error 1222)
00:00:02   |                            | ❌ Exception ném
           |                            | ❌ Khách B bị từ chối
00:00:05   | WAITFOR DELAY hoàn tất    |
00:00:06   | UPDATE Status = 1 ✓       |
00:00:07   | COMMIT ✓ (Thành công)     |
           | ✓ BẢO VỆ TOÀN VẸN       |
```

---

### 2.2: Stored Procedure sp_Payment
**Mục đích**: Demo Transaction Rollback.

```sql
BEGIN TRAN
    |
    ├─ Bước 1: Kiểm tra ghế Status = 1 (Đang giữ)
    |
    ├─ Bước 2: Nếu SimulateError = 1
    |          THROW 50005 (Lỗi giả lập)
    |          → SQL Server tự động ROLLBACK
    |
    ├─ Bước 3: UPDATE Seats Status = 2 (Đã bán)
    |
    ├─ Bước 4: INSERT vào Payments
    |
    └─ COMMIT (Nếu không có lỗi)
      hoặc
      ROLLBACK (Nếu bị lỗi)
```

**Ví dụ kịch bản Rollback**:
```
Bước      | Trạng Thái Ghế       | Bảng Payments
----------|---------------------|---------------
Trước TRAN| Status = 1          | (trống)
          |                      |
Sau COMMIT| Status = 1 (Rollback| (trống)
(Error)   |  vì lỗi!)           | (không ghi)
          |                      |
Kết quả   | ✓ Ghế vẫn giữ được  | ✓ Không có bản ghi
          | ✓ An toàn, có thể   | ✓ Nguyên tắc ACID
          |   giữ lại hoặc...   |   được bảo vệ
```

---

### 2.3: Lock Strategy Comparison

| Yếu Tố | UNSAFE (IsSafeMode=0) | SAFE (IsSafeMode=1) |
|--------|----------------------|-------------------|
| Lock | Không | UPDLOCK + NOWAIT |
| Lost Update Risk | ⚠️ CÓ | ✓ KHÔNG |
| Khi bị tranh chấp | Transaction cuối thắng | Transaction sớm thắng + kẻ khác bị reject |
| Error Code | Không có | 1222 (Lock Timeout) |
| Kịch bản thực tế | ❌ Không dùng | ✓ Nên dùng trong production |

---

### 2.4: Transaction ACID Properties

**ACID** = Atomicity, Consistency, Isolation, Durability

Trong `sp_Payment`:

```
Atomicity (Tính Nguyên Tử):
  - Tất cả hoặc không gì
  - Nếu INSERT Payments fail → UPDATE Seats cũng rollback
  - Không bao giờ có "nửa vẹn" trạng thái

Consistency (Tính Nhất Quán):
  - Status bao giờ cũng = 0, 1, hoặc 2 (không bao giờ lỏng lẻo)
  - UserID luôn khớp giữa Seats.UserIDHeld và Payments.UserID

Isolation (Tính Cô Lập):
  - Transaction A không thấy UPDATE chưa commit của B
  - Mỗi Transaction hoạt động như là "riêng"

Durability (Tính Bền Vững):
  - Sau COMMIT, dữ liệu lưu vĩnh viễn vào ổ cứng
  - Ngay cả nếu server crash, dữ liệu vẫn an toàn
```

---

## PHẦN 3: HƯỚNG DẪN CHẠY TEST

### Test 1: Lost Update (Unsafe Mode)
```
1. Mở SSMS (SQL Server Management Studio)
2. Tab 1: Chạy script trong test-scripts.sql phần "TAB 1: KHÁCH A (UNSAFE MODE)"
3. Tab 2: VỪA LÚC Tab 1 chạy WAITFOR (khoảng giây 1-4), 
           chạy script "TAB 2: KHÁCH B (UNSAFE MODE)"
4. Kết quả: Cả 2 tab hoàn tất, nhưng ghế chỉ được "giữ" bởi người cuối cùng
            → LOST UPDATE!
```

### Test 2: Pessimistic Lock (Safe Mode)
```
1. Tab 1: Chạy script "TAB 1: KHÁCH A (SAFE MODE)"
2. Tab 2: VỪA LÚC Tab 1 đang WAITFOR, 
           chạy script "TAB 2: KHÁCH B (SAFE MODE)"
3. Kết quả: Tab 2 sẽ bị CHẶN hoặc nhận lỗi 1222
            → BẢO VỆ THÀNH CÔNG!
```

### Test 3: Transaction Rollback
```
1. Chạy script "Test 3B: Payment thất bại"
2. Quan sát:
   - Ghế vẫn Status = 1 (Đang giữ)
   - Bảng Payments không có bản ghi mới
   → ROLLBACK THÀNH CÔNG!
```

---

## PHẦN 4: INDEX OPTIMIZATION

```sql
CREATE NONCLUSTERED INDEX IX_Seats_Status 
ON Seats([Status])
INCLUDE (SeatID, UserIDHeld);
```

**Tác dụng**:
- Khi query: `SELECT * FROM Seats WHERE Status = 0`
- SQL Server không cần scan toàn bộ bảng
- Chỉ cần tìm trong Index (nhanh hơn 10-100 lần)

**So sánh**:
```
Không Index (Table Scan):
  1 triệu rows → Phải kiểm tra tất cả → 100+ ms

Với Index (Index Seek):
  1 triệu rows → Chỉ kiểm tra Status=0 → 5-10 ms
```

---

## PHẦN 5: SETUP & CÁCH CHẠY

### Bước 1: Tạo Database
```bash
1. Mở SQL Server Management Studio
2. Chạy file: database.sql
3. Verify: Xem có CinemaDB + các bảng không?
```

### Bước 2: Seed Data (Optional)
```bash
1. Chạy file: seed-data.sql
2. Sẽ tạo 1 triệu rows để test Index performance
3. Mất khoảng 2-5 phút (tùy máy)
```

### Bước 3: Chạy Node.js Server
```bash
1. Mở Command Prompt / PowerShell
2. CD đến thư mục dự án
3. npm install
4. npm start
5. Server chạy ở http://localhost:3000
```

### Bước 4: Mở Frontend
```bash
1. Mở trình duyệt
2. Vào http://localhost:3000/frontend/index.html
3. (Hoặc setup simple HTTP server để serve frontend)
```

### Bước 5: Test Concurrency
```bash
1. Mở 2 tab frontend
2. Tab 1: Khách A
3. Tab 2: Khách B
4. Cùng lúc click vào 1 ghế, bật/tắt checkbox "SafeMode"
5. Quan sát Console Log
```

---

## CẤU TRÚC DỰ ÁN

```
cinema-concurrency-backend/
├── database.sql              # Tạo DB + Procedures
├── test-scripts.sql          # Test scripts (2 tabs)
├── seed-data.sql             # Tạo 1 triệu dòng
├── server.js                 # Express Server + API
├── package.json              # Dependencies
├── README.md                 # File này
└── frontend/
    └── index.html            # Giao diện Admin Kiosk
```

---

## LƯU Ý AN TOÀN

- ⚠️ **UNSAFE mode** chỉ để demo + học tập. TUYỆT ĐỐI KHÔNG DÙNG production!
- ✓ **SAFE mode** (UPDLOCK) là tiêu chuẩn ngành cho tình huống này
- Đảm bảo SQL Server có cấu hình MSDTC (Distributed Transaction Coordinator) nếu dùng xuyên suốt
- Luôn đặt timeout trên Connection Pool để tránh "deadlock" vô tận

---

**Tác giả**: Sinh viên HQTCSDL  
**Ngày**: 2026-05-05  
**Mục đích**: Học tập Concurrency Control & Transaction Management
