// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "./controllers"

// Debug Stimulus
document.addEventListener('DOMContentLoaded', () => {
  console.log("DOM fully loaded");
  // Check if stimulus is available
  if (window.Stimulus) {
    console.log("Stimulus is loaded", window.Stimulus);
    console.log("Registered controllers:", window.Stimulus.application.controllers);
  } else {
    console.error("Stimulus not loaded!");
  }
});
