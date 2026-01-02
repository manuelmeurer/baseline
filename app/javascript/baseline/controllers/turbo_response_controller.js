import ApplicationController from "application_controller"

export default class extends ApplicationController {
  static values = {
    redirect:          String,
    successMessage:    String,
    errorMessage:      String,
    closeModal:        Boolean,
    reloadMain:        Boolean,
    reloadMainOrModal: Boolean,
    reloadFrames:      Array
  }

  connect() {
    if (this.redirectValue)
      if (document.modalController?.modalIsOpen)
        document.modalController.url = this.redirectValue
      else
        Turbo.visit(this.redirectValue)

    if (this.closeModalValue)
      document.modalController?.closeModal()

    if (this.reloadMainValue) {
      this.main.reload()
      this.navbar?.reload()
    }

    if (this.reloadMainOrModalValue)
      if (document.modalController?.modalIsOpen)
        document.modalController.reload()
      else {
        this.main.reload()
        this.navbar?.reload()
      }

    this.reloadFramesValue?.forEach(id =>
      document.querySelector(`turbo-frame#${id}`).reload()
    )

    if (this.successMessageValue)
      document.toastController.show("success", this.successMessageValue)

    if (this.errorMessageValue)
      document.toastController.show("error", this.errorMessageValue)
  }
}
