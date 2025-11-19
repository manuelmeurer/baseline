import ApplicationController from "application_controller"

export default class extends ApplicationController {
  clear(event) {
    event.preventDefault()
    this.element.querySelectorAll("input:checked").forEach(radio => radio.checked = false)
  }
}
