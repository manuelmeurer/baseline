import ApplicationController from "application_controller"

export default class extends ApplicationController {
  static values = {
    attribute:    String,
    attributeKey: { type: String, default: "attribute" },
    searchKey:    { type: String, default: "search"    },
    async:        Boolean,
    asyncUrl:     String,
    placeholder:  String,
    width:        { type: String, default: "100%"      }
  }

  async connect() {
    this.enableStylesheets("select2")

    await import("jquery")
    await import("select2")

    const options = {
      theme:       "bootstrap-5",
      width:       this.widthValue,
      placeholder: this.placeholderValue || "", // Necessary for `allowClear`
      allowClear:  true
    }

    if (this.element.querySelectorAll("option").length < 10 && !this.element["multiple"])
      options["minimumResultsForSearch"] = Infinity

    if (this.inModal())
      options["dropdownParent"] = document.modalController.contentTarget

    if (this.asyncValue) {
      const data = params => {
        const data = {
          [this.searchKeyValue]: params.term
        }
        if (this.hasAttributeValue)
          data[this.attributeKeyValue] = this.attributeValue
        return data
      }
      const processResults = data => {
        const selectedOptions = this.element.selectedOptions
        var results
        if (selectedOptions.length) {
          const selectedIds = Array.from(selectedOptions, option => option.value)
          results = data.results.filter(element =>
            !selectedIds.includes(String(element.id))
          )
        } else
          results = data.results
        return {
          results: results
        }
      }
      Object.assign(options, {
        minimumInputLength: 1,
        ajax: {
          url:            this.asyncUrlValue || this.currentUrl,
          dataType:       "json",
          delay:          250,
          data:           data,
          processResults: processResults
        }
      })
    }

    $(this.element).select2(options)

    this.doBeforeAndAfterMorph(
      () => $(this.element).select2("destroy"),
      () => this.connect()
    )
  }
}
