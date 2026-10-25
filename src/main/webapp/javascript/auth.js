(() => {
  "use strict";

  const message = document.querySelector("#auth-message");
  const connectionNote = document.querySelector("#connection-note");

  function showMessage(text, type = "info") {
    if (!message) return;
    message.hidden = false;
    message.dataset.type = type;
    message.textContent = text;
  }

  function clearMessage() {
    if (!message) return;
    message.hidden = true;
    message.textContent = "";
    delete message.dataset.type;
  }

  function showPanel(mode) {
    clearMessage();
    const panels = {
      login: document.querySelector("#login-panel"),
      register: document.querySelector("#register-panel"),
      recovery: document.querySelector("#recovery-panel")
    };
    Object.entries(panels).forEach(([key, panel]) => {
      if (panel) panel.hidden = key !== mode;
    });
    document.querySelectorAll("[data-auth-mode]").forEach((tab) => {
      const selected = tab.dataset.authMode === mode;
      tab.setAttribute("aria-selected", String(selected));
      tab.classList.toggle("is-active", selected);
      tab.tabIndex = selected ? 0 : -1;
    });
  }

  function initAccess() {
    if (connectionNote) {
      connectionNote.textContent = "Conexión local activa con XAMPP / MySQL.";
    }

    const params = new URLSearchParams(window.location.search);
    const initialMode = params.get("mode") === "register" ? "register" : "login";
    const requestedRole = params.get("role") === "producer" ? "producer" : "actor";
    const roleField = document.querySelector('#register-panel [name="role"]');
    if (roleField) roleField.value = requestedRole;
    showPanel(initialMode);

    document.querySelectorAll("[data-auth-mode]").forEach((tab) => {
      tab.addEventListener("click", () => showPanel(tab.dataset.authMode));
    });
    document.querySelector("#forgot-password")?.addEventListener("click", () => showPanel("recovery"));
    document.querySelector("[data-back-login]")?.addEventListener("click", () => showPanel("login"));

    const registerForm = document.querySelector("#register-panel");
    registerForm?.addEventListener("submit", (event) => {
      const password = registerForm.querySelector('[name="password"]')?.value;
      const passwordConfirm = registerForm.querySelector('[name="passwordConfirm"]')?.value;
      
      if (password && passwordConfirm && password !== passwordConfirm) {
        event.preventDefault();
        showMessage("Las contraseñas no coinciden.", "error");
      }
    });
  }

  function initReset() {
    const form = document.querySelector("#reset-password-form");
    if (connectionNote) {
      connectionNote.textContent = "Restablecimiento de contraseña local.";
    }

    form?.addEventListener("submit", (event) => {
      const password = form.querySelector('[name="password"]')?.value;
      const passwordConfirm = form.querySelector('[name="passwordConfirm"]')?.value;

      if (password && passwordConfirm && password !== passwordConfirm) {
        event.preventDefault();
        showMessage("Las contraseñas no coinciden.", "error");
      }
    });
  }

  const page = document.body.dataset.authPage;
  if (page === "access") initAccess();
  if (page === "reset") initReset();
})();