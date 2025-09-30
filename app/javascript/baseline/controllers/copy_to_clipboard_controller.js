import ApplicationController from "application_controller"

export default class extends ApplicationController {
  static targets = ["container"]
  static values = {
    text: String
  }

  copy(event) {
    event.preventDefault()

    const text =
      this.textValue ||
      this.containerTarget.value ||
      this.containerTarget.innerText

    navigator
      .clipboard
      .writeText(text)

    const triggerElement = event.currentTarget
    var initialHTML = triggerElement.innerHTML
    triggerElement.innerText = "Copied!"
    setTimeout(() => {
      triggerElement.innerHTML = initialHTML
    }, 2000)
  }
}
