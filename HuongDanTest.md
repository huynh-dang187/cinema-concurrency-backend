# 🎬 HƯỚNG DẪN TEST CINEMA CONCURRENCY PROJECT

**Dành cho các thành viên nhóm tự chạy & kiểm thử**

---

## 📌 YÊU CẦU TRƯỚC KHI BẮT ĐẦU

Đảm bảo bạn đã hoàn thành:
- [ ] SQL Server đã cài (Instance: `HUYNHDANG`, Password: `dangvatran187`)
- [ ] Node.js đã cài (chạy `node -v` để kiểm tra)
- [ ] Python đã cài (chạy `python --version` để kiểm tra)
- [ ] Database CinemaDB đã tạo (chạy file `database.sql`)
- [ ] npm packages đã cài (`npm install`)

---

## ⚡ QUICK START (BƯỚC 1-3)

### BƯỚC 1: Mở Terminal PowerShell (Terminal 1)

```powershell
# CD vào thư mục dự án
cd d:\Nam_3\Hệ Quản Trị CSDL\Demo_TL\cinema-concurrency-backend

# Khởi động Backend Server
npm start
```

**Nếu thấy output**:
```
✓ [SUCCESS] Kết nối SQL Server thành công!
✓ [SUCCESS] Server chạy trên http://localhost:3000
[INFO] Sẵn sàng nhận request!
```

→ ✅ **Backend đang chạy! (Đừng đóng terminal này)**

---

### BƯỚC 2: Mở Terminal PowerShell Mới (Terminal 2)

```powershell
# CD vào folder frontend
cd d:\Nam_3\Hệ Quản Trị CSDL\Demo_TL\cinema-concurrency-backend\frontend

# Khởi động Frontend Server
python -m http.server 8000
```

**Nếu thấy output**:
```
Serving HTTP on 0.0.0.0 port 8000 (http://0.0.0.0:8000/) ...
```

→ ✅ **Frontend đang chạy!**

---

### BƯỚC 3: Mở Trình Duyệt

Vào địa chỉ:
```
http://localhost:8000/index.html
```

**Nếu thấy**:
- Lưới ghế 8×8 (trắng, vàng, xám) ✅
- Bảng điều khiển (checkbox, dropdown) ✅
- Console Log phía dưới ✅
- 3 nút (Giữ Ghế, Thanh Toán, Làm Mới) ✅

→ ✅ **GIAO DIỆN HOẠT ĐỘNG!**

---

## 🧪 CÁC TEST CASE (CHỌN & CHẠY)

### ✅ TEST 1: Single User - Chọn → Giữ → Thanh Toán

**Mục đích**: Kiểm tra chức năng cơ bản

**Thời gian**: 30 giây

**Các bước**:

1. **Chọn role**: "Tôi là Khách A" ✓
2. **TẮT checkbox**: "Bật UPDLOCK" (để Unsafe Mode) ✓
3. **Click vào ghế**: Chọn ghế trắng (ví dụ: **A1**)
   - Ghế chuyển sang **xanh** ✓
4. **Click nút "Giữ Ghế"**
   - Chờ 5 giây...
   - Ghế chuyển sang **vàng** (Đang giữ) ✓
   - Console log xanh: `✓ Ghế A1 được giữ thành công!` ✓
5. **Click nút "Thanh Toán"**
   - Toast xanh: `✓ Thanh toán thành công!` ✓
   - Ghế chuyển sang **xám** (Đã bán) ✓
   - Button "Thanh Toán" disable ✓

**✅ KẾT QUẢ MONG ĐỢI**:
```
Console Log:
[HH:MM:SS] 📋 Đã chọn ghế: A1 (ID: 1)
[HH:MM:SS] 🔄 Đang gọi API /api/hold... (SafeMode: false)
[HH:MM:SS] ✓ Ghế A1 được giữ thành công!
[HH:MM:SS] 🔄 Đang gọi API /api/payment...
[HH:MM:SS] ✓ Thanh toán ghế A1 thành công!
```

---

### ❌ TEST 2: Lost Update Demo (UNSAFE MODE - 2 TAB)

**Mục đích**: Chứng minh lỗi Lost Update khi không dùng Lock

**Thời gian**: 1 phút

**Chuẩn bị**:
- [ ] Mở **2 tab** trình duyệt cùng URL: `http://localhost:8000/index.html`
- [ ] Label: **Tab A** (Khách A) và **Tab B** (Khách B)

**BƯỚC 1 - TAB A (KHÁCH A)**:

1. **Chọn role**: "Tôi là Khách A" ✓
2. **TẮT checkbox**: "Bật UPDLOCK" (Unsafe mode) ✓
3. **Chọn ghế**: **B2** (ví dụ)
   - Ghế chuyển xanh
4. **Click "Giữ Ghế"**
   - ⏳ Chờ... (đang ở giữa WAITFOR 5 giây)
   - **KHÔNG CLICK GÌ THÊM** - chuyển sang Tab B

**BƯỚC 2 - TAB B (KHÁCH B) - Chạy VỪA LÚC Tab A đang chờ**:

> ⏰ **THỜI ĐIỂM QUAN TRỌNG**: Khi Tab A vừa click "Giữ Ghế" (khoảng giây 1-4), làm như sau:

1. **Chọn role**: "Tôi là Khách B" ✓
2. **TẮT checkbox**: "Bật UPDLOCK" (Unsafe mode) ✓
3. **Chọn CÙNG ghế**: **B2** ✓
   - Ghế chuyển xanh
4. **Click "Giữ Ghế"**
   - Chờ...

**BƯỚC 3 - Sau ~10 giây, quay lại Tab A**:

- ✓ Ghế B2 chuyển **vàng** (Đang giữ)
- Console log: `✓ Ghế B2 được giữ thành công!`
- Click "Thanh Toán"
  - ❌ Toast **đỏ**: `❌ Lỗi thanh toán: Ghế không trong trạng thái 'Đang giữ'...`
  - **TẠI SAO?** → Vì Tab B đã update cuối cùng

**BƯỚC 4 - Quay sang Tab B**:

- ✓ Ghế B2 vàng (Đang giữ - của Tab B)
- Console log: `✓ Ghế B2 được giữ thành công!`
- Click "Thanh Toán"
  - ✓ Toast **xanh**: `✓ Thanh toán thành công!`
  - Ghế chuyển xám

**❌ KẾT QUẢ LOST UPDATE**:

```
┌─────────────────────────────────────────┐
│  TAB A (KHÁCH A):                       │
│  ✓ "Ghế được giữ thành công"            │
│  ❌ "Thanh toán fail: Không phải của tôi"│
│                                         │
│  TAB B (KHÁCH B):                       │
│  ✓ "Ghế được giữ thành công"            │
│  ✓ "Thanh toán thành công"              │
│  ✓ Ghế chuyển xám (Thực sự nắm được)   │
│                                         │
│  ⚠️ NHẬN XÉT:                           │
│  Cả 2 think "tôi giữ được ghế B2"      │
│  Nhưng chỉ Khách B thực sự nắm giữ     │
│  Khách A bị LOST UPDATE! ❌             │
└─────────────────────────────────────────┘
```

**📸 CONSOLE LOG CẦN CHỤP**:

```
Tab A:
[10:15:00] 📋 Đã chọn ghế: B2 (ID: 10)
[10:15:01] 🔄 Đang gọi API /api/hold... (SafeMode: false)
[10:15:06] ✓ Ghế B2 được giữ thành công!
[10:15:10] 🔄 Đang gọi API /api/payment...
[10:15:11] ❌ Lỗi thanh toán: Ghế không trong trạng thái...

Tab B:
[10:15:02] 📋 Đã chọn ghế: B2 (ID: 10)
[10:15:02] 🔄 Đang gọi API /api/hold... (SafeMode: false)
[10:15:07] ✓ Ghế B2 được giữ thành công!
[10:15:12] 🔄 Đang gọi API /api/payment...
[10:15:13] ✓ Thanh toán ghế B2 thành công!
```

---

### ✅ TEST 3: Pessimistic Lock Demo (SAFE MODE - 2 TAB)

**Mục đích**: Chứng minh Lock bảo vệ khỏi Lost Update

**Thời gian**: 1 phút

**Chuẩn bị**:
- [ ] Mở **2 tab** trình duyệt cùng URL: `http://localhost:8000/index.html`
- [ ] Label: **Tab A** (Khách A) và **Tab B** (Khách B)

**BƯỚC 1 - TAB A (KHÁCH A)**:

1. **Chọn role**: "Tôi là Khách A" ✓
2. **BẬT checkbox**: "Bật UPDLOCK" (Safe mode) ✓✓✓
3. **Chọn ghế**: **C3** (ví dụ)
   - Ghế chuyển xanh
4. **Click "Giữ Ghế"**
   - ⏳ Chờ... (Lock đã được giữ!)
   - **KHÔNG CLICK GÌ THÊM** - chuyển sang Tab B

**BƯỚC 2 - TAB B (KHÁCH B) - Chạy VỪA LÚC Tab A đang Lock**:

> ⏰ **THỜI ĐIỂM QUAN TRỌNG**: Khi Tab A vừa click "Giữ Ghế" (khoảng giây 1-4), làm như sau:

1. **Chọn role**: "Tôi là Khách B" ✓
2. **BẬT checkbox**: "Bật UPDLOCK" (Safe mode) ✓✓✓
3. **Chọn CÙNG ghế**: **C3** ✓
   - Ghế chuyển xanh
4. **Click "Giữ Ghế"**
   - ⏰ **NGAY LẬP TỨC** (không chờ 5 giây):
   - ❌ Toast **đỏ**: `❌ Ghế đang có người giao dịch`
   - ❌ Console log: `❌ Lỗi giữ ghế: Ghế đang có người giao dịch`

**BƯỚC 3 - Quay lại Tab A**:

- ⏳ Sau ~5 giây, hoàn tất
- ✓ Ghế C3 chuyển **vàng** (Đang giữ - của Tab A)
- Console log: `✓ Ghế C3 được giữ thành công!`
- Click "Thanh Toán"
  - ✓ Toast **xanh**: `✓ Thanh toán thành công!`
  - Ghế chuyển xám

**✅ KẾT QUẢ PESSIMISTIC LOCK**:

```
┌─────────────────────────────────────────┐
│  TAB A (KHÁCH A):                       │
│  ✓ "Ghế được giữ thành công"            │
│  ✓ "Thanh toán thành công"              │
│  ✓ Ghế chuyển xám (Bán thành công)      │
│                                         │
│  TAB B (KHÁCH B):                       │
│  ❌ "Ghế đang có người giao dịch"       │
│  ❌ Bị từ chối NGAY (Error 1222 Lock)   │
│                                         │
│  ✅ NHẬN XÉT:                           │
│  Lock hoạt động đúng!                   │
│  Chỉ 1 người nắm giữ                    │
│  Người kia bị reject NGAY lập tức        │
│  BẢO VỀ THÀNH CÔNG! ✅                  │
└─────────────────────────────────────────┘
```

**📸 CONSOLE LOG CẦN CHỤP**:

```
Tab A:
[10:20:00] 📋 Đã chọn ghế: C3 (ID: 19)
[10:20:01] 🔄 Đang gọi API /api/hold... (SafeMode: true)
[10:20:06] ✓ Ghế C3 được giữ thành công!
[10:20:08] 🔄 Đang gọi API /api/payment...
[10:20:09] ✓ Thanh toán ghế C3 thành công!

Tab B:
[10:20:02] 📋 Đã chọn ghế: C3 (ID: 19)
[10:20:02] 🔄 Đang gọi API /api/hold... (SafeMode: true)
[10:20:03] ❌ Lỗi giữ ghế: Ghế đang có người giao dịch
```

---

### ✅ TEST 4: Transaction Rollback (Giả Lập Lỗi)

**Mục đích**: Chứng minh ACID - Transaction tự động Rollback

**Thời gian**: 1 phút

**Các bước**:

1. **Chọn role**: "Tôi là Khách A" ✓
2. **BẬT checkbox**: "Bật UPDLOCK" (Safe mode) ✓
3. **BẬT checkbox**: "Giả lập lỗi Thanh Toán" ⚠️⚠️
4. **Chọn ghế**: **D4** (ví dụ)
   - Ghế chuyển xanh
5. **Click "Giữ Ghế"**
   - Chờ 5 giây...
   - Ghế chuyển **vàng** (Đang giữ) ✓
   - Console log: `✓ Ghế D4 được giữ thành công!`
6. **Click "Thanh Toán"** ← Cố tình lỗi!
   - ❌ Toast **đỏ**: `❌ Thanh toán thất bại: Lỗi giả lập...`
   - Console log: `❌ Lỗi thanh toán: Lỗi giả lập...`
7. **Quan sát ghế**:
   - ✓ Ghế **VẪN VÀ NG** (Đang giữ)
   - ✓ **KHÔNG** chuyển sang xám (Đã bán)
   - ✓ **KHÔNG** có bản ghi trong bảng Payments
   - → Transaction **ROLLBACK** tự động! ✓

**✅ KẾT QUẢ ROLLBACK**:

```
┌────────────────────────────────────┐
│  TRƯỚC THANH TOÁN:                 │
│  Ghế D4: Status = 1 (Đang giữ)     │
│  Payments: 0 bản ghi               │
│                                    │
│  SAU THANH TOÁN (LỖI):             │
│  Ghế D4: Status = 1 (VẪN GIỮ!) ✓  │
│  Payments: 0 bản ghi (KHÔNG GHI!) ✓│
│                                    │
│  ✅ NHẬN XÉT:                      │
│  Ghế không bị update              │
│  Payment không được ghi            │
│  ROLLBACK THÀNH CÔNG!              │
│  ACID Properties được bảo vệ!      │
└────────────────────────────────────┘
```

**📸 CONSOLE LOG CẦN CHỤP**:

```
[10:25:00] 📋 Đã chọn ghế: D4 (ID: 28)
[10:25:01] 🔄 Đang gọi API /api/hold... (SafeMode: true)
[10:25:06] ✓ Ghế D4 được giữ thành công!
[10:25:10] 🔄 Đang gọi API /api/payment... (SimulateError: true)
[10:25:11] ❌ Lỗi thanh toán: Lỗi giả lập: Kết nối mạng bị gián đoạn!
```

---

### ✅ TEST 5: Role Switching & Reset

**Mục đích**: Kiểm tra chuyển đổi user và reset state

**Thời gian**: 30 giây

**Các bước**:

1. **Chọn role**: "Tôi là Khách A"
2. **Giữ 1 ghế** bình thường (chọn ghế, click "Giữ Ghế")
   - Ghế chuyển vàng ✓
   - Button "Thanh Toán" sáng ✓

3. **Chọn role khác**: "Tôi là Khách B"
   - Console log: `📋 Đã chuyển sang: Khách B` ✓
   - Ghế **deselect** (xanh → trắng) ✓
   - Button "Thanh Toán" **disable** (tối) ✓

4. **Click "Làm Mới"**
   - Ghế deselect ✓
   - Button "Giữ Ghế" **disable** (tối) ✓
   - Console log: `📋 Đã làm mới. Chọn ghế mới để tiếp tục.` ✓

**✅ KẾT QUẢ**: State được reset đúng ✓

---

### ✅ TEST 6: Browser Refresh & Data Sync

**Mục đích**: Kiểm tra data sync từ server

**Thời gian**: 1 phút

**Các bước**:

1. **Giữ 1 ghế thành công** (ghế chuyển vàng)
   - Console log: `✓ Ghế X được giữ thành công!`

2. **Refresh page** (Ctrl + F5 hoặc F5)
   - Lưới ghế tải lại ✓
   - Console log: `✓ Tải thành công 64 ghế` ✓
   - **Ghế vẫn VÀ NG** (Sync từ server database) ✓

3. **Click "Thanh Toán"**
   - ✓ Toast xanh: `✓ Thanh toán thành công!`
   - Ghế chuyển xám ✓

**✅ KẾT QUẢ**: Data sync hoạt động đúng ✓

---

## 📋 CHECKLIST TEST TOÀN BỘ

Sau khi chạy hết tất cả test, điền vào bảng:

| Test | Mô Tả | Status | Ghi Chú |
|------|-------|--------|---------|
| 1 | Single User | ☐ Pass | Ghế trắng → vàng → xám |
| 2 | Lost Update (Unsafe) | ☐ Pass | 2 tab đều thành công, 1 bị lỗi |
| 3 | Pessimistic Lock (Safe) | ☐ Pass | Tab 2 bị từ chối (Error 1222) |
| 4 | Rollback (SimError) | ☐ Pass | Ghế vẫn vàng, không Payment |
| 5 | Role Switching | ☐ Pass | State reset đúng |
| 6 | Data Sync | ☐ Pass | Ghế vẫn vàng sau refresh |

---

## 🆘 TROUBLESHOOTING

### Nếu Backend bị lỗi kết nối SQL Server

```powershell
# Kiểm tra SQL Server đang chạy
Get-Service | Where-Object {$_.Name -like "*SQL*"}

# Nếu thấy MSSQL$HUYNHDANG là "Running" → OK
# Nếu "Stopped" → Khởi động lại:
Start-Service -Name "MSSQL$HUYNHDANG"
```

### Nếu Frontend hiện lỗi CORS

- Kiểm tra server.js có dòng:
  ```javascript
  app.use(cors({
      origin: ['http://localhost:3000', 'http://localhost:8000'],
      credentials: true
  }));
  ```
- Nếu chưa có → Thêm vào file
- Khởi động lại: `npm start`

### Nếu Port 3000 hoặc 8000 đã bị chiếm

```powershell
# Tìm process chiếm port 3000
netstat -ano | findstr :3000

# Kill process (thay PID bằng số)
taskkill /PID <PID> /F

# Thử lại npm start
npm start
```

---

## 📞 LIÊN HỆ HỖ TRỢ

Nếu gặp lỗi:
1. Kiểm tra lại các bước trong file này
2. Xem SETUP-GUIDE.md để cài đặt lại
3. Xem DOCUMENTATION.md để hiểu lý thuyết
4. Hỏi người tạo project

---

## ✅ KẾT LUẬN

Nếu đã pass hết 6 test cases:

```
✅ TEST 1: Single User
✅ TEST 2: Lost Update
✅ TEST 3: Pessimistic Lock
✅ TEST 4: Rollback
✅ TEST 5: Role Switching
✅ TEST 6: Data Sync

→ PROJECT ĐÃ HOÀN THÀNH & SẴN SÀNG DEMO! 🎉
```

---

**Chúc bạn test thành công! 👍**

Ngày: 2026-05-06
