// =========================================================================
// StageLink · Gestión de talento
// -------------------------------------------------------------------------
// Requiere (en este orden): app.js -> producer-data.js -> producer-dashboard.js
// Caso de uso: CU-10 (Gestionar postulaciones) y lista "Mis convocatorias".
// Si la cuenta es de Artista, este script no modifica la página.
// =========================================================================
(() => {
  "use strict";

  const App = window.StageLinkApp;
  const Data = window.StageLinkProducer;

  const $ = (selector, root = document) => root.querySelector(selector);

  const producerView = $("#producer-dashboard");
  const actorView = $("#actor-dashboard");

  if (!App || !Data || !producerView) {
    console.error("producer-dashboard.js: faltan app.js, producer-data.js o el HTML de dashboard.jsp.");
    return;
  }

  // Un Artista conserva su vista tal como está
  if (App.getRole() !== "producer") return;

  const esc = App.escapeHtml;

  const notice = $("#producer-sub-notice");
  const auditionList = $("#management-list");
  const auditionSelect = $("#managed-audition");
  const statsBox = $("#candidate-stats");
  const filtersBox = $("#cand-filters");
  const candidateList = $("#candidate-list");

  const dialog = $("#candidate-dialog");
  const dialogSub = $("#candidate-dialog-sub");
  const dialogBody = $("#candidate-dialog-body");
  const dialogSave = $("#candidate-save-note");

  const FILTERS = [
    ["all", "Todas"],
    ["pending", "Pendiente"],
    ["shortlisted", "En preselección"],
    ["accepted", "Aceptada"],
    ["rejected", "Rechazada"]
  ];

  const MATERIAL_ICONS = {
    image: '<rect x="3" y="4" width="18" height="16" rx="2"></rect><circle cx="9" cy="10" r="2"></circle><path d="m21 16-5-5-8 9"></path>',
    video: '<rect x="3" y="5" width="18" height="14" rx="2"></rect><path d="m10 9 5 3-5 3V9Z"></path>',
    document: '<path d="M6 3h9l4 4v14H6V3Z"></path><path d="M14 3v5h5M9 13h6M9 17h6"></path>'
  };

  // Estado de la pantalla
  let selectedId = null;
  let statusFilter = "all";
  let dialogCandidateId = null;
  let dialogRating = 0;

  // ---------------------------------------------------------------------
  // Utilidades
  // ---------------------------------------------------------------------
  function initials(name) {
    return String(name || "SL")
      .trim()
      .split(/\s+/)
      .slice(0, 2)
      .map((word) => word[0] || "")
      .join("")
      .toUpperCase();
  }

  function starsText(rating) {
    const value = Math.max(0, Math.min(5, Number(rating) || 0));
    return "★".repeat(value) + "☆".repeat(5 - value);
  }

  function roleNameOf(audition, roleId) {
    const role = audition && audition.roles.find((item) => item.id === roleId);
    return role ? role.name : "Rol sin especificar";
  }

  function emptyState(title, text) {
    return `
      <div class="empty-state card">
        <div class="empty-state-inner">
          <h3>${esc(title)}</h3>
          <p>${esc(text)}</p>
        </div>
      </div>`;
  }

  // ---------------------------------------------------------------------
  // Aviso de suscripción
  // ---------------------------------------------------------------------
  function renderSubscriptionNotice() {
    if (Data.hasActiveSubscription()) {
      notice.hidden = true;
      return;
    }
    notice.dataset.type = "info";
    notice.removeAttribute("role");
    notice.innerHTML =
      'Aún no tienes una suscripción activa. Puedes gestionar postulaciones, pero necesitas ' +
      'suscribirte para publicar convocatorias. <a href="subscription.jsp"><strong>Ver planes</strong></a>';
    notice.hidden = false;
  }

  function showSubscriptionRequired() {
    notice.dataset.type = "error";
    notice.setAttribute("role", "alert");
    notice.innerHTML =
      'Necesitas una suscripción activa para publicar o reabrir convocatorias. ' +
      '<a href="subscription.jsp"><strong>Ver planes y suscribirme</strong></a>';
    notice.hidden = false;
    notice.scrollIntoView({ behavior: "smooth", block: "center" });
  }

  // ---------------------------------------------------------------------
  // Mis convocatorias
  // ---------------------------------------------------------------------
  function statusAction(audition) {
    if (audition.status === "draft") return { next: "published", label: "Publicar" };
    if (audition.status === "published") return { next: "closed", label: "Cerrar" };
    return { next: "published", label: "Reabrir" };
  }

  function renderAuditions() {
    const auditions = Data.getAuditions();

    if (auditions.length === 0) {
      auditionList.innerHTML = emptyState(
        "Aún no tienes convocatorias",
        "Cuando publiques una, aparecerá aquí con sus postulaciones."
      ) + '<a class="button" href="create-audition.jsp" style="margin-top:12px">Crear convocatoria</a>';
      return;
    }

    auditionList.innerHTML = auditions.map((audition) => {
      const total = Data.getCandidateStats(audition.id).total;
      const action = statusAction(audition);
      const selected = audition.id === selectedId;
      return `
        <article class="card management-card${selected ? " is-selected" : ""}" data-audition-id="${esc(audition.id)}">
          <div>
            <h3>${esc(audition.title)}</h3>
            <p>${esc(audition.type)} · Audición: ${esc(Data.formatDate(audition.date))}</p>
            <div class="management-meta">
              <span class="badge aud-status-${esc(audition.status)}">${esc(Data.AUDITION_STATUS[audition.status] || audition.status)}</span>
              <span class="badge">${total} ${total === 1 ? "postulación" : "postulaciones"}</span>
              <span class="badge">${audition.roles.length} ${audition.roles.length === 1 ? "rol" : "roles"}</span>
            </div>
            <div class="management-card-actions" style="margin-top: 12px">
              <button class="button small" type="button" data-select-audition="${esc(audition.id)}">Ver candidatos</button>
              <a class="button secondary small" href="edit-audition.jsp?id=${encodeURIComponent(audition.id)}">Editar</a>
              <button class="button secondary small" type="button" data-audition-status="${esc(audition.id)}" data-next-status="${esc(action.next)}">${esc(action.label)}</button>
            </div>
          </div>
        </article>`;
    }).join("");
  }

  function renderAuditionSelect() {
    const auditions = Data.getAuditions();
    auditionSelect.innerHTML = auditions.map((audition) => {
      const total = Data.getCandidateStats(audition.id).total;
      return `<option value="${esc(audition.id)}"${audition.id === selectedId ? " selected" : ""}>${esc(audition.title)} (${total})</option>`;
    }).join("");
    auditionSelect.disabled = auditions.length === 0;
  }

  // ---------------------------------------------------------------------
  // Estadísticas, filtros y candidatos
  // ---------------------------------------------------------------------
  function renderStats() {
    const stats = Data.getCandidateStats(selectedId);
    const items = [
      ["Postulaciones", stats.total],
      ["Pendientes", stats.pending],
      ["En preselección", stats.shortlisted],
      ["Aceptadas", stats.accepted],
      ["Rechazadas", stats.rejected]
    ];
    statsBox.innerHTML = items.map(([label, value]) => `
      <div class="card stat-card"><strong>${value}</strong><span>${esc(label)}</span></div>`).join("");
  }

  function renderFilters() {
    const stats = Data.getCandidateStats(selectedId);
    filtersBox.innerHTML = FILTERS.map(([key, label]) => {
      const count = key === "all" ? stats.total : stats[key];
      return `<button class="cand-filter" type="button" data-filter="${key}" aria-pressed="${statusFilter === key}">${esc(label)} (${count})</button>`;
    }).join("");
  }

  function renderCandidates() {
    if (!selectedId) {
      candidateList.innerHTML = emptyState("Sin convocatoria seleccionada", "Crea o selecciona una convocatoria para ver sus candidatos.");
      return;
    }

    const audition = Data.getAudition(selectedId);
    let candidates = Data.getCandidates(selectedId);

    if (candidates.length === 0) {
      candidateList.innerHTML = emptyState("Aún no hay postulaciones", "Cuando los artistas se postulen a esta convocatoria, aparecerán aquí.");
      return;
    }

    if (statusFilter !== "all") {
      candidates = candidates.filter((candidate) => candidate.status === statusFilter);
    }

    if (candidates.length === 0) {
      candidateList.innerHTML = emptyState("Sin resultados", "Ninguna postulación tiene este estado. Prueba con otro filtro.");
      return;
    }

    candidateList.innerHTML = candidates.map((candidate) => {
      const options = Object.entries(Data.APPLICATION_STATUS).map(([value, label]) =>
        `<option value="${esc(value)}"${value === candidate.status ? " selected" : ""}>${esc(label)}</option>`
      ).join("");

      const ratingLabel = candidate.rating
        ? `Calificación: ${candidate.rating} de 5`
        : "Sin calificar";

      return `
        <article class="card candidate-card" data-candidate-id="${esc(candidate.id)}">
          <span class="avatar" aria-hidden="true">${esc(initials(candidate.name))}</span>
          <div>
            <h3>${esc(candidate.name)}</h3>
            <p>${esc(candidate.city)} · ${esc(candidate.age)} años · ${esc(roleNameOf(audition, candidate.roleId))}</p>
            <div class="cand-tags">
              <span class="badge cand-status-${esc(candidate.status)}">${esc(Data.APPLICATION_STATUS[candidate.status] || candidate.status)}</span>
              <span class="badge">Postulado: ${esc(Data.formatDate(candidate.appliedAt))}</span>
              <span class="badge" aria-label="${esc(ratingLabel)}">${candidate.rating ? esc(starsText(candidate.rating)) : "Sin calificar"}</span>
            </div>
            ${candidate.note ? `<p style="margin-top: 8px"><strong>Nota privada:</strong> ${esc(candidate.note)}</p>` : ""}
          </div>
          <div class="candidate-actions">
            <label class="sr-only" for="status-${esc(candidate.id)}">Estado de la postulación de ${esc(candidate.name)}</label>
            <select class="select status-select" id="status-${esc(candidate.id)}" data-status-for="${esc(candidate.id)}">${options}</select>
            <button class="button secondary small" type="button" data-view-candidate="${esc(candidate.id)}">Ver perfil</button>
          </div>
        </article>`;
    }).join("");
  }

  // Redibuja lo que depende de los candidatos y la convocatoria seleccionada
  function renderAll() {
    renderAuditions();
    renderAuditionSelect();
    renderStats();
    renderFilters();
    renderCandidates();
  }

  function selectAudition(id) {
    selectedId = id;
    statusFilter = "all";
    renderAll();
  }

  function paintRating() {
    $$stars().forEach((button) => {
      button.classList.toggle("is-active", Number(button.dataset.star) <= dialogRating);
      button.setAttribute("aria-pressed", String(Number(button.dataset.star) <= dialogRating));
    });
  }

  function $$stars() {
    return Array.from(dialogBody.querySelectorAll("[data-star]"));
  }

  function openCandidate(id) {
    const candidate = Data.getCandidate(id);
    if (!candidate) return;
    const audition = Data.getAudition(candidate.auditionId);

    dialogCandidateId = id;
    dialogRating = candidate.rating || 0;

    dialogSub.textContent = `${roleNameOf(audition, candidate.roleId)} · ${audition ? audition.title : ""}`;

    const facts = [
      ["Edad", `${candidate.age} años`],
      ["Estatura", candidate.height],
      ["Género", candidate.gender],
      ["Idiomas", candidate.languages],
      ["Postulación", Data.formatDate(candidate.appliedAt)],
      ["Estado", Data.APPLICATION_STATUS[candidate.status] || candidate.status]
    ].map(([label, value]) => `
      <div class="cand-fact"><small>${esc(label)}</small><strong>${esc(value || "Sin definir")}</strong></div>`).join("");

    const skills = (candidate.skills || []).map((skill) => `<span class="badge">${esc(skill)}</span>`).join("");

    const materials = (candidate.materials || []).map((material) => `
      <span class="material-chip">
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">${MATERIAL_ICONS[material.type] || MATERIAL_ICONS.document}</svg>
        ${esc(material.name)}
      </span>`).join("");

    const stars = [1, 2, 3, 4, 5].map((n) =>
      `<button class="star-button" type="button" data-star="${n}" aria-label="${n} ${n === 1 ? "estrella" : "estrellas"}" aria-pressed="false">★</button>`
    ).join("");

    dialogBody.innerHTML = `
      <div class="cand-detail-head">
        <span class="avatar" aria-hidden="true">${esc(initials(candidate.name))}</span>
        <div>
          <h3>${esc(candidate.name)}</h3>
          <p>${esc(candidate.city)}</p>
        </div>
      </div>
      <div class="cand-facts">${facts}</div>
      <div class="detail-section">
        <h3>Habilidades</h3>
        <div class="badge-row">${skills || '<span class="form-note">Sin habilidades registradas.</span>'}</div>
      </div>
      <div class="detail-section" style="margin-top: 16px">
        <h3>Biografía</h3>
        <p>${esc(candidate.bio || "Sin biografía.")}</p>
      </div>
      ${candidate.applicantNote ? `
      <div class="detail-section" style="margin-top: 16px">
        <h3>Nota del artista</h3>
        <p>${esc(candidate.applicantNote)}</p>
      </div>` : ""}
      <div class="detail-section" style="margin-top: 16px">
        <h3>Materiales enviados</h3>
        <div class="material-chips">${materials || '<span class="form-note">No adjuntó materiales.</span>'}</div>
      </div>
      <div class="private-note">
        <span class="field-label">Calificación</span>
        <div class="rating" role="group" aria-label="Calificación del candidato">${stars}</div>
        <label class="field" style="margin-top: 12px">
          <span class="field-label">Nota privada</span>
          <textarea class="textarea" id="dialog-note" maxlength="500" placeholder="Solo tú puedes ver esta nota.">${esc(candidate.note || "")}</textarea>
          <span class="field-hint">Solo la ve tu compañía. Máximo 500 caracteres.</span>
        </label>
      </div>`;

    paintRating();

    if (typeof dialog.showModal === "function") dialog.showModal();
    else dialog.setAttribute("open", "");
    document.body.classList.add("modal-open");
  }

  function closeDialog() {
    if (typeof dialog.close === "function") dialog.close();
    else dialog.removeAttribute("open");
    document.body.classList.remove("modal-open");
    dialogCandidateId = null;
  }

  function saveDialog() {
    if (!dialogCandidateId) return;
    const noteField = $("#dialog-note");
    Data.setCandidateRating(dialogCandidateId, dialogRating);
    Data.setCandidateNote(dialogCandidateId, noteField ? noteField.value : "");
    closeDialog();
    renderCandidates();
  }

  // ---------------------------------------------------------------------
  // Eventos
  // ---------------------------------------------------------------------
  function bindEvents() {
    // Mis convocatorias: ver candidatos / cambiar estado
    auditionList.addEventListener("click", (event) => {
      const selectButton = event.target.closest("[data-select-audition]");
      if (selectButton) {
        selectAudition(selectButton.dataset.selectAudition);
        return;
      }

      const statusButton = event.target.closest("[data-audition-status]");
      if (statusButton) {
        const next = statusButton.dataset.nextStatus;
        // Publicar o reabrir equivale a publicar: requiere suscripción
        if (next === "published" && !Data.hasActiveSubscription()) {
          showSubscriptionRequired();
          return;
        }
        Data.setAuditionStatus(statusButton.dataset.auditionStatus, next);
        renderAuditions();
      }
    });

    // Selector de candidatos
    auditionSelect.addEventListener("change", () => selectAudition(auditionSelect.value));

    // Filtros por estado
    filtersBox.addEventListener("click", (event) => {
      const button = event.target.closest("[data-filter]");
      if (!button) return;
      statusFilter = button.dataset.filter;
      renderFilters();
      renderCandidates();
    });

    // Cambio de estado de un candidato (con confirmación al aceptar o rechazar)
    candidateList.addEventListener("change", (event) => {
      const select = event.target.closest("[data-status-for]");
      if (!select) return;

      const id = select.dataset.statusFor;
      const next = select.value;
      const candidate = Data.getCandidate(id);
      if (!candidate || candidate.status === next) return;

      if (next === "accepted" || next === "rejected") {
        const verb = next === "accepted" ? "aceptar" : "rechazar";
        if (!window.confirm(`¿Deseas ${verb} la postulación de ${candidate.name}?`)) {
          select.value = candidate.status;
          return;
        }
      }

      Data.setCandidateStatus(id, next);
      renderAll();
    });

    // Abrir el detalle del candidato
    candidateList.addEventListener("click", (event) => {
      const button = event.target.closest("[data-view-candidate]");
      if (button) openCandidate(button.dataset.viewCandidate);
    });

    // Diálogo: estrellas
    dialogBody.addEventListener("click", (event) => {
      const star = event.target.closest("[data-star]");
      if (!star) return;
      const value = Number(star.dataset.star);
      // Pulsar de nuevo la calificación actual la quita
      dialogRating = dialogRating === value ? 0 : value;
      paintRating();
    });

    dialog.querySelectorAll("[data-close-dialog]").forEach((button) => {
      button.addEventListener("click", closeDialog);
    });
    dialogSave.addEventListener("click", saveDialog);
    dialog.addEventListener("click", (event) => {
      if (event.target === dialog) closeDialog();
    });
	
    dialog.addEventListener("close", () => {
      document.body.classList.remove("modal-open");
      dialogCandidateId = null;
    });
  }

  // ---------------------------------------------------------------------
  // Arranque
  // ---------------------------------------------------------------------
  function pickInitialAudition() {
    const auditions = Data.getAuditions();
    if (auditions.length === 0) return null;

    // Permite abrir una convocatoria concreta: dashboard.jsp?audition=ID
    const requested = new URLSearchParams(window.location.search).get("audition");
    if (requested && auditions.some((audition) => audition.id === requested)) return requested;

    // Si no, la primera que ya tenga candidatos; si ninguna, la primera de la lista
    const withCandidates = auditions.find((audition) => Data.getCandidateStats(audition.id).total > 0);
    return (withCandidates || auditions[0]).id;
  }

  function init() {
    if (actorView) actorView.hidden = true;
    producerView.hidden = false;

    renderSubscriptionNotice();
    selectedId = pickInitialAudition();
    bindEvents();
    renderAll();
  }

  init();
})();
