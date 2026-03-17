import { Controller } from "@hotwired/stimulus"
import { get }        from "@rails/request.js"

function showAlert(message) {
  const container = document.querySelector("turbo-frame#alerts")
  if (!container)
    throw new Error("Could not find turbo-frame#alerts container")

  const div = document.createElement("div")
  div.dataset.controller = "alert"
  div.dataset.alertDismissAfterValue = "5000"
  div.dataset.alertRemoveDelayValue = "0"
  div.className = "max-w-lg w-full shadow-lg rounded px-4 py-3 rounded relative border text-white pointer-events-auto bg-green-500 border-green-600"
  div.innerHTML = `
    <div class="px-2">
      <div class="flex h-full">
        <div class="ml-3 w-0 flex-1 pt-0.5">
          <p class="text-sm leading-5 font-semibold">${message}</p>
        </div>
        <div class="ml-4 flex-shrink-0 flex items-center">
          <button data-action="alert#close" class="inline-flex text-white focus:outline-none focus:text-gray-300 transition ease-in-out duration-150">
            <svg class="h-5 w-5" viewBox="0 0 20 20" fill="currentColor">
              <path fill-rule="evenodd" d="M4.293 4.293a1 1 0 011.414 0L10 8.586l4.293-4.293a1 1 0 111.414 1.414L11.414 10l4.293 4.293a1 1 0 01-1.414 1.414L10 11.414l-4.293 4.293a1 1 0 01-1.414-1.414L8.586 10 4.293 5.707a1 1 0 010-1.414z" clip-rule="evenodd"/>
            </svg>
          </button>
        </div>
      </div>
    </div>
  `
  container.appendChild(div)
}

class FormReloadController extends Controller {
  async reload(event) {
    const fields = event.params.fields

    const url = new URL(window.location.href)
    const attribute = event.target.closest("[data-field-id]")?.dataset.fieldId
    if (!attribute)
      throw new Error("Could not find data-field-id attribute on or above the target element")
    url.searchParams.set(attribute, event.target.value)

    const response = await get(url.toString())
    if (!response.ok)
      throw new Error(`Form reload request failed with status ${response.statusCode}`)

    const html = await response.html
    const parser = new DOMParser()
    const doc = parser.parseFromString(html, "text/html")

    fields.forEach(fieldId => {
      const selector     = `[data-field-id="${fieldId}"]`
      const newField     = doc.querySelector(selector)
      const currentField = document.querySelector(selector)

      if (!newField)     throw new Error(`Could not find field "${fieldId}" in the response`)
      if (!currentField) throw new Error(`Could not find field "${fieldId}" on the page`)

      currentField.replaceWith(newField.cloneNode(true))
    })

    showAlert(`Updated ${fields.join(", ")}!`)
  }
}

const application = window.Stimulus
application.register("form-reload", FormReloadController)

// Collapse tall fields on show pages
const FIELD_MAX_HEIGHT = 200

function collapseFields() {
  document.querySelectorAll(".field-wrapper [data-slot='value']").forEach(valueEl => {
    const wrapper = valueEl.closest(".field-wrapper")
    if (wrapper.classList.contains("field-value-processed")) return
    wrapper.classList.add("field-value-processed")

    if (valueEl.scrollHeight <= FIELD_MAX_HEIGHT) return

    wrapper.classList.add("field-value-collapsed")

    // Override self-center to prevent vertical centering of clipped content
    const innerDiv = valueEl.querySelector(":scope > div")
    if (innerDiv) innerDiv.classList.replace("self-center", "self-start")

    const btn = document.createElement("button")
    btn.type = "button"
    btn.className = "field-value-toggle"
    btn.textContent = "Show all"
    btn.addEventListener("click", () => {
      const collapsed = wrapper.classList.toggle("field-value-collapsed")
      btn.textContent = collapsed ? "Show all" : "Show less"
    })

    // Wrap value and button in a column container so the button appears below the text
    const col = document.createElement("div")
    col.className = "field-value-container"
    valueEl.parentNode.insertBefore(col, valueEl)
    col.appendChild(valueEl)
    col.appendChild(btn)
  })
}

collapseFields()
document.addEventListener("turbo:load", collapseFields)
document.addEventListener("turbo:frame-load", collapseFields)

// Close Avo action modal on Escape key
document.addEventListener("keydown", event => {
  if (event.key !== "Escape")
    return

  const modal = document.querySelector(".modal-container[data-controller='modal']")
  if (modal) {
    const controller = application.getControllerForElementAndIdentifier(modal, "modal")
    controller?.closeModal()
  }
})
