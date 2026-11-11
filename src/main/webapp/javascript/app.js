// =========================================================================
// LIMPIEZA SELECTIVA DE LA SIMULACIÓN LOCAL
// Antes: localStorage.clear() borraba TODO (incluido el rol activo).
// Ahora: se siguen limpiando los datos de simulación del actor, pero se
// conservan las claves necesarias para el rol de Productora.
// =========================================================================
(() => {
  const PERSISTENT_KEYS = ["stagelink.role", "stagelink.subscription"];
  const PERSISTENT_PREFIXES = ["stagelink.producer."];

  try {
    Object.keys(localStorage).forEach((key) => {
      const keep =
        PERSISTENT_KEYS.includes(key) ||
        PERSISTENT_PREFIXES.some((prefix) => key.startsWith(prefix));
      if (!keep) localStorage.removeItem(key);
    });
  } catch (error) {
    // Si localStorage no está disponible, continuamos sin limpiar.
  }
})();

(() => {
  "use strict";

  const STORAGE = {
    role: "stagelink.role",
    profiles: "stagelink.profiles",
    portfolio: "stagelink.portfolio",
    workHistory: "stagelink.workHistory",
    remoteAuditions: "stagelink.remoteAuditions",
    createdAuditions: "stagelink.createdAuditions",
    savedAuditions: "stagelink.savedAuditions",
    applications: "stagelink.applications",
    notifications: "stagelink.notifications",
    candidates: "stagelink.candidates",
    // Datos de la compañía (Productora). Se conserva en la limpieza por su prefijo.
    producerCompany: "stagelink.producer.company"
  };

  const backend = window.StageLinkBackend || null;

  function isRemoteMode() {
    return Boolean(backend?.configured);
  }

  const DEFAULT_AUDITIONS = [];
  const DEFAULT_PROFILES = {
    actor: { displayName: "María Rivera", city: "Ciudad de Panamá", bio: "Actriz en formación.", phone: "+507 6000-1234", avatar: "" },
    producer: { displayName: "Producciones Istmo", city: "Ciudad de Panamá", bio: "Compañía independiente.", phone: "+507 390-8840", avatar: "" }
  };
  const DEFAULT_PORTFOLIO = [];
  const DEFAULT_NOTIFICATIONS = [];
  const DEFAULT_APPLICATIONS = [];
  const DEFAULT_CANDIDATES = [];

  const PAGE_META = {
    feed: ["Audiciones", "Oportunidades abiertas"],
    audition: ["Detalle", "Convocatoria"],
    portfolio: ["Portafolio", "Material artístico"],
    notifications: ["Notificaciones", "Actividad reciente"],
    profile: ["Mi perfil", "Información profesional"],
    create: ["Crear convocatoria", "Publicación guiada"],
    dashboard: ["Gestión", "Seguimiento"],
    subscription: ["Suscripción", "Plan de productora"],
    edit: ["Editar convocatoria", "Gestión de convocatorias"]
  };

  // Páginas secundarias -> ítem del menú que debe verse como "activo"
  const NAV_PARENT = {
    audition: "feed",
    subscription: "create",
    edit: "dashboard"
  };

  function read(key, fallback) {
    try {
      const raw = localStorage.getItem(key);
      return raw === null ? fallback : JSON.parse(raw);
    } catch (error) {
      return fallback;
    }
  }

  function write(key, value) {
    try {
      localStorage.setItem(key, JSON.stringify(value));
      return true;
    } catch (error) {
      return false;
    }
  }

  function getRole() {
    const stored = localStorage.getItem(STORAGE.role);
    return stored === "producer" || stored === "actor" ? stored : "actor";
  }

  function setRole(role) {
    if (role !== "actor" && role !== "producer") return;
    localStorage.setItem(STORAGE.role, role);
  }

  // Rol de demostración por parámetro de URL: ?role=producer | ?role=actor
  // (No hay sesión real todavía; esto permite probar cada rol.)
  (function applyRoleFromUrl() {
    try {
      const requested = new URLSearchParams(window.location.search).get("role");
      if (requested === "producer" || requested === "actor") setRole(requested);
    } catch (error) {
      // Ignoramos errores de lectura de la URL.
    }
  })();

  function getProfile(role = getRole() || "actor") {
    const profiles = read(STORAGE.profiles, DEFAULT_PROFILES);
    const profile = { ...DEFAULT_PROFILES[role], ...(profiles[role] || {}) };

    // Productora: los datos guardados de la compañía (producer-profile.js)
    // tienen prioridad, para que el sidebar muestre el nombre y la foto actuales.
    if (role === "producer") {
      const company = read(STORAGE.producerCompany, null);
      if (company && typeof company === "object") {
        const name = company.displayName || company.name;
        if (name) profile.displayName = name;
        if (company.city) profile.city = company.city;
        if (company.bio) profile.bio = company.bio;
        if (company.phone) profile.phone = company.phone;
        if (company.avatar) profile.avatar = company.avatar;
      }
    }

    return profile;
  }

  function escapeHtml(value) {
    return String(value ?? "")
      .replaceAll("&", "&amp;")
      .replaceAll("<", "&lt;")
      .replaceAll(">", "&gt;")
      .replaceAll('"', "&quot;")
      .replaceAll("'", "&#039;");
  }

  function initials(name) {
    return String(name || "SL")
      .trim()
      .split(/\s+/)
      .slice(0, 2)
      .map((word) => word[0] || "")
      .join("")
      .toUpperCase();
  }

  function icon(name, extraClass = "") {
    const paths = {
      search: '<circle cx="11" cy="11" r="7"></circle><path d="m20 20-4-4"></path>',
      masks: '<path d="M5 4h6v5a5 5 0 0 1-10 0V4h4Z"></path><path d="M13 4h6v5a5 5 0 0 1-8 4"></path>',
      portfolio: '<rect x="3" y="5" width="18" height="15" rx="2"></rect><path d="M8 5V3h8v2M3 10h18M9 14h6"></path>',
      bell: '<path d="M18 8a6 6 0 0 0-12 0c0 7-3 7-3 9h18c0-2-3-2-3-9"></path><path d="M10 21h4"></path>',
      user: '<circle cx="12" cy="8" r="4"></circle><path d="M4 21a8 8 0 0 1 16 0"></path>',
      users: '<path d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2"></path><circle cx="9" cy="7" r="4"></circle>',
      plus: '<path d="M12 5v14M5 12h14"></path>',
      calendar: '<rect x="3" y="5" width="18" height="16" rx="2"></rect><path d="M16 3v4M8 3v4M3 10h18"></path>',
      map: '<path d="M20 10c0 5-8 11-8 11S4 15 4 10a8 8 0 1 1 16 0Z"></path><circle cx="12" cy="10" r="2.5"></circle>',
      clock: '<circle cx="12" cy="12" r="9"></circle><path d="M12 7v5l3 2"></path>',
      bookmark: '<path d="M6 3h12v18l-6-4-6 4V3Z"></path>',
      arrowRight: '<path d="m9 18 6-6-6-6"></path>',
      inbox: '<path d="M4 4h16l2 12h-6l-2 3h-4l-2-3H2L4 4Z"></path>',
      building: '<path d="M4 21V4h11v17M15 9h5v12M8 8h3M8 12h3M8 16h3M18 13h.01M18 17h.01M2 21h20"></path>',
      info: '<circle cx="12" cy="12" r="9"></circle><path d="M12 11v6M12 7h.01"></path>'
    };
    return `<svg class="${escapeHtml(extraClass)}" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">${paths[name] || paths.info}</svg>`;
  }

  function avatarMarkup(profile, className = "avatar") {
    const content = profile.avatar
      ? `<img src="${escapeHtml(profile.avatar)}" alt="" />`
      : escapeHtml(initials(profile.displayName));
    return `<span class="${className}" aria-hidden="true">${content}</span>`;
  }

  // TODAS LAS RUTAS ACTUALIZADAS A .jsp
  function navItems(role) {
    if (role === "producer") {
      return [
        ["feed", "feed.jsp", "Convocatorias", "masks"],
        ["create", "create-audition.jsp", "Crear", "plus"],
        ["dashboard", "dashboard.jsp", "Gestión", "users"],
        ["notifications", "notifications.jsp", "Notificaciones", "bell"],
        ["profile", "profile.jsp", "Perfil", "building"]
      ];
    }
    return [
      ["feed", "feed.jsp", "Audiciones", "masks"],
      ["portfolio", "portfolio.jsp", "Portafolio", "portfolio"],
      ["dashboard", "dashboard.jsp", "Postulaciones", "inbox"],
      ["notifications", "notifications.jsp", "Notificaciones", "bell"],
      ["profile", "profile.jsp", "Perfil", "user"]
    ];
  }

  function renderNavLinks(items, page) {
    return items.map(([key, href, label, iconName]) => {
      const current = key === page || NAV_PARENT[page] === key;
      return `<a class="nav-link" href="${href}" ${current ? 'aria-current="page"' : ""}>
        ${icon(iconName, "nav-icon")}
        <span class="nav-text">${escapeHtml(label)}</span>
      </a>`;
    }).join("");
  }

  function initShell(page) {
    const role = getRole();
    const profile = getProfile(role);
    const items = navItems(role);
    const sidebar = document.querySelector("#sidebar");
    const topbar = document.querySelector("#topbar");
    const mobileNav = document.querySelector("#mobile-nav");
    const pageMeta = PAGE_META[page] || ["StageLink", "Plataforma"];

    if (sidebar) {
      sidebar.innerHTML = `
        <a class="brand" href="feed.jsp" aria-label="StageLink Auditions, inicio">
          <span class="brand-mark">SL</span>
          <span>StageLink<small>Auditions</small></span>
        </a>
        <nav class="side-nav" aria-label="Navegación principal">${renderNavLinks(items, page)}</nav>
        <a class="side-profile" href="profile.jsp">
          ${avatarMarkup(profile)}
          <span class="side-profile-copy"><strong>${escapeHtml(profile.displayName)}</strong><span>${role === "producer" ? "Productora / compañía" : "Artista"}</span></span>
        </a>`;
    }

    if (topbar) {
      topbar.innerHTML = `
        <div class="topbar-copy">
          <p class="topbar-eyebrow">${escapeHtml(pageMeta[1])}</p>
          <h2 class="topbar-title">${escapeHtml(pageMeta[0])}</h2>
        </div>
        <div class="heading-actions">
          <span class="role-chip" aria-label="Tipo de cuenta actual">
            <span class="dot"></span><span>${role === "producer" ? "Productora" : "Artista"}</span>
          </span>
        </div>`;
    }

    if (mobileNav) {
      mobileNav.setAttribute("aria-label", "Navegación principal");
      mobileNav.innerHTML = renderNavLinks(items, page);
    }
    return true;
  }

  function initWelcome() {
    // Controlado directamente por los enlaces y atributos onclick en el index.jsp
  }

  // API mínima para que los scripts de Productora (producer-*.js) reutilicen
  // el rol y el perfil sin duplicar las claves de almacenamiento.
  window.StageLinkApp = { getRole, setRole, getProfile, escapeHtml };

  const page = document.body.dataset.page;
  if (page && page !== "welcome") {
    initShell(page);
  } else if (page === "welcome") {
    initWelcome();
  }
})();
