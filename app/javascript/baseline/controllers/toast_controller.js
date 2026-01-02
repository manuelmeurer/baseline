import ApplicationController from "application_controller"
import { Toast }             from "bootstrap"

export default class extends ApplicationController {
  static targets = ["container", "template"]

  connect() {
    document.toastController = this
  }

  // Override in child classes to adjust container position before showing a toast.
  beforeShow() {}

  show(type, body) {
    if (!["success", "error"].includes(type))
      throw new Error(`${type} is not a valid toast type.`)

    this.beforeShow()

    const element = this.templateTarget.cloneNode(true)

    element.classList.add(type)
    element.removeAttribute("data-toast-target")
    element
      .querySelector(`.icon-${type}`)
      .classList
      .remove("d-none")
    element
      .querySelector(".toast-body .text")
      .innerHTML = this.simpleFormat(body)

    this.containerTarget.prepend(element)

    // Keep only the 4 newest toasts (new one + 3 previous)
    const toasts = this.containerTarget.querySelectorAll(".toast")
    toasts.forEach((toast, index) => {
      if (index >= 4)
        toast.remove()
    })

    new Toast(element, { delay: 10000 }).show()
  }
}
