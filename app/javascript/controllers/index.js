import { Application } from "@hotwired/stimulus"

const application = Application.start()

// Configure Stimulus development experience
application.debug = false
window.Stimulus   = application

// Import and register all your controllers from the importmap under controllers/**/*_controller
const controllers = import.meta.globEager('./**/*_controller.js')

Object.entries(controllers).forEach(([path, controller]) => {
  const name = path.replace(/^\.\/(.*)_controller\.[^.]*$/, '$1')
  application.register(name, controller.default)
})
