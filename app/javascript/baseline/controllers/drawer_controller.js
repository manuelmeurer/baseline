import ApplicationController from "application_controller"

export default class extends ApplicationController {
  static targets = ["toggle", "frame"]

  connect() {
    document.drawerController = this
    this.keyHandler = event => {
      if (event.key === "Escape")
        this.closeDrawer()
    }
    document.addEventListener("keydown", this.keyHandler)
  }

  disconnect() {
    document.removeEventListener("keydown", this.keyHandler)
    if (document.drawerController === this)
      document.drawerController = null
  }

  open(event) {
    event.preventDefault()
    this.openDrawer(event.params.url)
  }

  openDrawer(url) {
    const absolute = new URL(url, document.baseURI).toString()
    if (this.frameTarget.src === absolute)
      this.frameTarget.reload()
    else
      this.frameTarget.src = url
    this.toggleTarget.checked = true
  }

  close() {
    this.closeDrawer()
  }

  closeDrawer() {
    this.toggleTarget.checked = false
  }
}
