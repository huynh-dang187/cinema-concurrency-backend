/**
 * DetailView.js
 * Màn hình 2: Thông tin phim & Suất chiếu
 */

class DetailView {
  constructor(movieId) {
    this.movieId = movieId;
    this.container = document.getElementById('app');
  }

  async render() {
    try {
      const movie = await APIClient.getMovieDetail(this.movieId);
      const showtimes = await APIClient.getShowtimes(this.movieId);

      this.container.innerHTML = `
        <div class="detail-view">
          <div class="movie-info">
            <img src="assets/img/${movie.poster}" alt="${movie.title}">
            <div class="info">
              <h1>${movie.title}</h1>
              <p>${movie.description}</p>
              <p>Thời lượng: ${movie.duration} phút</p>
            </div>
          </div>
          <div class="showtimes">
            <h2>Chọn suất chiếu</h2>
            ${showtimes.map(showtime => `
              <button onclick="store.setState({selectedShowtime: ${showtime.id}}); router.navigate('/seat/${showtime.id}')">
                ${showtime.time}
              </button>
            `).join('')}
          </div>
        </div>
      `;
    } catch (error) {
      console.error('Error loading movie details:', error);
    }
  }
}
