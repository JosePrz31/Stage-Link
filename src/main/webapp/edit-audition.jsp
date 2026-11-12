<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<!doctype html>
<html lang="es">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<meta name="description"
	content="Edita una convocatoria y sus roles en StageLink Auditions.">
<title>Editar convocatoria · StageLink</title>

<!-- Icono vectorial SVG de la plataforma -->
<link rel="icon" type="image/svg+xml"
	href="data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 64 64'%3E%3Crect width='64' height='64' rx='16' fill='%230a0a0a'/%3E%3Cpath d='M18 18h30v8H27v7h17v8H27v10h-9z' fill='white'/%3E%3C/svg%3E">

<!-- Hoja de estilos general + estilos exclusivos de Productora (en ese orden) -->
<link rel="stylesheet" href="${pageContext.request.contextPath}/css/styles.css">
<link rel="stylesheet" href="${pageContext.request.contextPath}/css/producer.css">

<!-- Scripts: shell compartido, datos simulados y lógica de edición (se ejecutan en orden) -->
<script src="${pageContext.request.contextPath}/javascript/app.js" defer></script>
<script src="${pageContext.request.contextPath}/javascript/producer-data.js" defer></script>
<script src="${pageContext.request.contextPath}/javascript/producer-edit.js" defer></script>
</head>
<body data-page="edit">
	<!-- Enlace de accesibilidad para saltar directamente al contenido -->
	<a class="skip-link" href="#main-content">Saltar al contenido</a>

	<div class="app-frame">
		<!-- Barra lateral de navegación (la inyecta app.js) -->
		<aside class="sidebar" id="sidebar"></aside>

		<div class="main-column">
			<!-- Barra superior (la inyecta app.js) -->
			<header class="topbar" id="topbar"></header>

			<main class="content" id="main-content">
				<div class="page-heading">
					<div>
						<h1>Editar convocatoria</h1>
						<p id="edit-subtitle">Actualiza la información general y los
							roles. Los cambios no se guardan hasta que pulses «Guardar
							cambios».</p>
					</div>
					<!-- producer-edit.js muestra aquí el estado de la convocatoria -->
					<div class="heading-actions" id="edit-status"></div>
				</div>

				<!-- ============================================================= -->
				<!-- Panel: cuenta de Artista                                       -->
				<!-- ============================================================= -->
				<section class="role-guard card" id="edit-role-guard" hidden>
					<div class="role-guard-inner">
						<span class="empty-icon"> <svg viewBox="0 0 24 24"
								fill="none" stroke="currentColor" stroke-width="1.8"
								aria-hidden="true">
                <path
									d="M4 21V4h11v17M15 9h5v12M8 8h3M8 12h3M8 16h3M2 21h20"></path>
              </svg>
						</span>
						<h2>Función exclusiva para productoras</h2>
						<p>Tu cuenta está registrada como artista y no puede editar
							convocatorias.</p>
						<a class="button secondary" href="feed.jsp">Volver a
							audiciones</a>
					</div>
				</section>

				<!-- ============================================================= -->
				<!-- Panel: convocatoria no encontrada                              -->
				<!-- ============================================================= -->
				<section class="card empty-state" id="edit-not-found" hidden>
					<div class="empty-state-inner">
						<span class="empty-icon" aria-hidden="true"> <svg
								viewBox="0 0 24 24" fill="none" stroke="currentColor"
								stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round">
                <circle cx="12" cy="12" r="9"></circle>
                <path d="M12 11v6M12 7h.01"></path>
              </svg>
						</span>
						<h2>No encontramos esta convocatoria</h2>
						<p>Es posible que el enlace sea incorrecto o que la convocatoria
							ya no exista.</p>
						<a class="button" href="dashboard.jsp">Volver a Gestión</a>
					</div>
				</section>

				<!-- ============================================================= -->
				<!-- Formulario de edición (lo muestra producer-edit.js)            -->
				<!-- Sin "action": el envío lo intercepta el JS (guardado simulado)  -->
				<!-- ============================================================= -->
				<section id="edit-form-container" hidden>
					<form class="card" id="edit-audition-form" novalidate>

						<div class="auth-message" id="edit-message" role="alert"
							data-type="error" hidden style="margin: 20px 20px 0"></div>

						<!-- BLOQUE 1: Información del proyecto -->
						<section class="edit-block" aria-labelledby="edit-project-title">
							<header class="surface-header">
								<h2 id="edit-project-title">Información del proyecto</h2>
							</header>
							<div class="surface-body">
								<div class="form-grid">
									<label class="field"><span class="field-label">Nombre
											de la obra o proyecto</span><input class="input" name="title"
										required placeholder="Ej. La vida es sueño"></label> <label
										class="field"><span class="field-label">Tipo</span><select
										class="select" name="type" required><option>Teatro</option>
											<option>Musical</option>
											<option>Cortometraje</option>
											<option>Serie</option>
											<option>Cine</option>
											<option>Publicidad</option>
											<option>Otro</option></select></label> <label class="field span-2"><span
										class="field-label">Descripción</span>
									<textarea class="textarea" name="description" required
											placeholder="Cuenta de qué trata el proyecto y qué enfoque tendrá el montaje."></textarea></label>
									<label class="field"><span class="field-label">Modalidad
											de compensación</span><select class="select" name="compensationType"
										required><option value="paid">Remunerado</option>
											<option value="ad-honorem">Proyecto ad honorem</option>
											<option value="experience">Intercambio de
												experiencia</option></select></label> <label class="field" id="edit-compensation-field"><span
										class="field-label">Detalle del pago</span><input
										class="input" name="compensation" required
										placeholder="Ej. B/. 300 por temporada"></label> <label
										class="field span-2"><span class="field-label">Requisitos
											generales</span>
									<textarea class="textarea" name="requirements" required
											placeholder="Escribe un requisito por línea."></textarea><span
										class="field-hint">Incluye disponibilidad, experiencia
											y qué debe preparar la persona.</span></label>
								</div>
							</div>
						</section>

						<!-- BLOQUE 2: Fecha y ubicación -->
						<section class="edit-block" aria-labelledby="edit-logistics-title">
							<header class="surface-header">
								<h2 id="edit-logistics-title">Fecha y ubicación</h2>
							</header>
							<div class="surface-body">
								<div class="form-grid">
									<label class="field span-2"><span class="field-label">Lugar
											exacto</span><input class="input" name="location" required
										placeholder="Teatro, edificio y referencia"></label> <label
										class="field"><span class="field-label">Distrito
											o corregimiento</span><input class="input" name="district" required
										placeholder="Ej. Bella Vista"></label> <label class="field"><span
										class="field-label">Fecha límite para postularse</span><input
										class="input" type="date" name="deadline" required></label> <label
										class="field"><span class="field-label">Fecha
											de audición</span><input class="input" type="date" name="date"
										required></label> <label class="field"><span
										class="field-label">Hora</span><input class="input"
										type="time" name="time" required></label>
								</div>
							</div>
						</section>

						<!-- BLOQUE 3: Material general solicitado -->
						<section class="edit-block" aria-labelledby="edit-materials-title">
							<header class="surface-header">
								<h2 id="edit-materials-title">Material solicitado</h2>
							</header>
							<div class="surface-body">
								<fieldset class="fieldset">
									<legend>Material general que acompaña cada postulación</legend>
									<div class="check-grid" style="margin-top: 12px">
										<label class="check-card"><input type="checkbox"
											name="materials" value="Headshot"> Headshot</label> <label
											class="check-card"><input type="checkbox"
											name="materials" value="CV artístico"> CV artístico</label> <label
											class="check-card"><input type="checkbox"
											name="materials" value="Reel de actuación"> Reel de
											actuación</label> <label class="check-card"><input
											type="checkbox" name="materials" value="Video de canto">
											Video de canto</label>
									</div>
								</fieldset>
							</div>
						</section>

						<!-- BLOQUE 4: Gestión de roles (CU-08) -->
						<section class="edit-block" aria-labelledby="edit-roles-title">
							<header class="surface-header">
								<h2 id="edit-roles-title">Roles</h2>
							</header>
							<div class="surface-body">
								<p class="form-note" style="margin-bottom: 14px">Añade,
									modifica o elimina los personajes. La convocatoria debe tener
									al menos un rol.</p>
								<div class="edit-role-list" id="edit-role-list"></div>
								<button class="button secondary" id="edit-add-role"
									type="button" style="margin-top: 14px">Agregar rol</button>
							</div>
						</section>

						<!-- Acciones -->
						<div class="surface-body">
							<div class="form-actions" style="margin-top: 0">
								<a class="button secondary" id="edit-cancel"
									href="dashboard.jsp">Cancelar</a>
								<button class="button" type="submit" id="edit-save">Guardar
									cambios</button>
							</div>
						</div>
					</form>
				</section>
			</main>

			<!-- Barra de navegación inferior móvil (la inyecta app.js) -->
			<nav class="mobile-nav" id="mobile-nav"></nav>
		</div>
	</div>

	<!-- Diálogo: añadir o modificar un rol -->
	<dialog class="dialog" id="role-dialog"
		aria-labelledby="role-dialog-title">
	<form id="role-form" novalidate>
		<header class="dialog-header">
			<div>
				<h2 id="role-dialog-title">Agregar rol</h2>
				<p>Describe al personaje y qué material debe enviar el artista.</p>
			</div>
			<button class="dialog-close" type="button" data-close-role-dialog
				aria-label="Cerrar">
				<svg class="icon-inline" viewBox="0 0 24 24" fill="none"
					stroke="currentColor" stroke-width="1.8" aria-hidden="true">
            <path d="m6 6 12 12M18 6 6 18"></path>
          </svg>
			</button>
		</header>

		<div class="dialog-body">
			<div class="auth-message" id="role-error" role="alert"
				data-type="error" hidden style="margin-bottom: 16px"></div>
			<div class="form-grid">
				<label class="field span-2"><span class="field-label">Nombre
						del personaje</span><input class="input" id="role-f-name" maxlength="80"
					placeholder="Ej. Adela"></label> <label class="field"><span
					class="field-label">Perfil breve</span><input class="input"
					id="role-f-profile" maxlength="80"
					placeholder="Ej. Joven adulta · Principal"></label> <label
					class="field"><span class="field-label">Rango de edad</span><input
					class="input" id="role-f-age" maxlength="40"
					placeholder="Ej. 18–30 años"></label> <label class="field span-2"><span
					class="field-label">Género del personaje</span><select
					class="select" id="role-f-gender"><option>Cualquier
							género</option>
						<option>Femenino</option>
						<option>Masculino</option>
						<option>No binario</option></select></label> <label class="field span-2"><span
					class="field-label">Descripción del rol</span>
				<textarea class="textarea" id="role-f-description"></textarea></label> <label
					class="field span-2"><span class="field-label">Material
						específico</span>
				<textarea class="textarea" id="role-f-requirement"
						placeholder="Ej. Self-tape con la escena adjunta."></textarea></label>
			</div>
		</div>

		<footer class="dialog-actions">
			<button class="button secondary" type="button"
				data-close-role-dialog>Cancelar</button>
			<button class="button" type="submit" id="role-save">Guardar rol</button>
		</footer>
	</form>
	</dialog>
</body>
</html>
