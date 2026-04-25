/**
 * TicketView.js
 * Màn hình 5: Vé điện tử thành công
 */

class TicketView {
  constructor(bookingId) {
    this.bookingId = bookingId;
    this.container = document.getElementById('app');
  }

  async render() {
    try {
      const booking = await APIClient.getBookings(this.bookingId);

      this.container.innerHTML = `
        <div class="ticket-view">
          <div class="ticket-success">
            <h1>✓ Đặt vé thành công!</h1>
            <div class="ticket">
              <p>Mã vé: ${booking.id}</p>
              <p>Phim: ${booking.movieTitle}</p>
              <p>Suất chiếu: ${booking.showtimeTime}</p>
              <p>Ghế: ${booking.seats.join(', ')}</p>
              <p>Tổng tiền: ${booking.totalPrice.toLocaleString('vi-VN')} đ</p>
            </div>
            <button onclick="router.navigate('/')">Quay lại trang chủ</button>
            <button onclick="router.navigate('/history')">Xem lịch sử</button>
          </div>
        </div>
      `;
    } catch (error) {
      console.error('Error loading ticket:', error);
    }
  }
}
