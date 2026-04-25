/**
 * api.js
 * API Client - Kết nối với Backend
 * Chứa các hàm gọi fetch() đến Backend
 */

const API_BASE_URL = 'http://localhost:8080/api';

class APIClient {
  // Movies
  static async getMovies() {
    const response = await fetch(`${API_BASE_URL}/movies`);
    return response.json();
  }

  static async getMovieDetail(movieId) {
    const response = await fetch(`${API_BASE_URL}/movies/${movieId}`);
    return response.json();
  }

  // Showtimes
  static async getShowtimes(movieId) {
    const response = await fetch(`${API_BASE_URL}/showtimes?movieId=${movieId}`);
    return response.json();
  }

  // Seats
  static async getSeats(showtimeId) {
    const response = await fetch(`${API_BASE_URL}/seats?showtimeId=${showtimeId}`);
    return response.json();
  }

  // Booking
  static async createBooking(bookingData) {
    const response = await fetch(`${API_BASE_URL}/bookings`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(bookingData)
    });
    return response.json();
  }

  // History
  static async getBookingHistory(userId) {
    const response = await fetch(`${API_BASE_URL}/bookings/user/${userId}`);
    return response.json();
  }
}
