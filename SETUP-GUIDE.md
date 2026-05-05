HƯỚNG DẪN SETUP CHI TIẾT (STEP-BY-STEP)
======================================

Đọc file này nếu bạn là lần đầu tiên setup dự án!

---

## PREREQUISITE: Cài đặt Phần Mềm

### 1. SQL Server

**Windows**:
1. Download SQL Server Express 2022: https://www.microsoft.com/sql-server/sql-server-downloads
2. Chọn "Express" (free)
3. Chạy installer
4. Chọn "Basic Installation"
5. Đợi hoàn tất

**Kiểm tra**:
- Mở SQL Server Management Studio (SSMS)
- Connect đến: `(local)` hoặc `localhost`
- Username: `sa`
- Password: Lấy từ quá trình cài đặt

### 2. Node.js

1. Download: https://nodejs.org (LTS version)
2. Chạy installer
3. Chọn "Add to PATH"
4. Chạy `node -v` trong Terminal để kiểm tra

### 3. Git (Optional - để clone dự án)

1. Download: https://git-scm.com
2. Chạy installer
3. Chấp nhận mặc định

---

## BƯỚC 1: Lấy Code

### Cách A: Clone từ Git (nếu có git)

```bash
cd d:\Nam_3\Hệ Quản Trị CSDL\Demo_TL
git clone <repo-url>
cd cinema-concurrency-backend
```

### Cách B: Copy folder (nếu không có git)

Chỉ cần copy toàn bộ folder `cinema-concurrency-backend` đến máy của bạn.

---

## BƯỚC 2: Tạo Database

### Mở SQL Server Management Studio

1. Tìm kiếm "SQL Server Management Studio" trong Start
2. Chạy
3. Connect tới:
   - Server: `localhost` (hoặc `(local)`)
   - Authentication: SQL Server Authentication
   - Login: `sa`
   - Password: (nhập password bạn đặt)
   - Click "Connect"

### Chạy Script database.sql

1. Mở File > Open > File
2. Chọn `database.sql` trong folder dự án
3. Nhấn Ctrl+A để chọn toàn bộ
4. Nhấn F5 (hoặc Click Execute)
5. Chờ kết quả

**Kết quả mong đợi**:
```
✓ Database CinemaDB được tạo thành công!
✓ Dữ liệu mẫu được thêm thành công!
✓ Procedure sp_HoldSeat_Demo được tạo thành công!
✓ Procedure sp_Payment được tạo thành công!
✓ Index được tạo thành công!
```

---

## BƯỚC 3: Kiểm tra Database

Trong SSMS, gõ câu lệnh:

```sql
USE CinemaDB;
SELECT COUNT(*) as TotalSeats FROM Seats;
SELECT COUNT(*) as TotalUsers FROM Users;
```

**Kết quả**: 
- TotalSeats = 64
- TotalUsers = 3

---

## BƯỚC 4: Cấu hình Backend (Node.js)

### Mở file server.js

Dùng VS Code hoặc editor yêu thích:

```bash
# Mở VS Code
code server.js
```

### Tìm dòng sqlConfig

```javascript
const sqlConfig = {
    server: 'localhost',
    database: 'CinemaDB',
    authentication: {
        type: 'default',
        options: {
            userName: 'sa',              // ← ĐỔI NẾU CẦN
            password: 'YourPassword123'  // ← ĐỔI NẾU CẦN
        }
    },
    ...
};
```

**Thay đổi**:
- `server`: Đổi thành server name của bạn (nếu không phải localhost)
- `userName`: Username SQL Server (thường là `sa`)
- `password`: Password bạn đặt khi cài SQL Server

### Save file (Ctrl+S)

---

## BƯỚC 5: Cài Dependencies

### Mở PowerShell hoặc Command Prompt

```bash
# CD vào thư mục dự án
cd d:\Nam_3\Hệ Quản Trị CSDL\Demo_TL\cinema-concurrency-backend

# Cài dependencies
npm install

# Chờ khoảng 1-2 phút
# Sẽ thấy:
#   added XXX packages
```

---

## BƯỚC 6: Khởi động Server

### Trong cùng Terminal

```bash
npm start

# Output:
# ✓ [SUCCESS] Kết nối SQL Server thành công!
# ✓ [SUCCESS] Server chạy trên http://localhost:3000
# [INFO] Sẵn sàng nhận request!
```

**✓ Server đang chạy!**

---

## BƯỚC 7: Mở Frontend

### Cách A: Dùng Python (dễ nhất)

```bash
# Mở terminal mới (không close terminal Node.js)
cd frontend

# Python 3
python -m http.server 8000

# hoặc Python 2
python -m SimpleHTTPServer 8000

# Rồi mở trình duyệt:
# http://localhost:8000/index.html
```

### Cách B: Dùng Live Server trong VS Code

1. Cài extension "Live Server"
2. Click chuột phải trên index.html
3. Chọn "Open with Live Server"
4. Tự động mở http://localhost:5500/index.html

### Cách C: Mở file trực tiếp

```
file:///d:/Nam_3/Hệ Quản Trị CSDL/Demo_TL/cinema-concurrency-backend/frontend/index.html
```

⚠️ **LƯU Ý**: Các API sẽ không hoạt động nếu mở file:// trực tiếp (CORS issue)

---

## BƯỚC 8: TEST CỨU CÓ

### Trong Frontend

1. Giao diện Admin Kiosk tải xong
2. Console log hiện:
   ```
   ═══════════════════════════════════════════
      ADMIN CINEMA KIOSK ĐANG HOẠT ĐỘNG
   ═══════════════════════════════════════════
   Kết nối đến server: http://localhost:3000/api
   Tải danh sách ghế từ server...
   ✓ Tải thành công 64 ghế
   ```
3. Lưới ghế 8x8 hiện thị
4. Chọn 1 ghế trắng
5. Bật/tắt checkbox "Bật UPDLOCK (Pessimistic Lock)"
6. Click nút "Giữ Ghế"
7. Nếu thành công → Toast xanh
8. Click "Thanh Toán"
9. Nếu thành công → Ghế chuyển sang xám (Đã bán)

**✓ HOÀN THÀNH SETUP!**

---

## BƯỚC 9: TEST CONCURRENCY (2 TAB)

### Test Lost Update (Unsafe)

**Mục đích**: Chứng minh lỗi Lost Update

1. **Tab 1 (Khách A)**:
   - Mở: http://localhost:8000/index.html
   - Chọn role: "Tôi là Khách A"
   - TẮT checkbox "Bật UPDLOCK"
   - Chọn ghế (ví dụ A1)
   - Click "Giữ Ghế"

2. **Vừa lúc Tab 1 đang chờ (5 giây)**, mở Tab 2:
   - Mở: http://localhost:8000/index.html (tab mới)
   - Chọn role: "Tôi là Khách B"
   - TẮT checkbox "Bật UPDLOCK"
   - Chọn CÙNG ghế (A1)
   - Click "Giữ Ghế"

3. **Kết quả**:
   - ✗ Cả 2 tab đều "Ghế được giữ thành công!"
   - ✗ Nhưng chỉ Khách B thực sự giữ được
   - ✗ Khách A sẽ bị lỗi khi thanh toán
   - ❌ **LOST UPDATE REPRODUCED!**

### Test Pessimistic Lock (Safe)

**Mục đích**: Chứng minh Lock bảo vệ

1. **Tab 1 (Khách A)**:
   - Chọn role: "Tôi là Khách A"
   - BẬT checkbox "Bật UPDLOCK"
   - Chọn ghế (ví dụ B2)
   - Click "Giữ Ghế"

2. **Vừa lúc Tab 1 đang chờ (5 giây)**, mở Tab 2:
   - Chọn role: "Tôi là Khách B"
   - BẬT checkbox "Bật UPDLOCK"
   - Chọn CÙNG ghế (B2)
   - Click "Giữ Ghế"

3. **Kết quả**:
   - ✓ Tab 1 "Ghế được giữ thành công!"
   - ❌ Tab 2 nhận lỗi: "Ghế đang có người giao dịch"
   - ✓ **BẢO VỀ THÀNH CÔNG!**

---

## BƯỚC 10: TEST TRANSACTION ROLLBACK

### Test Giả lập lỗi Thanh toán

1. Giữ 1 ghế bình thường (SafeMode=ON)
2. BẬT checkbox "Giả lập lỗi Thanh Toán"
3. Click "Thanh Toán"
4. **Kết quả**:
   - ❌ Toast đỏ: "Thanh toán thất bại"
   - ✓ Ghế vẫn ở trạng thái "Đang giữ" (vàng)
   - ✓ Không có bản ghi Payment
   - ✓ **ROLLBACK THÀNH CÔNG!**

---

## TROUBLESHOOTING

### Lỗi: "Connection to database failed"

**Giải pháp**:
```bash
# 1. Kiểm tra SQL Server đang chạy
# Mở Task Manager > Services > SQL Server (MSSQLSERVER) = Running?

# 2. Kiểm tra kết nối
sqlcmd -S localhost -U sa -P YourPassword

# 3. Sửa server.js
# Đổi 'localhost' thành '(local)' hoặc '.\\SQLEXPRESS'
```

### Lỗi: "Cannot find module 'express'"

**Giải pháp**:
```bash
npm install
npm install express cors mssql
```

### Lỗi: "Port 3000 is already in use"

**Giải pháp**:
```bash
# Cách 1: Kill process chiếm port
lsof -i :3000  # macOS/Linux
netstat -ano | findstr :3000  # Windows

# Cách 2: Dùng port khác
# Sửa server.js:
const PORT = process.env.PORT || 3001;
```

### Lỗi: "CORS policy blocked"

**Giải pháp**:
- Đảm bảo server.js có:
```javascript
app.use(cors({
    origin: 'http://localhost:3000',
    credentials: true
}));
```
- Và frontend đang chạy trên http://localhost:8000 (hoặc cấu hình CORS tương ứng)

---

## HOÀN THÀNH!

Nếu đã:
✓ Cài SQL Server + SSMS
✓ Chạy database.sql
✓ Cài npm packages
✓ Khởi động server Node.js
✓ Mở frontend
✓ Test Lock & Rollback thành công

**→ Dự án đã sẵn sàng cho đồ án!**

---

## NEXT STEPS

1. **Đọc DOCUMENTATION.md** - Để hiểu lý thuyết sâu hơn
2. **Chạy test-scripts.sql** - Để test trong SSMS (2 tabs)
3. **Chạy seed-data.sql** - Để tạo 1 triệu rows (optional)
4. **Tùy chỉnh code** - Thêm logging, monitoring, error handling

---

**Chúc bạn thành công! 🚀**

Nếu gặp issue, hãy kiểm tra:
- Phần "TROUBLESHOOTING" ở trên
- Hoặc file README.md
- Hoặc DOCUMENTATION.md
