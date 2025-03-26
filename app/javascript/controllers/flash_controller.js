import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    console.log("Flash controller connected", this.element)
    // Auto-dismiss after 5 seconds
    setTimeout(() => {
      this.dismiss()
    }, 5000)
  }

  dismiss() {
    console.log("Dismissing flash message", this.element)
    this.element.classList.add('opacity-0')
    setTimeout(() => {
      console.log("Removing flash message from DOM")
      this.element.remove()
    }, 300) // Match this with CSS transition duration
  }
} 