// Nạp các màn hình vào hệ thống
import HomeView from './views/HomeView.js';
// import SeatView from './views/SeatView.js'; // Tạm ẩn, bước sau sẽ mở

// Khai báo danh sách các đường dẫn (Routes)
const routes = {
    '/home': HomeView,
    // '/seats': SeatView
};

// Hàm xử lý định tuyến chính
const router = async () => {
    // Tìm khu vực chứa nội dung trên index.html
    const appContainer = document.getElementById('app-container');
    
    // Lấy phần đuôi URL (ví dụ: #/home -> /home)
    let request = location.hash.slice(1) || '/home';

    // Tìm màn hình tương ứng, nếu không thấy thì mặc định về Home
    const page = routes[request] || HomeView;

    // 1. Vẽ giao diện HTML của màn hình đó
    appContainer.innerHTML = await page.render();

    // 2. Chạy các logic phía sau (Gắn sự kiện click, gọi API...)
    if (page.afterRender) {
        await page.afterRender();
    }
};

// Lắng nghe sự kiện khi web vừa load lên hoặc khi người dùng đổi URL
window.addEventListener('hashchange', router);
window.addEventListener('load', router);