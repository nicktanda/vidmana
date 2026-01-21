import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  toggleAdd(event) {
    event.preventDefault()
    event.stopPropagation()

    const formId = event.currentTarget.dataset.formId
    const form = document.getElementById(formId)
    if (form) {
      form.classList.toggle('hidden')
    }
  }

  toggleEdit(event) {
    event.preventDefault()
    event.stopPropagation()

    const type = event.currentTarget.dataset.type
    const id = event.currentTarget.dataset.id
    const viewEl = document.getElementById(`${type}-view-${id}`)
    const editEl = document.getElementById(`${type}-edit-${id}`)

    if (viewEl && editEl) {
      viewEl.classList.toggle('hidden')
      editEl.classList.toggle('hidden')
    }
  }
}
