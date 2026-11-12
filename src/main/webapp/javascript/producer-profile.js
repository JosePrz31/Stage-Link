// =========================================================================
// StageLink · Perfil de la compañía (rol de PRODUCTORA)
// Si la cuenta es de Artista, este script no modifica la página.
// =========================================================================
(() => {
  "use strict";

  const App = window.StageLinkApp;
  const Data = window.StageLinkProducer;

  const $ = (selector, root = document) => root.querySelector(selector);

  const form = $("#profile-form");
  const actorFields = $("#actor-fields");
  const producerFields = $("#producer-fields");

  if (!App || !Data || !form || !actorFields || !producerFields) {
    console.error("producer-profile.js: faltan app.js, producer-data.js o el HTML de profile.jsp.");
    return;
  }

  // Un Artista conserva su vista tal como está
  if (App.getRole() !== "producer") return;

  const esc = App.escapeHtml;

  const message = $("#profile-message");
  const avatarPreview = $("#profile-avatar-preview");
  const previewName = $("#profile-preview-name");
  const previewRole = $("#profile-preview-role");
  const avatarInput = $("#profile-avatar-input");
  const accountLabel = $("#account-type-label");
  const accountDescription = $("#account-type-description");
  const subSection = $("#subscription-section");
  const subCard = $("#subscription-card");
  const approvalBox = $("#company-approval");
  const resetButton = $("#reset-demo");

  const MAX_AVATAR_BYTES = 500 * 1024;
  const ALLOWED_AVATAR = ["image/png", "image/jpeg", "image/webp"];
  const FIELDS = [
    "displayName", "city", "bio", "phone",
    "companyType", "companySize", "contactName", "contactEmail", "website"
  ];

  // Foto elegida pero aún no guardada ("" = sin foto; null = sin cambios)
  let pendingAvatar = null;
  let currentAvatar = "";

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

  function avatarHtml(name, avatar) {
    return avatar ? `<img src="${esc(avatar)}" alt="">` : esc(initials(name));
  }

  function showMessage(text, type) {
    message.dataset.type = type || "success";
    message.textContent = text;
    message.hidden = false;
    message.scrollIntoView({ behavior: "smooth", block: "center" });
  }

  function clearMessage() {
    message.hidden = true;
    message.textContent = "";
  }

  // Datos de la compañía con valores por defecto coherentes con el resto del proyecto
  function loadCompany() {
    const company = Data.getCompany();
    const baseProfile = App.getProfile("producer");
    return {
      displayName: company.displayName || company.name || baseProfile.displayName || "",
      city: company.city || baseProfile.city || "",
      bio: company.bio || company.description || "",
      phone: company.phone || baseProfile.phone || "",
      companyType: company.companyType || "",
      companySize: company.companySize || "",
      contactName: company.contactName || "",
      contactEmail: company.contactEmail || company.email || "",
      website: company.website || "",
      avatar: company.avatar || "",
      approvalStatus: company.approvalStatus || "pending"
    };
  }

  // ---------------------------------------------------------------------
  // Vista previa lateral y sidebar (solo en esta página)
  // ---------------------------------------------------------------------
  function paintPreview() {
    const name = form.elements.displayName.value.trim() || "Nombre de perfil";
    const avatar = pendingAvatar !== null ? pendingAvatar : currentAvatar;

    previewName.textContent = name;
    previewRole.textContent = "Productora / compañía";
    avatarPreview.innerHTML = avatarHtml(name, avatar);
  }

  function paintSidebar(name, avatar) {
    const strong = $(".side-profile-copy strong");
    if (strong) strong.textContent = name;
    const sideAvatar = $(".side-profile .avatar");
    if (sideAvatar) sideAvatar.innerHTML = avatarHtml(name, avatar);
  }

  // ---------------------------------------------------------------------
  // Tipo de cuenta y aprobación
  // ---------------------------------------------------------------------
  function paintAccountType() {
    accountLabel.textContent = "Productora o compañía";
    accountDescription.textContent =
      "Puedes gestionar postulaciones y publicar convocatorias (esto último requiere una suscripción activa).";
  }

  function paintApproval(status) {
    const label = Data.APPROVAL_STATUS[status] || Data.APPROVAL_STATUS.pending;
    const tone = status === "approved" ? "success" : status === "rejected" ? "danger" : "warning";
    approvalBox.innerHTML =
      `<span class="field-label">Estado de la cuenta:</span> <span class="badge ${tone}">${esc(label)}</span>`;
  }

  // ---------------------------------------------------------------------
  // Tarjeta de suscripción
  // ---------------------------------------------------------------------
  const CHECK_ICON =
    '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="m5 12 5 5 9-10"></path></svg>';

  function renderSubscription() {
    const subscription = Data.getSubscription();

    if (subscription && Data.hasActiveSubscription()) {
      subCard.innerHTML = `
        <div class="subscription-card-head">
          <strong>${esc(subscription.planName)}</strong>
          <span class="sub-badge">${CHECK_ICON} Suscripción activa</span>
        </div>
        <div class="subscription-card-meta">
          <span>Importe: <strong>${esc(Data.formatPrice(subscription.price))}</strong></span>
          <span>Inicio: ${esc(Data.formatDate(subscription.startedAt))}</span>
          <span>Próxima renovación: ${esc(Data.formatDate(subscription.renewsAt))}</span>
          <span>Tarjeta terminada en ${esc(subscription.last4)}</span>
          <span>Referencia: ${esc(subscription.reference)}</span>
        </div>
        <div class="subscription-card-actions">
          <a class="button secondary small" href="create-audition.jsp">Crear convocatoria</a>
          <button class="button danger small" type="button" data-cancel-subscription>Cancelar suscripción</button>
        </div>`;
      return;
    }

    const expired = subscription && subscription.active;
    subCard.innerHTML = `
      <div class="subscription-card-head">
        <strong>${expired ? "Suscripción vencida" : "Sin suscripción"}</strong>
        <span class="sub-badge is-inactive">${expired ? "Vencida" : "Inactiva"}</span>
      </div>
      <div class="subscription-card-meta">
        <span>${expired
          ? `Tu plan venció el ${esc(Data.formatDate(subscription.renewsAt))}. Renuévalo para volver a publicar convocatorias.`
          : "Necesitas una suscripción activa para publicar convocatorias. Gestionar postulaciones sigue disponible."}</span>
      </div>
      <div class="subscription-card-actions">
        <a class="button small" href="subscription.jsp">Ver planes y suscribirme</a>
      </div>`;
  }

  // ---------------------------------------------------------------------
  // Formulario
  // ---------------------------------------------------------------------
  function fillForm(company) {
    FIELDS.forEach((name) => {
      const field = form.elements[name];
      if (field) field.value = company[name] || "";
    });
  }

  function saveProfile() {
    clearMessage();
    if (!form.reportValidity()) return;

    const values = {};
    FIELDS.forEach((name) => {
      values[name] = String(form.elements[name].value || "").trim();
    });

    const changes = {
      ...values,
      // Se mantienen sincronizados los campos base de producer-data.js
      name: values.displayName,
      description: values.bio,
      email: values.contactEmail
    };
    if (pendingAvatar !== null) changes.avatar = pendingAvatar;

    const saved = Data.saveCompany(changes);

    // Si el navegador no pudo guardar la foto (poco espacio), lo avisamos
    if (pendingAvatar && Data.getCompany().avatar !== pendingAvatar) {
      showMessage("Los datos se guardaron, pero la foto es demasiado grande para la demo. Prueba con una más liviana.", "error");
      pendingAvatar = null;
      paintPreview();
      return;
    }

    if (pendingAvatar !== null) {
      currentAvatar = saved.avatar || "";
      pendingAvatar = null;
    }

    paintPreview();
    paintSidebar(values.displayName, currentAvatar);
    showMessage("Perfil de la compañía actualizado correctamente (guardado de demostración).", "success");
  }

  function handleAvatarChange() {
    const file = avatarInput.files && avatarInput.files[0];
    if (!file) return;

    if (!ALLOWED_AVATAR.includes(file.type)) {
      showMessage("Elige una imagen PNG, JPG o WebP.", "error");
      avatarInput.value = "";
      return;
    }
    if (file.size > MAX_AVATAR_BYTES) {
      showMessage("La foto supera los 500 KB. Elige una más liviana.", "error");
      avatarInput.value = "";
      return;
    }

    const reader = new FileReader();
    reader.addEventListener("load", () => {
      clearMessage();
      pendingAvatar = String(reader.result || "");
      paintPreview();
    });
    reader.addEventListener("error", () => {
      showMessage("No se pudo leer la imagen. Intenta con otra.", "error");
    });
    reader.readAsDataURL(file);
  }

  // ---------------------------------------------------------------------
  // Eventos
  // ---------------------------------------------------------------------
  function bindEvents() {
    // Guardado simulado: nunca llega al servidor
    form.addEventListener("submit", (event) => {
      event.preventDefault();
      saveProfile();
    });

    form.elements.displayName.addEventListener("input", paintPreview);
    avatarInput.addEventListener("change", handleAvatarChange);

    // Cancelar suscripción (delegación: la tarjeta se vuelve a dibujar)
    subCard.addEventListener("click", (event) => {
      if (!event.target.closest("[data-cancel-subscription]")) return;
      if (!window.confirm("¿Cancelar tu suscripción? No podrás publicar convocatorias hasta suscribirte de nuevo.")) return;
      Data.cancelSubscription();
      showMessage("Suscripción cancelada.", "success");
    });

    // Se actualiza sola si la suscripción cambia (activar, cancelar o reiniciar)
    window.addEventListener("stagelink:subscription-changed", renderSubscription);

    // Restablecer demo
    resetButton.addEventListener("click", () => {
      const text =
        "Se borrarán la suscripción, las convocatorias, los candidatos y los datos de la compañía de la demo. ¿Continuar?";
      if (!window.confirm(text)) return;
      Data.resetDemo();
      window.location.reload();
    });
  }

  // ---------------------------------------------------------------------
  // Arranque
  // ---------------------------------------------------------------------
  function init() {
    actorFields.hidden = true;
    producerFields.hidden = false;
    subSection.hidden = false;

    const company = loadCompany();
    currentAvatar = company.avatar;

    fillForm(company);
    paintAccountType();
    paintApproval(company.approvalStatus);
    paintPreview();
    paintSidebar(company.displayName, currentAvatar);
    renderSubscription();
    bindEvents();
  }

  init();
})();
