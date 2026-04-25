/**
 * store.js
 * Kho dữ liệu toàn cục (State Management)
 * Lưu phim/ghế/showtime đang chọn để dùng giữa các trang
 */

class Store {
  constructor() {
    this.state = {
      selectedMovie: null,
      selectedShowtime: null,
      selectedSeats: [],
      userInfo: null,
      bookingHistory: []
    };
    this.observers = [];
  }

  subscribe(observer) {
    this.observers.push(observer);
  }

  notify() {
    this.observers.forEach(observer => observer(this.state));
  }

  setState(newState) {
    this.state = { ...this.state, ...newState };
    this.notify();
  }

  getState() {
    return this.state;
  }
}

// Initialize global store
const store = new Store();
