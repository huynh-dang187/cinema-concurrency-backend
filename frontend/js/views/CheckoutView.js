/**
 * CheckoutView.js
 * Màn hình 4: Xác nhận & Thanh toán
 */

class CheckoutView {
  constructor() {
    this.container = document.getElementById('app');
  }

  async render() {
    const state = store.getState();
    const totalPrice = state.selectedSeats.length * 100000; // VND

    this.container.innerHTML = `
      <div class="checkout-view">
        <h1>Xác nhận đặt vé</h1>
        <div class="order-summary">
          <p>Ghế: ${state.selectedSeats.join(', ')}</p>
          <p>Tổng tiền: ${totalPrice.toLocaleString('vi-VN')} đ</p>
        </div>
        <form onsubmit="handleCheckout(event)">
          <input type="text" placeholder="Họ tên" required>
          <input type="email" placeholder="Email" required>
          <input type="tel" placeholder="Số điện thoại" required>
          <button type="submit">Thanh toán</button>
        </form>
      </div>
    `;
  }
}
