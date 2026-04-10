import ApplicationController from "application_controller"

export default class extends ApplicationController {
  static values = {
    dismissAfter: { type: Number, default: 10000 }
  }

  connect() {
    if (this.dismissAfterValue > 0)
      this.timeout = setTimeout(() =>
        this.dismiss(), this.dismissAfterValue
      )
  }

  disconnect() {
    if (this.timeout)
      clearTimeout(this.timeout)
  }

  dismiss() {
    // Fade out, then remove. The starting: variants handle entry;
    // for exit we toggle opacity/translate and wait for the transition.
    this.element.classList.add("opacity-0", "translate-y-2", "sm:translate-x-2", "sm:translate-y-0")
    this.element.addEventListener("transitionend", () =>
      this.element.remove(), { once: true }
    )
  }
}
