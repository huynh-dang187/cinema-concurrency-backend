/**
 * AdminDashboard.js
 * Màn hình 7: Admin quản lý suất chiếu
 */

class AdminDashboard {
  constructor() {
    this.container = document.getElementById('app');
  }

  async render() {
    try {
      const showtimes = await APIClient.getShowtimes(null); // Get all showtimes

      this.container.innerHTML = `
        <div class="admin-dashboard">
          <h1>Quản lý suất chiếu</h1>
          <button onclick="showAddShowtimeForm()">Thêm suất chiếu</button>
          <table>
            <thead>
              <tr>
                <th>ID</th>
                <th>Phim</th>
                <th>Thời gian</th>
                <th>Phòng</th>
                <th>Tình trạng</th>
                <th>Hành động</th>
              </tr>
            </thead>
            <tbody>
              ${showtimes.map(showtime => `
                <tr>
                  <td>${showtime.id}</td>
                  <td>${showtime.movieTitle}</td>
                  <td>${showtime.time}</td>
                  <td>${showtime.room}</td>
                  <td>${showtime.status}</td>
                  <td>
                    <button onclick="editShowtime(${showtime.id})">Sửa</button>
                    <button onclick="deleteShowtime(${showtime.id})">Xóa</button>
                  </td>
                </tr>
              `).join('')}
            </tbody>
          </table>
        </div>
      `;
    } catch (error) {
      console.error('Error loading admin dashboard:', error);
    }
  }
}
