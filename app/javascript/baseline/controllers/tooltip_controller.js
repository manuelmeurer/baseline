import ApplicationController from "application_controller"
import { Tooltip }           from "bootstrap"

export default class extends ApplicationController {
  static values = {
    options: Object
  }

  connect() {
    const options = Object.assign({}, {
      html:     true,
      sanitize: false
    }, this.optionsValue)

    const tooltip = new Tooltip(this.element, options)

    this.element.addEventListener("show.bs.tooltip", () => {
      (document.visibleTooltips ??= new Set()).add(tooltip)
    })
    this.element.addEventListener("hide.bs.tooltip", () => {
      document.visibleTooltips?.delete(tooltip)
    })

    if (options.trigger && options.trigger.includes("click")) {
      this.element.addEventListener("click", event =>
        event.preventDefault()
      )
    }
  }
}
