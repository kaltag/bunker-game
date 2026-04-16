import { Controller } from "@hotwired/stimulus"
import { Turbo } from "@hotwired/turbo-rails"

// Fallback-поллинг: обновляет страницу через Turbo если WebSocket не доставил обновление.
// Turbo 8 Morphing обновит только изменившиеся элементы, скролл сохранится.
export default class extends Controller {
  static values = { interval: { type: Number, default: 5 } }

  connect() {
    this.timer = setInterval(() => {
      if (document.activeElement?.tagName === "INPUT" || document.activeElement?.tagName === "SELECT") return

      Turbo.visit(window.location.href, { action: "replace" })
    }, this.intervalValue * 1000)
  }

  disconnect() {
    clearInterval(this.timer)
  }
}
