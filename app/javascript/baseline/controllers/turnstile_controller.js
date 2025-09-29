import ApplicationController from "application_controller"

export default class extends ApplicationController {
  static targets = ["container"]
  static values = {
    waitingForInteraction: Boolean
  }

  connect() {
    const siteKey      = this.metaContent("turnstile_site_key")
    const fieldName    = "cf-turnstile-response"
    const errorMessage = this.metaContent("turnstile_error_message")

    let intervalId, field

    if (!siteKey)
      return

    this.element.addEventListener("turbo:submit-start", event => {
      if (event.detail.formSubmission.body.get(fieldName)?.length)
        return

      if (this.waitingForInteractionValue)
        this.toastOutlet.show("error", errorMessage)
      else if (!intervalId) {
        intervalId = setInterval(() => {
          field = this.element.querySelector(`input[name='${fieldName}']`)

          if (!field) {
            clearInterval(intervalId)
            this.toastOutlet.show("error", "An error occurred, please reload the page and try again.")
          }

          if (field.value) {
            clearInterval(intervalId)
            this.element.requestSubmit()
          }
        }, 250)
      }

      event.detail.formSubmission.stop()
    })

    window.turnstileLoaded = () => {
      this.widgetId = turnstile.render(this.containerTarget, {
        sitekey:    siteKey,
        appearance: "interaction-only",
        "before-interactive-callback": () => {
          this.waitingForInteractionValue = true
          this.containerTarget.classList.remove("d-none")
        }
      })
    }

    const script = document.createElement("script")
    script.src = "https://challenges.cloudflare.com/turnstile/v0/api.js?onload=turnstileLoaded"
    document.head.appendChild(script)
  }

  disconnect() {
    if (this.widgetId)
      turnstile.remove(this.widgetId)
  }
}
