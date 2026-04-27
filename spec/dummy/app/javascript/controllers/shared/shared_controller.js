import ApplicationController from "application_controller"
import "@hotwired/turbo-rails"

export default class extends ApplicationController {
  connect() {
    this.initSentry()
    this.handleMissingFrames()
    this.quickSubmitForms()
  }
}
