(() => {
  "use strict";

  // ---------------------------------------------------------------------
  // Claves de almacenamiento
  // ---------------------------------------------------------------------
  const KEYS = {
    subscription: "stagelink.subscription",
    auditions: "stagelink.producer.auditions",
    candidates: "stagelink.producer.candidates",
    company: "stagelink.producer.company"
  };

  // ---------------------------------------------------------------------
  // Catálogos y etiquetas
  // ---------------------------------------------------------------------
  const AUDITION_STATUS = {
    draft: "Borrador",
    published: "Publicada",
    closed: "Cerrada"
  };

  const APPLICATION_STATUS = {
    pending: "Pendiente",
    shortlisted: "En preselección",
    accepted: "Aceptada",
    rejected: "Rechazada"
  };

  const COMPENSATION = {
    paid: "Remunerado",
    "ad-honorem": "Proyecto ad honorem",
    experience: "Intercambio de experiencia"
  };

  const APPROVAL_STATUS = {
    pending: "Pendiente de aprobación",
    approved: "Aprobada",
    rejected: "No aprobada"
  };

  // Planes de suscripción ficticios (precios en balboas, B/.)
  const PLANS = [
    {
      id: "monthly",
      name: "Plan Mensual",
      price: 25,
      months: 1,
      period: "por mes",
      features: [
        "Publica convocatorias ilimitadas",
        "Gestiona roles y postulaciones",
        "Revisa portafolios y videos de los artistas",
        "Notificaciones de nuevas postulaciones"
      ],
      highlight: false
    },
    {
      id: "annual",
      name: "Plan Anual",
      price: 240,
      months: 12,
      period: "por año",
      features: [
        "Todo lo del plan mensual",
        "Ahorro equivalente a 2 meses",
        "Soporte prioritario",
        "Insignia de compañía verificada"
      ],
      highlight: true
    }
  ];

  // ---------------------------------------------------------------------
  // Utilidades básicas
  // ---------------------------------------------------------------------
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

  function remove(key) {
    try {
      localStorage.removeItem(key);
    } catch (error) {
      // Sin acción: localStorage no disponible.
    }
  }

  function clone(value) {
    return JSON.parse(JSON.stringify(value));
  }

  function uid(prefix) {
    return `${prefix}-${Date.now().toString(36)}${Math.random().toString(36).slice(2, 6)}`;
  }

  function addMonths(date, months) {
    const result = new Date(date.getTime());
    result.setMonth(result.getMonth() + months);
    return result;
  }

  // Convierte "YYYY-MM-DD" en una fecha legible en español, sin desfase de zona horaria
  function formatDate(value) {
    if (!value) return "Sin definir";
    const match = /^(\d{4})-(\d{2})-(\d{2})/.exec(String(value));
    const date = match
      ? new Date(Number(match[1]), Number(match[2]) - 1, Number(match[3]))
      : new Date(value);
    if (Number.isNaN(date.getTime())) return "Sin definir";
    return date.toLocaleDateString("es-PA", { day: "numeric", month: "long", year: "numeric" });
  }

  function formatPrice(amount) {
    return `B/. ${Number(amount).toFixed(2)}`;
  }

  // "una línea por requisito" -> ["req 1", "req 2"]
  function parseRequirements(text) {
    return String(text || "")
      .split(/\r?\n/)
      .map((line) => line.trim())
      .filter(Boolean);
  }

  // ---------------------------------------------------------------------
  // Datos de prueba (mock data)
  // ---------------------------------------------------------------------
  function seedAuditions() {
    return [
      {
        id: "aud-demo-1",
        title: "La casa de Bernarda Alba",
        type: "Teatro",
        description: "Montaje de cámara del clásico de García Lorca con enfoque contemporáneo y un elenco íntegramente femenino.",
        compensationType: "paid",
        compensation: "B/. 300 por temporada",
        requirements: "Disponibilidad de martes a sábado\nExperiencia previa en teatro\nPreparar un monólogo de 2 minutos",
        location: "Teatro La Huaca, calle 50",
        district: "Bella Vista",
        deadline: "2026-12-05",
        date: "2026-12-12",
        time: "10:00",
        materials: ["Headshot", "CV artístico"],
        roles: [
          { id: "role-1-1", name: "Adela", profile: "Joven adulta · Principal", age: "18–30 años", gender: "Femenino", description: "La menor de las hijas, rebelde y apasionada.", requirement: "Self-tape con la escena del tercer acto." },
          { id: "role-1-2", name: "Bernarda", profile: "Adulta mayor · Principal", age: "45–65 años", gender: "Femenino", description: "Matriarca autoritaria de la casa.", requirement: "Monólogo libre de 2 minutos." },
          { id: "role-1-3", name: "La Poncia", profile: "Adulta · Reparto", age: "35–55 años", gender: "Femenino", description: "Criada de confianza y voz de la experiencia.", requirement: "" }
        ],
        status: "published",
        createdAt: "2026-10-20"
      },
      {
        id: "aud-demo-2",
        title: "Cortometraje «Marea Baja»",
        type: "Cortometraje",
        description: "Drama corto rodado en Casco Antiguo sobre una familia de pescadores que enfrenta el cierre de su muelle.",
        compensationType: "experience",
        compensation: "Alimentación y copia del corto",
        requirements: "Disponibilidad en fines de semana\nComodidad frente a cámara",
        location: "Casa de la Cultura, Casco Antiguo",
        district: "San Felipe",
        deadline: "2026-11-28",
        date: "2026-12-03",
        time: "14:30",
        materials: ["Headshot", "Reel de actuación"],
        roles: [
          { id: "role-2-1", name: "Mateo", profile: "Adulto · Principal", age: "30–45 años", gender: "Masculino", description: "Pescador que lucha por conservar su oficio.", requirement: "Self-tape de 1 minuto." },
          { id: "role-2-2", name: "Lucía", profile: "Joven · Reparto", age: "16–22 años", gender: "Femenino", description: "Hija de Mateo, sueña con estudiar fuera.", requirement: "" }
        ],
        status: "published",
        createdAt: "2026-10-28"
      },
      {
        id: "aud-demo-3",
        title: "Musical «Noches de Calidonia»",
        type: "Musical",
        description: "Musical original ambientado en los años 60 con música en vivo. Convocatoria en preparación.",
        compensationType: "ad-honorem",
        compensation: "Proyecto ad honorem",
        requirements: "Canto y baile básico\nDisponibilidad de enero a marzo",
        location: "Por confirmar",
        district: "Calidonia",
        deadline: "2027-01-10",
        date: "2027-01-17",
        time: "09:00",
        materials: ["Headshot", "Video de canto"],
        roles: [
          { id: "role-3-1", name: "Rosa", profile: "Joven adulta · Principal", age: "20–32 años", gender: "Femenino", description: "Cantante de salón con un secreto.", requirement: "Video cantando 1 minuto." }
        ],
        status: "draft",
        createdAt: "2026-11-02"
      }
    ];
  }

  function seedCandidates() {
    return [
      { id: "cand-1", auditionId: "aud-demo-1", roleId: "role-1-1", name: "Valeria Montenegro", city: "Ciudad de Panamá", age: 24, height: "165 cm", gender: "Femenino", languages: "Español, Inglés", skills: ["Actuación", "Canto", "Danza"], bio: "Actriz egresada de una escuela de teatro local, con dos montajes universitarios.", appliedAt: "2026-11-03", status: "pending", rating: 0, note: "", applicantNote: "Disponible toda la temporada.", materials: [{ type: "image", name: "Headshot principal" }, { type: "video", name: "Monólogo dramático" }, { type: "document", name: "CV artístico.pdf" }] },
      { id: "cand-2", auditionId: "aud-demo-1", roleId: "role-1-1", name: "Camila Ortega", city: "San Miguelito", age: 27, height: "170 cm", gender: "Femenino", languages: "Español", skills: ["Actuación", "Voz"], bio: "Cuatro años en teatro independiente.", appliedAt: "2026-11-04", status: "shortlisted", rating: 4, note: "Buena presencia escénica. Pedir segunda lectura.", applicantNote: "", materials: [{ type: "image", name: "Headshot" }, { type: "video", name: "Self-tape Adela" }] },
      { id: "cand-3", auditionId: "aud-demo-1", roleId: "role-1-2", name: "Rosa Elena Díaz", city: "Ciudad de Panamá", age: 52, height: "160 cm", gender: "Femenino", languages: "Español, Francés", skills: ["Actuación", "Dirección"], bio: "Más de 20 años en escena, ha dirigido varios montajes comunitarios.", appliedAt: "2026-11-02", status: "accepted", rating: 5, note: "Ideal para Bernarda.", applicantNote: "Adjunto reseña de prensa.", materials: [{ type: "video", name: "Monólogo libre" }, { type: "document", name: "Reseña de prensa.pdf" }] },
      { id: "cand-4", auditionId: "aud-demo-1", roleId: "role-1-3", name: "Marta Quintero", city: "La Chorrera", age: 41, height: "158 cm", gender: "Femenino", languages: "Español", skills: ["Actuación"], bio: "Experiencia en televisión local y teatro comunitario.", appliedAt: "2026-11-05", status: "rejected", rating: 2, note: "No cumple disponibilidad.", applicantNote: "", materials: [{ type: "image", name: "Headshot" }] },
      { id: "cand-5", auditionId: "aud-demo-2", roleId: "role-2-1", name: "Andrés Batista", city: "Colón", age: 35, height: "178 cm", gender: "Masculino", languages: "Español, Inglés", skills: ["Actuación", "Cine"], bio: "Actor de cine independiente, dos cortometrajes premiados a nivel local.", appliedAt: "2026-11-01", status: "pending", rating: 0, note: "", applicantNote: "Cuento con reel actualizado.", materials: [{ type: "video", name: "Reel 2026" }, { type: "image", name: "Headshot" }] },
      { id: "cand-6", auditionId: "aud-demo-2", roleId: "role-2-1", name: "Gabriel Sáenz", city: "Ciudad de Panamá", age: 39, height: "175 cm", gender: "Masculino", languages: "Español", skills: ["Actuación", "Improvisación"], bio: "Formado en improvisación y teatro físico.", appliedAt: "2026-11-04", status: "pending", rating: 0, note: "", applicantNote: "", materials: [{ type: "video", name: "Self-tape Mateo" }] },
      { id: "cand-7", auditionId: "aud-demo-2", roleId: "role-2-2", name: "Isabella Cruz", city: "Arraiján", age: 19, height: "162 cm", gender: "Femenino", languages: "Español, Inglés", skills: ["Actuación", "Canto"], bio: "Estudiante de artes escénicas, primera experiencia en cine.", appliedAt: "2026-11-05", status: "shortlisted", rating: 3, note: "Revisar con la dirección.", applicantNote: "Mis padres autorizan el rodaje en fines de semana.", materials: [{ type: "image", name: "Headshot" }, { type: "video", name: "Escena libre" }] }
    ];
  }

  function seedCompany() {
    return {
      name: "Producciones Istmo",
      description: "Compañía teatral independiente con sede en Ciudad de Panamá.",
      contactName: "Laura Pinzón",
      email: "contacto@produccionesistmo.example",
      phone: "+507 390-8840",
      approvalStatus: "approved"
    };
  }

  // ------------------------------------
  // Suscripción 
  // ------------------------------------
  function getPlans() {
    return clone(PLANS);
  }

  function getPlan(planId) {
    const plan = PLANS.find((item) => item.id === planId);
    return plan ? clone(plan) : null;
  }

  // Devuelve el registro de suscripción o null si nunca se activó / se canceló
  function getSubscription() {
    const stored = read(KEYS.subscription, null);
    return stored && typeof stored === "object" ? stored : null;
  }

  function hasActiveSubscription() {
    const subscription = getSubscription();
    if (!subscription || !subscription.active) return false;
    const renewsAt = new Date(subscription.renewsAt);
    return Number.isNaN(renewsAt.getTime()) || renewsAt.getTime() > Date.now();
  }

  // Simula el pago exitoso. NUNCA recibe ni guarda número de tarjeta completo ni CVV.
  function activateSubscription(planId, paymentInfo = {}) {
    const plan = PLANS.find((item) => item.id === planId);
    if (!plan) return null;

    const now = new Date();
    const last4 = String(paymentInfo.last4 || "").replace(/\D/g, "").slice(-4);
    const subscription = {
      active: true,
      planId: plan.id,
      planName: plan.name,
      price: plan.price,
      startedAt: now.toISOString(),
      renewsAt: addMonths(now, plan.months).toISOString(),
      last4: last4 || "0000",
      reference: `SIM-${now.getTime().toString(36).toUpperCase()}`
    };

    write(KEYS.subscription, subscription);
    window.dispatchEvent(new CustomEvent("stagelink:subscription-changed", { detail: subscription }));
    return clone(subscription);
  }

  function cancelSubscription() {
    remove(KEYS.subscription);
    window.dispatchEvent(new CustomEvent("stagelink:subscription-changed", { detail: null }));
  }

  // ---------------------------------------------------------------------
  // Convocatorias
  // ---------------------------------------------------------------------
  function readAuditions() {
    const stored = read(KEYS.auditions, null);
    if (Array.isArray(stored)) return stored;
    const seeded = seedAuditions();
    write(KEYS.auditions, seeded);
    return seeded;
  }

  function getAuditions() {
    return clone(readAuditions());
  }

  function getAudition(id) {
    const found = readAuditions().find((item) => item.id === id);
    return found ? clone(found) : null;
  }

  // Crea (sin id) o actualiza (con id existente) una convocatoria.
  // Devuelve la convocatoria guardada.
  function saveAudition(data) {
    const list = readAuditions();
    const incoming = clone(data || {});
    incoming.roles = Array.isArray(incoming.roles)
      ? incoming.roles.map((role) => ({ ...role, id: role.id || uid("role") }))
      : [];

    const index = incoming.id ? list.findIndex((item) => item.id === incoming.id) : -1;
    let saved;

    if (index >= 0) {
      saved = { ...list[index], ...incoming };
      list[index] = saved;
    } else {
      saved = {
        status: "published",
        materials: [],
        createdAt: new Date().toISOString().slice(0, 10),
        ...incoming,
        id: uid("aud")
      };
      list.unshift(saved);
    }

    write(KEYS.auditions, list);
    return clone(saved);
  }

  function setAuditionStatus(id, status) {
    if (!AUDITION_STATUS[status]) return null;
    const list = readAuditions();
    const target = list.find((item) => item.id === id);
    if (!target) return null;
    target.status = status;
    write(KEYS.auditions, list);
    return clone(target);
  }

  // ---------------------------------------------------------------------
  // Candidatos / postulaciones recibidas
  // ---------------------------------------------------------------------
  function readCandidates() {
    const stored = read(KEYS.candidates, null);
    if (Array.isArray(stored)) return stored;
    const seeded = seedCandidates();
    write(KEYS.candidates, seeded);
    return seeded;
  }

  // Si se pasa auditionId, filtra por esa convocatoria
  function getCandidates(auditionId) {
    const list = readCandidates();
    return clone(auditionId ? list.filter((item) => item.auditionId === auditionId) : list);
  }

  function getCandidate(id) {
    const found = readCandidates().find((item) => item.id === id);
    return found ? clone(found) : null;
  }

  function updateCandidate(id, changes) {
    const list = readCandidates();
    const target = list.find((item) => item.id === id);
    if (!target) return null;
    Object.assign(target, changes);
    write(KEYS.candidates, list);
    return clone(target);
  }

  function setCandidateStatus(id, status) {
    if (!APPLICATION_STATUS[status]) return null;
    return updateCandidate(id, { status });
  }

  function setCandidateRating(id, rating) {
    const value = Math.max(0, Math.min(5, Math.round(Number(rating) || 0)));
    return updateCandidate(id, { rating: value });
  }

  function setCandidateNote(id, note) {
    return updateCandidate(id, { note: String(note || "").slice(0, 500) });
  }

  // Conteos por estado, para las tarjetas de estadísticas
  function getCandidateStats(auditionId) {
    const stats = { total: 0, pending: 0, shortlisted: 0, accepted: 0, rejected: 0 };
    getCandidates(auditionId).forEach((candidate) => {
      stats.total += 1;
      if (stats[candidate.status] !== undefined) stats[candidate.status] += 1;
    });
    return stats;
  }

  // ---------------------------------------------------------------------
  // Datos de la compañía ("Mi organización")
  // ---------------------------------------------------------------------
  function getCompany() {
    const stored = read(KEYS.company, null);
    return { ...seedCompany(), ...(stored || {}) };
  }

  function saveCompany(changes) {
    const merged = { ...getCompany(), ...(changes || {}) };
    write(KEYS.company, merged);
    return clone(merged);
  }

  // ---------------------------------------------------------------------
  // Reinicio de la demo (solo borra datos de Productora y la suscripción)
  // ---------------------------------------------------------------------
  function resetDemo() {
    Object.values(KEYS).forEach(remove);
    window.dispatchEvent(new CustomEvent("stagelink:subscription-changed", { detail: null }));
  }

  // ---------------------------------------------------------------------
  // API pública
  // ---------------------------------------------------------------------
  window.StageLinkProducer = {
    KEYS,
    AUDITION_STATUS,
    APPLICATION_STATUS,
    COMPENSATION,
    APPROVAL_STATUS,

    // Suscripción
    getPlans,
    getPlan,
    getSubscription,
    hasActiveSubscription,
    activateSubscription,
    cancelSubscription,

    // Convocatorias
    getAuditions,
    getAudition,
    saveAudition,
    setAuditionStatus,

    // Candidatos
    getCandidates,
    getCandidate,
    setCandidateStatus,
    setCandidateRating,
    setCandidateNote,
    getCandidateStats,

    // Compañía
    getCompany,
    saveCompany,

    // Utilidades
    formatDate,
    formatPrice,
    parseRequirements,
    resetDemo
  };
})();
