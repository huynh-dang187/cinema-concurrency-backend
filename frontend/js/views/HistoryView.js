/**
 * HistoryView.js
 * Màn hình 6: Lịch sử đặt vé
 */

class HistoryView {
  constructor(userId) {
    this.userId = userId;
    this.container = document.getElementById('app');
  }

  async render() {
    try {
      const history = await APIClient.getBookingHistory(this.userId);

      this.container.innerHTML = `
        <div class="history-view">
          <h1>Lịch sử đặt vé</h1>
          <table>
            <thead>
              <tr>
                <th>Mã vé</th>
                <th>Phim</th>
                <th>Ngày</th>
                <th>Ghế</th>
                <th>Giá</th>
              </tr>
            </thead>
            <tbody>
              ${history.map(booking => `
                <tr>
                  <td>${booking.id}</td>
                  <td>${booking.movieTitle}</td>
                  <td>${booking.date}</td>
                  <td>${booking.seats.join(', ')}</td>
                  <td>${booking.totalPrice.toLocaleString('vi-VN')} đ</td>
                </tr>
              `).join('')}
            </tbody>
          </table>
        </div>
      `;
    } catch (error) {
      console.error('Error loading booking history:', error);
    }
  }
}
