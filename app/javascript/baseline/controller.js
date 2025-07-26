import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  startLocalTime(localTime) {
    localTime.config.useFormat24 = true
    localTime.config.i18n["de"]  = JSON.parse(this.metaContent("local_time_i18n_de"))
    localTime.config.locale      = this.currentLocale.split("-")[0]

    localTime.start()

    document.addEventListener("turbo:morph", () => {
      localTime.run()
    })
  }

  metaContent(name) {
    return document.head.querySelector(`meta[name="${name}"]`)?.content
  }

  inModal(element = this.element) {
    return document.modalController?.element.contains(element)
  }

  getFormMethod(form) {
    if (!form.tagName === "FORM")
      throw new Error(`Expected a form element but got a ${form.tagName}`)

    return Array
      .from(form)
      .find(element => element.name === "_method")
      ?.value ||
        form.getAttribute("method") ||
        "post"
  }

  getFormSubmitElements(form) {
    if (!form.tagName === "FORM")
      throw new Error(`Expected a form element but got a ${form.tagName}`)

    const elements = new Set(form.querySelectorAll("[type='submit']"))

    if (this.inModal(form))
      document
        .modalController
        .footerTarget
        .querySelectorAll("[type='submit']")
        .forEach(element => elements.add(element))

    const turboMethodLink = this.getTurboMethodLink(
      form.action,
      this.getFormMethod(form)
    )
    if (turboMethodLink)
      elements.add(turboMethodLink)

    return elements
  }

  getTurboMethodLink(url, method) {
    const links = this.element.querySelectorAll(`a[data-turbo-method="${method}"]`)

    return Array
      .from(links)
      .find(link => link.href === url)
  }

  showToast(type, body) {
    const toastController = document.querySelector("[data-controller='toast']")
    this.application
      .getControllerForElementAndIdentifier(toastController, "toast")
      .show(type, body)
  }

  elementIsInViewport(element) {
    var rect = element.getBoundingClientRect()

    return (
      rect.top    >= 0 &&
      rect.left   >= 0 &&
      rect.bottom <= (window.innerHeight || document.documentElement.clientHeight) &&
      rect.right  <= (window.innerWidth  || document.documentElement.clientWidth)
    )
  }

  waitForConstant(name, interval = 100, timeout = 10000) {
    return new Promise((resolve, reject) => {
      const startTime = Date.now()

      function checkConstant() {
        if (typeof window[name] !== "undefined") {
          resolve(window[name])
        } else if (Date.now() - startTime >= timeout) {
          reject(new Error(`${name} is not defined within the timeout period.`))
        } else {
          setTimeout(checkConstant, interval)
        }
      }

      checkConstant()
    })
  }

  toggleFromUrl() {
    let idSuffix, checkbox, checked

    for (const param of ["on", "off"]) {
      idSuffix = this.getSearchParam(param)
      checked = param === "on"

      if (!idSuffix)
        continue

      checkbox = Array
        .from(this.element.querySelectorAll("input[type='checkbox']"))
        .find(element => element.id.endsWith(idSuffix))

      if (!checkbox || (checkbox.checked === checked))
        continue

      checkbox.checked = checked
      checkbox.dispatchEvent(new Event("change"), { bubbles: true })
    }
  }

  getSearchParam(param) {
    return new URLSearchParams(this.currentUrl.search).get(param)
  }

  get currentUrl() {
    return this.inModal() ? document.modalController.url : window.location
  }

  get currentLocale() {
    return document.documentElement.lang
  }

  enableStylesheets(name) {
    const disabledStylesheets = JSON.parse(this.metaContent("disabled_stylesheets"))

    if (!disabledStylesheets[name])
      throw new Error(`No disabled stylesheets found for ${name}.`)

    disabledStylesheets[name].forEach(link => {
      const url = new DOMParser()
        .parseFromString(link, "text/html")
        .querySelector("link")
        .getAttribute("href")

      if (document.querySelector(`link[href="${url}"]`))
        return

      document.head.insertAdjacentHTML('beforeend', link)
    })
  }

  async showCookieConsent() {
    if (this.element.querySelector("[data-hide-cookie-consent]"))
      return

    const CookieConsent = await import("cookieconsent")

    CookieConsent.run({
      categories: {
        necessary: {
          enabled: true,
          readOnly: true
        },
        analytics: {}
      },
      language: {
        default: "en",
        translations: {
          en: {
            consentModal: {
              title: "🍪 We use cookies!",
              acceptAllBtn: "Accept all",
              acceptNecessaryBtn: "Reject all",
              showPreferencesBtn: "Manage preferences"
            },
            preferencesModal: {
              title: "Manage cookie preferences",
              acceptAllBtn: "Accept all",
              acceptNecessaryBtn: "Reject all",
              savePreferencesBtn: "Accept current selection",
              closeIconLabel: "Close modal",
              sections: [
                {
                  title: "🍪 We use cookies to make this site work.",
                }, {
                  title: "Strictly Necessary cookies",
                  description: "These cookies are essential for the proper functioning of the website and cannot be disabled.",
                  linkedCategory: "necessary"
                }, {
                  title: "Performance and Analytics",
                  description: "These cookies collect information about how you use our website. All of the data is anonymized and cannot be used to identify you.",
                  linkedCategory: "analytics"
                }
              ]
            }
          }
        }
      }
    })
  }
}
