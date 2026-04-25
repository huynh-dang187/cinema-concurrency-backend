/**
 * app.js
 * Bộ điều hướng (Router) - Quyết định hiển thị trang nào
 */

class Router {
  constructor() {
    this.routes = {};
    this.currentView = null;
  }

  register(path, view) {
    this.routes[path] = view;
  }

  navigate(path) {
    const view = this.routes[path];
    if (view) {
      this.currentView = view;
      this.render();
    } else {
      console.error(`Route not found: ${path}`);
    }
  }

  render() {
    if (this.currentView) {
      this.currentView.render();
    }
  }
}

// Initialize router
const router = new Router();
