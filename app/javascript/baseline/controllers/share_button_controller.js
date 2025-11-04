import ApplicationController from "application_controller"

export default class extends ApplicationController {
  static values = {
    url:   String,
    title: String,
    text:  String
  }
  static targets = [
    "nativeButton",
    "webButton"
  ]

  connect() {
    if (navigator.share && matchMedia("(pointer: coarse)").matches) {
      this.nativeButtonTarget.classList.remove("d-none")
      this.webButtonTarget.classList.add("d-none")
    }
  }

  async share(event) {
    event.preventDefault()

    if (!navigator.share)
      return

    const shareData = {
      url: this.urlValue,
      ...(this.hasTitleValue && { title: this.titleValue }),
      ...(this.hasTextValue && { text: this.textValue })
    }

    try {
      await navigator.share(shareData)
    } catch (error) {
      // User cancelled or error occurred
      if (error.name !== "AbortError") {
        console.error("Error sharing:", error)
      }
    }
  }
}
