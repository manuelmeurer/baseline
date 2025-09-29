import ApplicationController from "application_controller"
import { highlightAll } from "lexxy"

export default class extends ApplicationController {
  connect() {
    this.enableStylesheets("lexxy")
    highlightAll()
  }
}
