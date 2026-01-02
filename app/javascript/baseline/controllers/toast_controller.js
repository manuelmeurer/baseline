import ApplicationController from "application_controller"
import { Toast }             from "bootstrap"

export default class extends ApplicationController {
  static targets = ["container", "template"]

  connect() {
    document.toastController = this
  }

  show(type, body) {
    if (!["success", "error"].includes(type))
      throw new Error(`${type} is not a valid toast type.`)

    const element = this.templateTarget.cloneNode(true)

    element.classList.add(type)
    element.removeAttribute("data-toast-target")
    element.querySelector(".toast-body").innerHTML = body.replace(/\n/g, "<br>")

    this.containerTarget.prepend(element)

    new Toast(element, { delay: 10000 }).show()
  }
}
