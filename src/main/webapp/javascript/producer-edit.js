// =========================================================================
// StageLink · Editar convocatoria (rol de PRODUCTORA
// =========================================================================
(() => {
  "use strict";

  const App = window.StageLinkApp;
  const Data = window.StageLinkProducer;

  const $ = (selector, root = document) => root.querySelector(selector);
  const $$ = (selector, root = document) => Array.from(root.querySelectorAll(selector));

  const container = $("#edit-form-container");
  const form = $("#edit-audition-form");

  if (!App || !Data || !container || !form) {
    console.error("producer-edit.js: faltan app.js, producer-data.js o el HTML de edit-audition.jsp.");
    return;
  }

  const esc = App.escapeHtml;

  const roleGuard = $("#edit-role-guard");
  const notFound = $("#edit-not-found");
  const subtitle = $("#edit-subtitle");
  const statusBox = $("#edit-status");
  const message = $("#edit-message");
  const saveButton = $("#edit-save");
  const cancelLink = $("#edit-cancel");
  const roleList = $("#edit-role-list");
  const addRoleButton = $("#edit-add-role");

  const dialog = $("#role-dialog");
  const roleForm = $("#role-form");
  const roleTitle = $("#role-dialog-title");
  const roleError = $("#role-error");
  const RF = {
    name: $("#role-f-name"),
    profile: $("#role-f-profile"),
    age: $("#role-f-age"),
    gender: $("#role-f-gender"),
    description: $("#role-f-description"),
    requirement: $("#role-f-requirement")
  };

  const COMPENSATION_DEFAULTS = {
    "ad-honorem": "Proyecto ad honorem",
    experience: "Intercambio de experiencia"
  };

  // Estado de la pantalla
  let original = null;       // convocatoria tal como se cargó
  let roles = [];            // copia de trabajo de los roles
  let extraMaterials = [];   // materiales que no están entre los checkboxes
  let snapshot = "";         // estado inicial serializado, para detectar cambios
  let editingIndex = -1;     // -1 = agregando un rol nuevo
  let lastAutoCompensation = "";
  let saving = false;

  // ---------------------------------------------------------------------
  // Utilidades
  // ---------------------------------------------------------------------
  function getField(name) {
    return form.elements[name];
  }

  function fieldValue(name) {
    const field = getField(name);
    return field ? String(field.value || "").trim() : "";
  }

  function checkboxes() {
    return $$('input[name="materials"]', form);
  }

  function selectedMaterials() {
    const checked = checkboxes().filter((input) => input.checked).map((input) => input.value);
    return checked.concat(extraMaterials);
  }

  function todayISO() {
    const now = new Date();
    const month = String(now.getMonth() + 1).padStart(2, "0");
    const day = String(now.getDate()).padStart(2, "0");
    return `${now.getFullYear()}-${month}-${day}`;
  }

  function showMessage(text, field) {
    message.textContent = text;
    message.hidden = false;
    if (field) field.focus();
    message.scrollIntoView({ behavior: "smooth", block: "center" });
  }

  function clearMessage() {
    message.hidden = true;
    message.textContent = "";
  }

  // Estado actual del formulario como objeto (sirve para guardar y para detectar cambios)
  function collect() {
    return {
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
      roles: roles.map((role) => ({ ...role }))
    };
  }

  function isDirty() {
    return JSON.stringify(collect()) !== snapshot;
  }

  // ---------------------------------------------------------------------
  // Carga de datos en el formulario
  // ---------------------------------------------------------------------
  function setSelectValue(select, value) {
    if (!select) return;
    const exists = Array.from(select.options).some((option) => (option.value || option.text) === value);
    // Si el valor guardado no está entre las opciones, lo añadimos para no perderlo
    if (value && !exists) {
      const option = document.createElement("option");
      option.textContent = value;
      select.appendChild(option);
    }
    if (value) select.value = value;
  }

  function fillForm(audition) {
    getField("title").value = audition.title || "";
    setSelectValue(getField("type"), audition.type || "");
    getField("description").value = audition.description || "";
    getField("compensationType").value = audition.compensationType || "paid";
    getField("compensation").value = audition.compensation || "";
    getField("requirements").value = audition.requirements || "";
    getField("location").value = audition.location || "";
    getField("district").value = audition.district || "";
    getField("deadline").value = audition.deadline || "";
    getField("date").value = audition.date || "";
    getField("time").value = audition.time || "";

    const known = checkboxes().map((input) => input.value);
    const saved = Array.isArray(audition.materials) ? audition.materials : [];
    checkboxes().forEach((input) => {
      input.checked = saved.includes(input.value);
    });
    extraMaterials = saved.filter((item) => !known.includes(item));
  }

  function renderStatusBadge(audition) {
    const label = Data.AUDITION_STATUS[audition.status] || audition.status;
    statusBox.innerHTML = `<span class="badge aud-status-${esc(audition.status)}">${esc(label)}</span>`;
  }

  // ---------------------------------------------------------------------
  // Compensación
  // ---------------------------------------------------------------------
  // userChange = true cuando la persona cambia la modalidad (puede autocompletar).
  // Al cargar, solo se ajusta la etiqueta: nunca se modifica el valor guardado.
  function syncCompensation(userChange) {
    const type = fieldValue("compensationType");
    const input = getField("compensation");
    const label = $(".field-label", $("#edit-compensation-field"));
    const auto = COMPENSATION_DEFAULTS[type] || "";

    if (auto) {
      if (userChange && (!input.value.trim() || input.value === lastAutoCompensation)) input.value = auto;
      input.required = false;
      if (label) label.textContent = "Detalle de la compensación (opcional)";
    } else {
      if (userChange && input.value === lastAutoCompensation) input.value = "";
      input.required = true;
      if (label) label.textContent = "Detalle del pago";
    }
    lastAutoCompensation = auto;
  }

  // ---------------------------------------------------------------------
  // Roles
  // ---------------------------------------------------------------------
  function renderRoles() {
    if (roles.length === 0) {
      roleList.innerHTML = '<p class="form-note">Esta convocatoria no tiene roles. Agrega al menos uno.</p>';
      return;
    }

    roleList.innerHTML = roles.map((role, index) => {
      const summary = [role.profile, role.age, role.gender].filter(Boolean).join(" · ") || "Sin detalles";
      return `
        <article class="card edit-role">
          <div>
            <h3>${esc(role.name)}</h3>
            <p>${esc(summary)}</p>
          </div>
          <div class="edit-role-actions">
            <button class="button secondary small" type="button" data-edit-role="${index}" aria-label="Editar rol ${esc(role.name)}">Editar</button>
            <button class="button secondary small" type="button" data-remove-role="${index}" aria-label="Eliminar rol ${esc(role.name)}">Eliminar</button>
          </div>
        </article>`;
    }).join("");
  }

  function clearRoleError() {
    roleError.hidden = true;
    roleError.textContent = "";
  }

  function openRoleDialog(index) {
    editingIndex = index;
    clearRoleError();

    const role = index >= 0 ? roles[index] : {};
    roleTitle.textContent = index >= 0 ? "Editar rol" : "Agregar rol";
    RF.name.value = role.name || "";
    RF.profile.value = role.profile || "";
    RF.age.value = role.age || "";
    setSelectValue(RF.gender, role.gender || "");
    if (!role.gender) RF.gender.selectedIndex = 0;
    RF.description.value = role.description || "";
    RF.requirement.value = role.requirement || "";

    if (typeof dialog.showModal === "function") dialog.showModal();
    else dialog.setAttribute("open", "");
    document.body.classList.add("modal-open");
    RF.name.focus();
  }

  function closeRoleDialog() {
    if (typeof dialog.close === "function") dialog.close();
    else dialog.removeAttribute("open");
    document.body.classList.remove("modal-open");
  }

  function saveRole() {
    clearRoleError();
    const name = RF.name.value.trim();

    if (!name) {
      roleError.textContent = "El nombre del personaje es obligatorio.";
      roleError.hidden = false;
      RF.name.focus();
      return;
    }

    const data = {
      name,
      profile: RF.profile.value.trim(),
      age: RF.age.value.trim(),
      gender: RF.gender.value.trim(),
      description: RF.description.value.trim(),
      requirement: RF.requirement.value.trim()
    };

    if (editingIndex >= 0) {
      // Se conserva el id para que las postulaciones sigan asociadas al rol
      roles[editingIndex] = { ...roles[editingIndex], ...data };
    } else {
      roles.push(data);
    }

    closeRoleDialog();
    renderRoles();
    clearMessage();
  }

  function removeRole(index) {
    const role = roles[index];
    if (!role) return;

    let text = `¿Eliminar el rol «${role.name}»?`;
    if (role.id) {
      const applicants = Data.getCandidates(original.id).filter((candidate) => candidate.roleId === role.id).length;
      if (applicants > 0) {
        text += `\n\nEste rol tiene ${applicants} ${applicants === 1 ? "postulación" : "postulaciones"} que quedará${applicants === 1 ? "" : "n"} sin rol asignado.`;
      }
    }
    if (!window.confirm(text)) return;

    roles.splice(index, 1);
    renderRoles();
  }

  // ---------------------------------------------------------------------
  // Validación y guardado
  // ---------------------------------------------------------------------
  function validate() {
    clearMessage();

    // 1) Campos obligatorios con el aviso nativo del navegador
    for (const control of $$("input, select, textarea", form)) {
      if (!control.checkValidity()) {
        control.reportValidity();
        return false;
      }
    }

    // 2) Fechas coherentes
    const deadline = fieldValue("deadline");
    const auditionDate = fieldValue("date");

    // La fecha límite solo se exige futura si la persona la cambió
    if (deadline !== (original.deadline || "") && deadline < todayISO()) {
      showMessage("La fecha límite para postularse no puede estar en el pasado.", getField("deadline"));
      return false;
    }
    if (auditionDate < deadline) {
      showMessage("La fecha de audición debe ser igual o posterior a la fecha límite de postulación.", getField("date"));
      return false;
    }

    // 3) Al menos un rol
    if (roles.length === 0) {
      showMessage("La convocatoria debe tener al menos un rol.", addRoleButton);
      return false;
    }

    return true;
  }

  function save() {
    if (saving) return;
    if (!validate()) return;

    saving = true;
    saveButton.disabled = true;
    saveButton.textContent = "Guardando…";

    // No se envía "status": la edición conserva el estado actual de la convocatoria
    Data.saveAudition({ ...collect(), id: original.id });

    window.location.href = `dashboard.jsp?audition=${encodeURIComponent(original.id)}`;
  }

  // ---------------------------------------------------------------------
  // Eventos
  // ---------------------------------------------------------------------
  function bindEvents() {
    form.addEventListener("submit", (event) => {
      event.preventDefault();
      save();
    });

    getField("compensationType").addEventListener("change", () => syncCompensation(true));

    // Cancelar: confirma solo si hubo cambios
    cancelLink.addEventListener("click", (event) => {
      if (isDirty() && !window.confirm("¿Salir sin guardar? Se perderán los cambios que hiciste.")) {
        event.preventDefault();
      }
    });

    // Roles
    addRoleButton.addEventListener("click", () => openRoleDialog(-1));
    roleList.addEventListener("click", (event) => {
      const edit = event.target.closest("[data-edit-role]");
      if (edit) {
        openRoleDialog(Number(edit.dataset.editRole));
        return;
      }
      const remove = event.target.closest("[data-remove-role]");
      if (remove) removeRole(Number(remove.dataset.removeRole));
    });

    // Diálogo del rol
    roleForm.addEventListener("submit", (event) => {
      event.preventDefault();
      saveRole();
    });
    $$("[data-close-role-dialog]", dialog).forEach((button) => {
      button.addEventListener("click", closeRoleDialog);
    });
    dialog.addEventListener("click", (event) => {
      if (event.target === dialog) closeRoleDialog();
    });
    // También cubre la tecla Esc
    dialog.addEventListener("close", () => {
      document.body.classList.remove("modal-open");
    });
  }

  // ---------------------------------------------------------------------
  // Arranque
  // ---------------------------------------------------------------------
  function init() {
    if (App.getRole() !== "producer") {
      roleGuard.hidden = false;
      return;
    }

    const id = new URLSearchParams(window.location.search).get("id");
    const audition = id ? Data.getAudition(id) : null;

    if (!audition) {
      notFound.hidden = false;
      return;
    }

    original = audition;
    roles = (audition.roles || []).map((role) => ({ ...role }));

    subtitle.textContent = `Editando «${audition.title}». Los cambios no se guardan hasta que pulses «Guardar cambios».`;
    renderStatusBadge(audition);
    fillForm(audition);
    syncCompensation(false);
    renderRoles();
    bindEvents();

    snapshot = JSON.stringify(collect());
    container.hidden = false;
  }

  init();
})();
