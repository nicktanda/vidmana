import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["bar", "container", "overlay"]

  connect() {
    console.log("Progress controller connected")
  }

  submit(event) {
    console.log("Form submitted!", event)
    const form = event.target
    const promptField = form.querySelector('textarea[name="universe[prompt]"]')

    console.log("Prompt field:", promptField)
    console.log("Prompt value:", promptField ? promptField.value : "no field")

    // Only show loading if there's a prompt
    if (promptField && promptField.value.trim()) {
      console.log("Showing progress bar...")

      // Show progress bar and overlay
      this.containerTarget.classList.remove('hidden')
      this.overlayTarget.classList.remove('hidden')

      console.log("Progress bar should be visible now")

      // Animate progress bar
      let progress = 0
      this.interval = setInterval(() => {
        if (progress < 90) {
          progress += Math.random() * 15
          if (progress > 90) progress = 90
          this.barTarget.style.width = progress + '%'
          console.log("Progress:", progress + "%")
        }
      }, 500)
    } else {
      console.log("No prompt or prompt is empty")
    }
  }

  disconnect() {
    console.log("Progress controller disconnected")
    if (this.interval) {
      clearInterval(this.interval)
    }
  }
}
