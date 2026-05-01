import ApplicationController from "application_controller"

export default class extends ApplicationController {
  login(event) {
    const token = event.target.value
    if (!token)
      return

    Turbo.visit(`/?t=${encodeURIComponent(token)}`)
  }
}
