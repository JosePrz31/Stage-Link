// =========================================================================
// StageLink · Crear convocatoria (rol de PRODUCTORA)
// -------------------------------------------------------------------------
// Requiere (en este orden): app.js -> producer-data.js -> producer-create.js
// =========================================================================
(() => {
  "use strict";

  const App = window.StageLinkApp;
  const Data = window.StageLinkProducer;

  const $ = (selector, root = document) => root.querySelector(selector);
  const $$ = (selector, root = document) => Array.from(root.querySelectorAll(selector));

  const container = $("#create-form-container");
  const form = $("#create-audition-form");
  const roleGuard = $("#create-role-guard");
  const subGuard = $("#create-sub-guard");
  const subStatus = $("#create-sub-status");

  if (!App || !Data || !container || !form) {
    console.error("producer-create.js: faltan app.js, producer-data.js o el HTML de create-audition.jsp.");
    return;
  }

  const esc = App.escapeHtml;

  const steps = $$(".form-step", form);
  const stepperItems = $$(".stepper .step", container);
  const lastStep = steps.length - 1;

  const draftList = $("#draft-role-list");
  const reviewBox = $("#audition-review");
  const addRoleButton = $("#add-role");

  const ROLE_FIELDS = {
    name: form.elements.roleName,
    profile: form.elements.roleProfile,
    age: form.elements.roleAge,
    gender: form.elements.roleGender,
    description: form.elements.roleDescription,
    requirement: form.elements.roleRequirement
  };

  const COMPENSATION_DEFAULTS = {
    "ad-honorem": "Proyecto ad honorem",
    experience: "Intercambio de experiencia"
  };

  let currentStep = 0;
  let roles = [];
  let lastAutoCompensation = "";
  let publishing = false;

  // ---------------------------------------------------------------------
  // Utilidades
  // ---------------------------------------------------------------------
  function todayISO() {
    const now = new Date();
    const month = String(now.getMonth() + 1).padStart(2, "0");
    const day = String(now.getDate()).padStart(2, "0");
    return `${now.getFullYear()}-${month}-${day}`;
  }

  function getField(name) {
    return form.elements[name];
  }

  function fieldValue(name) {
    const field = getField(name);
    return field ? String(field.value || "").trim() : "";
  }

  function selectedMaterials() {
    return $$('input[name="materials"]:checked', form).map((input) => input.value);
  }

  // Crea (o reutiliza) un mensaje de error dentro de un paso
  function showStepMessage(stepIndex, message) {
    const step = steps[stepIndex];
    let box = $(".step-message", step);
    if (!box) {
      box = document.createElement("div");
      box.className = "auth-message step-message";
      box.dataset.type = "error";
      box.setAttribute("role", "alert");
      box.style.marginBottom = "16px";
      const body = $(".surface-body", step);
      body.insertBefore(box, body.firstChild);
    }
    box.textContent = message;
    box.hidden = false;
  }

  function clearStepMessage(stepIndex) {
    const box = $(".step-message", steps[stepIndex]);
    if (box) {
      box.hidden = true;
      box.textContent = "";
    }
  }

  function roleDraftHasContent() {
    return Object.values(ROLE_FIELDS).some((field, index) => {
      // El género tiene un valor por defecto; no cuenta como "contenido"
      if (field === ROLE_FIELDS.gender) return false;
      return Boolean(field && String(field.value || "").trim());
    });
  }

  function formIsDirty() {
    const watched = ["title", "description", "compensation", "requirements", "location", "district"];
    return roles.length > 0 || watched.some((name) => fieldValue(name)) || roleDraftHasContent();
  }

  // ---------------------------------------------------------------------
  // Navegación entre pasos
  // ---------------------------------------------------------------------
  function showStep(index, moveFocus = true) {
    currentStep = index;

    steps.forEach((step, i) => {
      step.hidden = i !== index;
    });

    stepperItems.forEach((item, i) => {
      item.classList.toggle("is-active", i === index);
      item.classList.toggle("is-complete", i < index);
      if (i === index) item.setAttribute("aria-current", "step");
      else item.removeAttribute("aria-current");
    });

    if (index === lastStep) renderReview();

    if (moveFocus) {
      const heading = $("h2", steps[index]);
      if (heading) {
        heading.setAttribute("tabindex", "-1");
        heading.focus({ preventScroll: true });
      }
      window.scrollTo({ top: 0, behavior: "smooth" });
    }
  }

  // Valida el paso actual. Devuelve true si se puede avanzar.
  function validateStep(index) {
    clearStepMessage(index);
    const step = steps[index];

    // 1) Campos obligatorios con el aviso nativo del navegador
    const controls = $$("input, select, textarea", step);
    for (const control of controls) {
      if (!control.checkValidity()) {
        control.reportValidity();
        return false;
      }
    }

    // 2) Reglas propias de cada paso
    if (index === 1) {
      const deadline = fieldValue("deadline");
      const auditionDate = fieldValue("date");
      if (deadline < todayISO()) {
        showStepMessage(index, "La fecha límite para postularse no puede estar en el pasado.");
        getField("deadline").focus();
        return false;
      }
      if (auditionDate < deadline) {
        showStepMessage(index, "La fecha de audición debe ser igual o posterior a la fecha límite de postulación.");
        getField("date").focus();
        return false;
      }
    }

    if (index === 2) {
      if (roleDraftHasContent()) {
        showStepMessage(index, "Tienes un rol sin agregar. Pulsa «Agregar rol» para guardarlo o borra sus campos.");
        addRoleButton.focus();
        return false;
      }
      if (roles.length === 0) {
        showStepMessage(index, "Agrega al menos un rol antes de revisar la convocatoria.");
        ROLE_FIELDS.name.focus();
        return false;
      }
    }

    return true;
  }

  function goNext() {
    if (!validateStep(currentStep)) return;
    if (currentStep < lastStep) showStep(currentStep + 1);
  }

  function goPrev() {
    if (currentStep > 0) showStep(currentStep - 1);
  }

  // ---------------------------------------------------------------------
  // Constructor de roles
  // ---------------------------------------------------------------------
  function renderRoles() {
    if (roles.length === 0) {
      draftList.innerHTML = '<p class="form-note">Aún no has agregado roles. Agrega al menos uno.</p>';
      return;
    }

    draftList.innerHTML = roles.map((role, index) => `
      <article class="card draft-role">
        <div>
          <h3>${esc(role.name)}</h3>
          <p>${esc([role.profile, role.age, role.gender].filter(Boolean).join(" · ") || "Sin detalles")}</p>
        </div>
        <button class="button secondary small" type="button" data-remove-role="${index}" aria-label="Eliminar rol ${esc(role.name)}">Eliminar</button>
      </article>`).join("");
  }

  function clearRoleFields() {
    Object.entries(ROLE_FIELDS).forEach(([key, field]) => {
      if (!field) return;
      field.value = key === "gender" ? field.options[0].value : "";
    });
  }

  function addRole() {
    clearStepMessage(2);
    const name = String(ROLE_FIELDS.name.value || "").trim();

    if (!name) {
      showStepMessage(2, "El nombre del personaje es obligatorio para agregar un rol.");
      ROLE_FIELDS.name.focus();
      return;
    }

    roles.push({
      name,
      profile: String(ROLE_FIELDS.profile.value || "").trim(),
      age: String(ROLE_FIELDS.age.value || "").trim(),
      gender: String(ROLE_FIELDS.gender.value || "").trim(),
      description: String(ROLE_FIELDS.description.value || "").trim(),
      requirement: String(ROLE_FIELDS.requirement.value || "").trim()
    });

    clearRoleFields();
    renderRoles();
    ROLE_FIELDS.name.focus();
  }

  function removeRole(index) {
    roles.splice(index, 1);
    renderRoles();
  }

  // ---------------------------------------------------------------------
  // Compensación: autocompleta el detalle si no es remunerado
  // ---------------------------------------------------------------------
  function syncCompensation() {
    const type = fieldValue("compensationType");
    const input = getField("compensation");
    const label = $(".field-label", $("#compensation-field"));
    const auto = COMPENSATION_DEFAULTS[type] || "";

    if (auto) {
      // Solo reemplazamos si está vacío o si el valor era el autocompletado anterior
      if (!input.value.trim() || input.value === lastAutoCompensation) input.value = auto;
      input.required = false;
      if (label) label.textContent = "Detalle de la compensación (opcional)";
    } else {
      if (input.value === lastAutoCompensation) input.value = "";
      input.required = true;
      if (label) label.textContent = "Detalle del pago";
    }
    lastAutoCompensation = auto;
  }

  // ---------------------------------------------------------------------
  // Revisión
  // ---------------------------------------------------------------------
  function reviewItem(label, value) {
    return `<div class="review-item"><small>${esc(label)}</small><strong>${esc(value || "Sin definir")}</strong></div>`;
  }

  function renderReview() {
    const requirements = Data.parseRequirements(fieldValue("requirements"));
    const materials = selectedMaterials();
    const compensationLabel = Data.COMPENSATION[fieldValue("compensationType")] || "";
    const compensationDetail = fieldValue("compensation");

    const rolesHtml = roles.map((role) => `
      <li><strong>${esc(role.name)}</strong>${
        [role.profile, role.age, role.gender].filter(Boolean).length
          ? ` — ${esc([role.profile, role.age, role.gender].filter(Boolean).join(" · "))}`
          : ""
      }</li>`).join("");

    reviewBox.innerHTML = `
      <div class="review-grid">
        ${reviewItem("Proyecto", fieldValue("title"))}
        ${reviewItem("Tipo", fieldValue("type"))}
        ${reviewItem("Compensación", compensationDetail ? `${compensationLabel} · ${compensationDetail}` : compensationLabel)}
        ${reviewItem("Lugar", `${fieldValue("location")}, ${fieldValue("district")}`)}
        ${reviewItem("Fecha límite de postulación", Data.formatDate(fieldValue("deadline")))}
        ${reviewItem("Fecha y hora de audición", `${Data.formatDate(fieldValue("date"))} · ${fieldValue("time")}`)}
      </div>
      <div class="detail-section" style="margin-top: 18px">
        <h3>Descripción</h3>
        <p>${esc(fieldValue("description"))}</p>
      </div>
      <div class="detail-section" style="margin-top: 18px">
        <h3>Requisitos generales</h3>
        <ul class="detail-list">${requirements.map((item) => `<li>${esc(item)}</li>`).join("")}</ul>
      </div>
      <div class="detail-section" style="margin-top: 18px">
        <h3>Material solicitado</h3>
        <p>${esc(materials.length ? materials.join(", ") : "Ninguno")}</p>
      </div>
      <div class="detail-section" style="margin-top: 18px">
        <h3>Roles (${roles.length})</h3>
        <ul class="detail-list">${rolesHtml}</ul>
      </div>`;
  }

  function publish() {
    if (publishing) return;

    // Revalidamos todos los pasos por si se editó algo al retroceder
    for (let i = 0; i < lastStep; i += 1) {
      showStep(i, false);
      if (!validateStep(i)) {
        steps[i].scrollIntoView({ behavior: "smooth", block: "start" });
        return;
      }
    }
    showStep(lastStep, false);

    publishing = true;
    const submitButton = $('button[type="submit"]', steps[lastStep]);
    if (submitButton) {
      submitButton.disabled = true;
      submitButton.textContent = "Publicando…";
    }

    Data.saveAudition({
      title: fieldValue("title"),
      type: fieldValue("type"),
      description: fieldValue("description"),
      compensationType: fieldValue("compensationType"),
      compensation: fieldValue("compensation"),
      requirements: fieldValue("requirements"),
      location: fieldValue("location"),
      district: fieldValue("district"),
      deadline: fieldValue("deadline"),
      date: fieldValue("date"),
      time: fieldValue("time"),
      materials: selectedMaterials(),
      roles,
      status: "published"
    });

    window.location.href = "dashboard.jsp";
  }

  // ---------------------------------------------------------------------
  // Eventos
  // ---------------------------------------------------------------------
  function bindEvents() {
    $$("[data-next-step]", form).forEach((button) => button.addEventListener("click", goNext));
    $$("[data-prev-step]", form).forEach((button) => button.addEventListener("click", goPrev));

    addRoleButton.addEventListener("click", addRole);

    ROLE_FIELDS.name.addEventListener("keydown", (event) => {
      if (event.key === "Enter") {
        event.preventDefault();
        addRole();
      }
    });

    draftList.addEventListener("click", (event) => {
      const button = event.target.closest("[data-remove-role]");
      if (button) removeRole(Number(button.dataset.removeRole));
    });

    getField("compensationType").addEventListener("change", syncCompensation);

    $$('.form-actions a[href="feed.jsp"]', form).forEach((link) => {
      link.addEventListener("click", (event) => {
        if (formIsDirty() && !window.confirm("¿Cancelar la creación? Se perderá la información que escribiste.")) {
          event.preventDefault();
        }
      });
    });

    form.addEventListener("submit", (event) => {
      event.preventDefault();
      if (currentStep < lastStep) {
        goNext();
        return;
      }
      publish();
    });
  }

  function renderSubscriptionBadge() {
    const subscription = Data.getSubscription();
    const planName = subscription ? subscription.planName : "";
    subStatus.innerHTML = `
      <span class="sub-badge">
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="m5 12 5 5 9-10"></path></svg>
        Suscripción activa${planName ? ` · ${esc(planName)}` : ""}
      </span>`;
  }

  function init() {
    if (App.getRole() !== "producer") {
      container.hidden = true;
      roleGuard.hidden = false;
      return;
    }

    if (!Data.hasActiveSubscription()) {
      container.hidden = true;
      subGuard.hidden = false;
      return;
    }

    renderSubscriptionBadge();
    renderRoles();
    syncCompensation();
    bindEvents();
    showStep(0, false);
  }

  init();
})();
