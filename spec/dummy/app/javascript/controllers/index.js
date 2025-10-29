import { Application }              from "@hotwired/stimulus"
import { eagerLoadControllersFrom } from "@hotwired/stimulus-loading"

const application = Application.start()

application.debug = false
window.Stimulus   = application

// Eager load all controllers that have been preloaded via importmap.
const preloadedControllerNamespaces = Array
  .from(document.querySelectorAll("link[rel=modulepreload]"))
  .map(link => link.href.match(/\/controllers\/([^\/]+)\//)?.[1])
  .filter(Boolean)

new Set(preloadedControllerNamespaces)
  .forEach(namespace =>
    eagerLoadControllersFrom(`controllers/${namespace}`, application)
  )
