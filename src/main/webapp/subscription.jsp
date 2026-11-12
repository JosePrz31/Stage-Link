// =========================================================================
// StageLink · Flujo de suscripción de Productora 
// =========================================================================
(() => {
  "use strict";

  const App = window.StageLinkApp;
  const Data = window.StageLinkProducer;

  const $ = (selector, root = document) => root.querySelector(selector);
  const $$ = (selector, root = document) => Array.from(root.querySelectorAll(selector));

  const roleGuard = $("#subscription-role-guard");
  const activePanel = $("#subscription-active");
  const flow = $("#subscription-flow");

  if (!App || !Data || !flow) {
    console.error("subscription.js: faltan app.js, producer-data.js o el HTML de subscription.jsp.");
    return;
  }

  const PROCESSING_MS = 2000;

  const CHECK_ICON =
    '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="m5 12 5 5 9-10"></path></svg>';

  // Estado del flujo
  let selectedPlan = null;
  let processingTimer = null;

  // Elementos del flujo
  const steps = $$(".form-step", flow);
  const stepperItems = $$(".stepper .step", flow);
  const planGrid = $("#plan-grid");
  const form = $("#payment-form");
  const payError = $("#pay-error");
  const paySubmit = $("#pay-submit");
  const fields = {
    name: $("#card-name"),
    number: $("#card-number"),
    expiry: $("#card-expiry"),
    cvc: $("#card-cvc"),
    email: $("#card-email")
  };

  // ---------------------------------------------------------------------
  // Utilidades
  // ---------------------------------------------------------------------
  function setText(selector, value) {
    const element = $(selector);
    if (element) element.textContent = value;
  }

  function periodLabel(plan) {
    return plan.months === 1 ? "1 mes" : `${plan.months} meses`;
  }

  // ---------------------------------------------------------------------
  // Pasos
  // ---------------------------------------------------------------------
  function showStep(index, moveFocus = true) {
    steps.forEach((step, i) => {
      step.hidden = i !== index;
    });

    stepperItems.forEach((item, i) => {
      item.classList.toggle("is-active", i === index);
      item.classList.toggle("is-complete", i < index);
      if (i === index) item.setAttribute("aria-current", "step");
      else item.removeAttribute("aria-current");
    });

    if (moveFocus) {
      const heading = $("h2", steps[index]);
      if (heading) {
        heading.setAttribute("tabindex", "-1");
        heading.focus({ preventScroll: true });
      }
      window.scrollTo({ top: 0, behavior: "smooth" });
    }
  }

  // ---------------------------------------------------------------------
  // Paso 1: planes
  // ---------------------------------------------------------------------
  function renderPlans() {
    const plans = Data.getPlans();
    planGrid.innerHTML = plans.map((plan) => {
      const features = plan.features
        .map((feature) => `<li>${CHECK_ICON}<span>${App.escapeHtml(feature)}</span></li>`)
        .join("");
      return `
        <article class="plan-card" data-plan-id="${App.escapeHtml(plan.id)}">
          ${plan.highlight ? '<span class="plan-ribbon">Más popular</span>' : ""}
          <h3 class="plan-name">${App.escapeHtml(plan.name)}</h3>
          <p class="plan-price"><strong>${App.escapeHtml(Data.formatPrice(plan.price))}</strong><span>${App.escapeHtml(plan.period)}</span></p>
          <ul class="plan-features">${features}</ul>
          <button class="button ${plan.highlight ? "" : "secondary"}" type="button" data-select-plan="${App.escapeHtml(plan.id)}">Elegir ${App.escapeHtml(plan.name)}</button>
        </article>`;
    }).join("");
  }

  function selectPlan(planId) {
    const plan = Data.getPlan(planId);
    if (!plan) return;
    selectedPlan = plan;

    $$(".plan-card", planGrid).forEach((card) => {
      card.classList.toggle("is-selected", card.dataset.planId === plan.id);
    });

    setText("#summary-plan", plan.name);
    setText("#summary-period", periodLabel(plan));
    setText("#summary-price", Data.formatPrice(plan.price));
    setText("#summary-total", Data.formatPrice(plan.price));

    showStep(1);
  }

  // ---------------------------------------------------------------------
  // Paso 2: formato en vivo, vista previa y validación
  // ---------------------------------------------------------------------
  function digitsOnly(value) {
    return String(value || "").replace(/\D/g, "");
  }

  function formatCardNumber(value) {
    return digitsOnly(value).slice(0, 16).replace(/(.{4})/g, "$1 ").trim();
  }

  function formatExpiry(value) {
    const digits = digitsOnly(value).slice(0, 4);
    return digits.length >= 3 ? `${digits.slice(0, 2)}/${digits.slice(2)}` : digits;
  }

  function updatePreview() {
    const number = digitsOnly(fields.number.value).padEnd(16, "•");
    setText("#preview-number", number.replace(/(.{4})/g, "$1 ").trim());
    setText("#preview-name", fields.name.value.trim().toUpperCase() || "NOMBRE APELLIDO");
    setText("#preview-expiry", fields.expiry.value || "MM/AA");
  }

  function showPayError(message, field) {
    payError.textContent = message;
    payError.hidden = false;
    Object.values(fields).forEach((input) => input.removeAttribute("aria-invalid"));
    if (field) {
      field.setAttribute("aria-invalid", "true");
      field.focus();
    }
  }

  function clearPayError() {
    payError.hidden = true;
    payError.textContent = "";
    Object.values(fields).forEach((input) => input.removeAttribute("aria-invalid"));
  }

  // Devuelve null si todo es válido, o { message, field } con el primer problema
  function validatePayment() {
    if (fields.name.value.trim().length < 3) {
      return { message: "Escribe el nombre del titular tal como aparece en la tarjeta.", field: fields.name };
    }

    if (digitsOnly(fields.number.value).length !== 16) {
      return { message: "El número de tarjeta debe tener 16 dígitos.", field: fields.number };
    }

    const expiry = /^(\d{2})\/(\d{2})$/.exec(fields.expiry.value);
    if (!expiry) {
      return { message: "Escribe el vencimiento con el formato MM/AA.", field: fields.expiry };
    }
    const month = Number(expiry[1]);
    const year = 2000 + Number(expiry[2]);
    if (month < 1 || month > 12) {
      return { message: "El mes de vencimiento debe estar entre 01 y 12.", field: fields.expiry };
    }
    // Una tarjeta es válida hasta el último instante del mes de vencimiento
    const endOfMonth = new Date(year, month, 1);
    if (endOfMonth.getTime() <= Date.now()) {
      return { message: "La tarjeta está vencida. Usa una fecha futura.", field: fields.expiry };
    }

    const cvc = digitsOnly(fields.cvc.value);
    if (cvc.length < 3 || cvc.length > 4) {
      return { message: "El CVC debe tener 3 o 4 dígitos.", field: fields.cvc };
    }

    if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(fields.email.value.trim())) {
      return { message: "Escribe un correo válido para el recibo.", field: fields.email };
    }

    return null;
  }

  function resetPaymentForm() {
    form.reset();
    updatePreview();
    clearPayError();
  }

  // ---------------------------------------------------------------------
  // Paso 3: procesamiento simulado y recibo
  // ---------------------------------------------------------------------
  function showReceipt(subscription) {
    setText("#receipt-plan", subscription.planName);
    setText("#receipt-amount", Data.formatPrice(subscription.price));
    setText("#receipt-card", `•••• ${subscription.last4}`);
    setText("#receipt-ref", subscription.reference);
    setText("#receipt-renews", Data.formatDate(subscription.renewsAt));

    $("#pay-processing").hidden = true;
    $("#pay-success").hidden = false;

    const heading = $("#pay-success h2");
    if (heading) {
      heading.setAttribute("tabindex", "-1");
      heading.focus({ preventScroll: true });
    }
  }

  function startPayment() {
    // Solo se conservan los últimos 4 dígitos; el resto se descarta
    const last4 = digitsOnly(fields.number.value).slice(-4);
    const planId = selectedPlan.id;

    $("#pay-processing").hidden = false;
    $("#pay-success").hidden = true;
    paySubmit.disabled = true;
    showStep(2);

    // Limpiamos el formulario de inmediato: ya no hace falta conservar nada
    resetPaymentForm();

    processingTimer = window.setTimeout(() => {
      const subscription = Data.activateSubscription(planId, { last4 });
      paySubmit.disabled = false;
      if (subscription) {
        showReceipt(subscription);
      } else {
        // Caso improbable: el plan ya no existe. Volvemos a la selección.
        showStep(0);
      }
    }, PROCESSING_MS);
  }

  // ---------------------------------------------------------------------
  // Eventos
  // ---------------------------------------------------------------------
  function bindEvents() {
    // Elegir plan (delegación de eventos sobre la cuadrícula)
    planGrid.addEventListener("click", (event) => {
      const button = event.target.closest("[data-select-plan]");
      if (button) selectPlan(button.dataset.selectPlan);
    });

    // Botón "Anterior"
    $$("[data-prev-step]", flow).forEach((button) => {
      button.addEventListener("click", () => showStep(0));
    });

    // Formato en vivo
    fields.number.addEventListener("input", () => {
      fields.number.value = formatCardNumber(fields.number.value);
      updatePreview();
    });
    fields.expiry.addEventListener("input", () => {
      fields.expiry.value = formatExpiry(fields.expiry.value);
      updatePreview();
    });
    fields.cvc.addEventListener("input", () => {
      fields.cvc.value = digitsOnly(fields.cvc.value).slice(0, 4);
    });
    fields.name.addEventListener("input", updatePreview);

    // Envío (nunca llega al servidor: el formulario no tiene "action")
    form.addEventListener("submit", (event) => {
      event.preventDefault();
      if (!selectedPlan) {
        showStep(0);
        return;
      }

      const problem = validatePayment();
      if (problem) {
        showPayError(problem.message, problem.field);
        return;
      }

      clearPayError();
      startPayment();
    });
  }

  // ---------------------------------------------------------------------
  // Arranque: decide qué panel se muestra
  // ---------------------------------------------------------------------
  function describeActiveSubscription() {
    const subscription = Data.getSubscription();
    if (!subscription) return;
    setText(
      "#active-summary",
      `${subscription.planName} activo. Se renueva el ${Data.formatDate(subscription.renewsAt)}. ` +
      `Tarjeta terminada en ${subscription.last4}.`
    );
  }

  function init() {
    if (App.getRole() !== "producer") {
      roleGuard.hidden = false;
      return;
    }

    if (Data.hasActiveSubscription()) {
      describeActiveSubscription();
      activePanel.hidden = false;
      return;
    }

    renderPlans();
    bindEvents();
    updatePreview();
    showStep(0, false);
    flow.hidden = false;
  }

  init();
})();
