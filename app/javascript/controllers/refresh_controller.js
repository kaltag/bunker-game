import { Controller } from "@hotwired/stimulus"
import * as Turbo from "@hotwired/turbo-rails"

// Polling-контроллер: переоткрывает страницу через Turbo каждые N секунд.
// Turbo 8 Morphing обновит только изменившиеся элементы, скролл сохранится.
export default class extends Controller {
  static values = { interval: { type: Number, default: 3 } }

  connect() {
    this.timer = setInterval(() => {
      // Не обновляем, пока пользователь заполняет форму
      if (document.activeElement?.tagName === "INPUT" || document.activeElement?.tagName === "SELECT") return

      Turbo.visit(window.location.href, { action: "replace" })
    }, this.intervalValue * 1000)
  }

  disconnect() {
    clearInterval(this.timer)
  }
}
