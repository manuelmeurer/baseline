import ApplicationController from "application_controller"
import { Modal }             from "bootstrap"

export default class extends ApplicationController {
  static targets = [
    "dialog",
    "content",
    "header",
    "title",
    "actions",
    "body",
    "frame",
    "footer",
    "titleContent",
    "actionsContent",
    "footerContent",
    "warnOnClose"
  ]
  static values  = {
    defaultSize: String,
    loading:     String
  }

  connect() {
    document.modalController = this
    this.isTailwind = this.element.tagName === "DIALOG"

    this.scrollToFrameOnSubmitEnd(this.frameTarget)

    this.frameTarget.addEventListener("turbo:frame-load", () => {
      this.setHeaderAndFooter()
      this.focusFirstFormInput()
      this.fixModalLinks()
      this.fixForms()
    })

    if (this.isTailwind) {
      this.element.addEventListener("close", () => {
        this.indexDomID = null
      })
    } else {
      this.element.addEventListener("show.bs.modal", event => {
        if (!event.relatedTarget)
          return

        const url  = event.relatedTarget.dataset.url
        const size = event.relatedTarget.dataset.size

        this.indexDomID = this.getIndexDomID(event.relatedTarget)

        this.init(url, size)
      })

      this.element.addEventListener("hide.bs.modal", event => {
        if (this.hasWarnOnCloseTarget && !confirm("Close modal with form?")) {
          event.preventDefault()
          return
        }

        this.indexDomID = null

        this.dialogTarget.classList.remove("modal-sm", "modal-lg", "modal-xl")
      })
    }

    this.element.addEventListener("click", event => {
      if (event.target.closest("[data-update-modal-url]")) {
        event.preventDefault()
        this.url = event.target.dataset.url
      }
    })
  }

  // Stimulus action for Tailwind modal links (data-action="click->modal#open")
  open(event) {
    event.preventDefault()
    const url  = event.params.url
    const size = event.params.size

    this.indexDomID = this.getIndexDomID(event.currentTarget)

    this.init(url, size)
    this.element.showModal()
  }

  // Stimulus action for Tailwind close button (data-action="modal#close")
  close() {
    if (this.hasWarnOnCloseTarget && !confirm("Close modal with form?"))
      return
    this.element.close()
  }

  init(url, size = this.defaultSizeValue) {
    document.visibleTooltips?.forEach(tooltip => { tooltip.hide() })

    if (size && size.length) {
      if (this.isTailwind)
        this.dialogTarget.classList.add(`max-w-${size}`)
      else
        this.dialogTarget.classList.add(`modal-${size}`)
    }

    // Semicolon is necessary.
    ;[
      this.titleTarget,
      this.actionsTarget,
      this.footerTarget
    ].forEach(element =>
      element.innerHTML = ""
    )
    this.frameTarget.innerHTML = this.loadingValue
    this.url = url
  }

  showModal(url) {
    if (this.isTailwind) {
      this.element.showModal()
      this.init(url)
    } else {
      this.modal.show()
      this.init(url)
    }
  }

  closeModal() {
    if (this.hasWarnOnCloseTarget)
      this.warnOnCloseTarget.remove()

    if (this.isTailwind)
      this.element.close()
    else
      this.modal.hide()
  }

  get modal() {
    return Modal.getOrCreateInstance(this.element)
  }

  get modalIsOpen() {
    if (this.isTailwind)
      return this.element.open
    else
      return document.body.classList.contains("modal-open")
  }

  set url(value) {
    if (this.frameTarget.src === value.toString())
      this.reload()
    else
      this.frameTarget.src = value
  }

  get url() {
    return new URL(this.frameTarget.src, document.baseURI)
  }

  reload() {
    this.frameTarget.reload()
  }

  setHeaderAndFooter() {
    const hiddenClass = this.isTailwind ? "hidden" : "d-none"

    this.headerTarget.classList.toggle(hiddenClass, !this.hasTitleContentTarget && !this.hasActionsContentTarget)
    if (this.hasTitleContentTarget)
      this.titleTarget.textContent = this.titleContentTarget.innerText.trim()
    if (this.hasActionsContentTarget)
      this.actionsTarget.innerHTML = this.actionsContentTarget.innerHTML

    this.footerTarget.classList.toggle(hiddenClass, !this.hasFooterContentTarget)
    if (this.hasFooterContentTarget) {
      // If the footer content contains submit buttons without a form attribute,
      // add it so that they still work.
      this
        .footerContentTarget
        .querySelectorAll("button[type=submit]:not([form])")
        .forEach(submit => {
          const form = this.footerContentTarget.closest("form")
          if (!form)
            throw new Error("Could not find form for submit button.")
          if (!form.id.length)
            form.id = (Math.random() + 1).toString(36).substring(2)
          submit.setAttribute("form", form.id)
        })

      // If the footer content contains regular links with no data-turbo-frame attribute,
      // add it so that the response is loaded into the modal.
      const dismissSelector = this.isTailwind
        ? ":not([data-action*='modal#close'])"
        : ":not([data-bs-dismiss])"
      this
        .footerContentTarget
        .querySelectorAll(`a${dismissSelector}:not([data-turbo-frame])`)
        .forEach(link => {
          link.setAttribute("data-turbo-frame", "modal")
        })

      this.footerTarget.innerHTML = this.footerContentTarget.innerHTML
    }
  }

  focusFirstFormInput() {
    const input = this
      .bodyTarget
      .querySelector(
        "form input[type='text']:not([data-controller='datepicker']), \
        form textarea"
      )

    if (input && this.elementIsInViewport(input))
      input.focus()
  }

  async fixForms() {
    // Bootstrap-specific: adjust form column classes that are too wide for the modal.
    // Not needed for Tailwind which doesn't use Bootstrap's col-* grid in modals.
    if (this.isTailwind)
      return

    const bodyWidth = this.bodyTarget.clientWidth

    await this.pollUntil(() =>
      bodyWidth > 0
    )

    const breakpoints = {
      xxl: 1400,
      xl:  1200,
      lg:   992,
      md:   768,
      sm:   576
    }
    const largerBreakpoints = Object
      .keys(breakpoints)
      .filter(breakpoint =>
        breakpoints[breakpoint] > bodyWidth
      )

    if (!largerBreakpoints.length)
      return

    const removeRegex = new RegExp(`\\b(col|offset)-(${largerBreakpoints.join("|")})(-\\S+)?`)
    const checkRegex  = new RegExp(`^col(-(auto|${Object.keys(breakpoints).join("|")}))?(-\\d+)?$`)
    let   oldClassList, newClassList

    this.bodyTarget.querySelectorAll("form :not(svg)").forEach(element => {
      if (!element.classList.length)
        return

      oldClassList = Array.from(element.classList)
      element.className = element
        .className
        .split(/\s+/)
        .filter(name => !removeRegex.test(name))
        .join(" ")
      newClassList = Array.from(element.classList)
      if (JSON.stringify(oldClassList) != JSON.stringify(newClassList) &&
         !newClassList.some(className => checkRegex.test(className))) {
        element.classList.add("col-12")
      }
    })
  }

  fixModalLinks() {
    // Bootstrap: convert nested modal links to update-modal-url handlers
    this.element.querySelectorAll("[data-bs-toggle=modal]").forEach(element => {
      delete element.dataset.bsToggle
      element.dataset.updateModalUrl = ""
    })

    // Tailwind: convert nested modal open actions to update-modal-url handlers
    this.element.querySelectorAll("[data-action*='modal#open']").forEach(element => {
      element.dataset.action = element.dataset.action
        .replace(/click->modal#open/g, "")
        .trim()
      element.dataset.updateModalUrl = ""
      element.dataset.url = element.dataset.modalUrlParam
      delete element.dataset.modalUrlParam
    })
  }
}
