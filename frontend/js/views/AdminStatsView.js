/**
 * AdminStatsView.js
 * Màn hình 8: Admin xem doanh thu & Thống kê (Database Indexing Demo)
 * Showcase hiệu năng của database indexing khi truy vấn lượng lớn dữ liệu
 */

class AdminStatsView {
  constructor() {
    this.container = document.getElementById('app');
  }

  async render() {
    try {
      // Fetch stats from backend (demonstrating indexed queries)
      const stats = await fetch(`${API_BASE_URL}/admin/stats`).then(r => r.json());

      this.container.innerHTML = `
        <div class="admin-stats">
          <h1>Thống kê doanh thu</h1>
          
          <div class="stats-grid">
            <div class="stat-card">
              <h3>Tổng doanh thu</h3>
              <p class="stat-value">${stats.totalRevenue.toLocaleString('vi-VN')} đ</p>
            </div>
            <div class="stat-card">
              <h3>Tổng vé bán</h3>
              <p class="stat-value">${stats.totalTickets}</p>
            </div>
            <div class="stat-card">
              <h3>Phim bán chạy</h3>
              <p class="stat-value">${stats.topMovie}</p>
            </div>
          </div>

          <div class="detailed-stats">
            <h2>Doanh thu theo ngày</h2>
            <table>
              <thead>
                <tr>
                  <th>Ngày</th>
                  <th>Doanh thu</th>
                  <th>Vé bán</th>
                </tr>
              </thead>
              <tbody>
                ${stats.dailyRevenue.map(day => `
                  <tr>
                    <td>${day.date}</td>
                    <td>${day.revenue.toLocaleString('vi-VN')} đ</td>
                    <td>${day.tickets}</td>
                  </tr>
                `).join('')}
              </tbody>
            </table>
          </div>
        </div>
      `;
    } catch (error) {
      console.error('Error loading stats:', error);
    }
  }
}
