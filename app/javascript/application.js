// Entry point for the build script in your package.json
import "@hotwired/turbo-rails"
import "./controllers"

const enableLoadingButtons = () => {
  document.querySelectorAll("button[data-loading-button]").forEach((button) => {
    button.addEventListener("click", () => {
      const form = button.closest("form")
      if (!form) return

      const spinner = button.querySelector(".loading-spinner")
      const label = button.querySelector(".loading-label")
      const loadingText = button.getAttribute("data-loading-text")

      requestAnimationFrame(() => {
        button.disabled = true
        if (spinner) spinner.classList.remove("d-none")
        if (label && loadingText) label.textContent = loadingText
      })
    }, { once: true })
  })
}

document.addEventListener("turbo:load", enableLoadingButtons)
