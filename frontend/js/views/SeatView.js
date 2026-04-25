/**
 * SeatView.js
 * Màn hình 3: Trọng tâm - Chọn ghế & UPDLOCK (Concurrent Update Lock)
 * Quản lý tình huống race condition khi nhiều user chọn ghế cùng lúc
 */

class SeatView {
  constructor(showtimeId) {
    this.showtimeId = showtimeId;
    this.container = document.getElementById('app');
    this.selectedSeats = [];
  }

  async render() {
    try {
      const seats = await APIClient.getSeats(this.showtimeId);

      this.container.innerHTML = `
        <div class="seat-view">
          <h1>Chọn ghế</h1>
          <div class="seat-grid">
            ${seats.map(seat => `
              <button 
                class="seat ${seat.status}" 
                onclick="this.handleSeatClick(${seat.id}, '${seat.status}')"
                ${seat.status === 'booked' ? 'disabled' : ''}
              >
                ${seat.number}
              </button>
            `).join('')}
          </div>
          <div class="seat-legend">
            <span class="legend available">Trống</span>
            <span class="legend selected">Đã chọn</span>
            <span class="legend booked">Đã bán</span>
          </div>
          <button onclick="router.navigate('/checkout')">Tiếp tục</button>
        </div>
      `;
    } catch (error) {
      console.error('Error loading seats:', error);
    }
  }

  handleSeatClick(seatId, status) {
    if (status === 'available') {
      if (this.selectedSeats.includes(seatId)) {
        this.selectedSeats = this.selectedSeats.filter(id => id !== seatId);
      } else {
        this.selectedSeats.push(seatId);
      }
      store.setState({ selectedSeats: this.selectedSeats });
      this.render();
    }
  }
}
