import ApplicationController from "application_controller"
import "js-cookie"

export default class extends ApplicationController {
  static values = {
    cookieName: { type: String, default: "closed_alerts" },
    hideId:     String
  }

  connect() {
    if (!this.hasHideIdValue || !this.closedAlerts.includes(this.hideIdValue))
      this.element.classList.remove("d-none")

    const linkClass = "alert-link"
    this
      .element
      .querySelectorAll(`a:not(.btn):not(.${linkClass})`)
      .forEach(link => link.classList.add(linkClass))
  }

  disconnect() {
    document.dispatchEvent(new Event("alert-closed", { bubbles: true }))

    if (this.hasHideIdValue) {
      const closedAlerts = this.closedAlerts
      closedAlerts.push(this.hideIdValue)
      this.closedAlerts = closedAlerts
    }
  }

  get closedAlerts() {
    return JSON.parse(Cookies.get(this.cookieNameValue) || "[]")
  }

  set closedAlerts(value) {
    Cookies.set(this.cookieNameValue, JSON.stringify(value), { expires: 365 })
  }
}
