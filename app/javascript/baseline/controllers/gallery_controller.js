import ApplicationController from "application_controller"
import PhotoSwipe            from "photoswipe"
import PhotoSwipeLightbox    from "photoswipe-lightbox"

export default class extends ApplicationController {
  connect() {
    this.enableStylesheets("photoswipe")

    this
      .element
      .querySelectorAll("a")
      .forEach(link => {

      const image = new Image()
      image.onload = function() {
        link.dataset.pswpWidth  = image.width
        link.dataset.pswpHeight = image.height
      }
      image.src = link.getAttribute("href")
    })

    new PhotoSwipeLightbox({
      gallery:    this.element,
      children:   "a",
      pswpModule: PhotoSwipe
    }).init()
  }
}
