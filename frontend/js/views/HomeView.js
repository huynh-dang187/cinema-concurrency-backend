const HomeView = {
    // render: Chỉ dùng để trả về chuỗi HTML giao diện
    render: async () => {
        return `
            <div class="animate__animated animate__fadeIn">
                <h3 class="mb-4 border-start border-warning border-4 ps-2">Phim Đang Chiếu</h3>
                <div class="row g-4" id="movie-list">
                    
                    <div class="col-md-3">
                        <div class="movie-card text-center" onclick="location.hash='#/seats'">
                            <img src="https://via.placeholder.com/300x450/1a1d23/ff9d00?text=Avengers:+Endgame" class="img-fluid rounded mb-3" alt="Poster">
                            <h5 class="text-warning">Avengers: Endgame</h5>
                            <p class="text-secondary small">Hành động, Viễn tưởng</p>
                            <button class="btn btn-warning w-100 fw-bold">Mua Vé</button>
                        </div>
                    </div>
                    </div>
            </div>
        `;
    },
    
    // afterRender: Dùng để viết logic JS (nếu có) sau khi HTML đã hiện ra
    afterRender: async () => {
        console.log("Màn hình Trang chủ đã tải thành công!");
    }
};

export default HomeView;