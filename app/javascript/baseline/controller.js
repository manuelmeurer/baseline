import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
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
}
