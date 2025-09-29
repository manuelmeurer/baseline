import ApplicationController from "application_controller"

export default class extends ApplicationController {
  connect() {
    this.enableStylesheets("lexxy")

    import("lexxy")
    import("@rails/actiontext")
  }
}
