import ApplicationController from "application_controller"

export default class extends ApplicationController {
  static values = {
    submitAfter: { type: Number, default: 500 }
  }

  connect() {
    this.element.addEventListener("change", (event) => {
      if (!event.target.matches("select, input[type='checkbox'], input[type='radio']"))
        return

      this
        .waitForConstant("Turbo")
        .then(() =>
          this.element.requestSubmit()
        )
    })

    this
      .element
      .querySelectorAll('input[type="text"], textarea')
      .forEach(element => {

      element.addEventListener("input", event => {
        if (this.shouldIgnore(event))
          return

        // TODO: use this.debounce() here.
        clearTimeout(this.timeout)
        this.timeout = setTimeout(
          () => this.submitForm(event.target),
          this.submitAfterValue
        )
      })

      element.addEventListener("focus", event => {
        this.saveLastValue(event.target)
      })

      element.addEventListener("focusout", event => {
        if (this.shouldIgnore(event))
          return
        clearTimeout(this.timeout)
        this.submitForm(event.target)
      })
    })
  }

  shouldIgnore(event) {
    return [
      9,              // Tab
      16, 17, 18,     // Shift, Alt, Ctrl
      27,             // Caps lock
      37, 38, 39, 40, // Arrows
      91, 92, 93      // Windows keys
    ].includes(event.which)
  }

  saveLastValue(element) {
    element.dataset.lastValue = element.value
  }

  submitForm(element) {
    if (element.value !== element.dataset.lastValue) {
      this.saveLastValue(element)
      element.closest("form").requestSubmit()
    }
  }
}
