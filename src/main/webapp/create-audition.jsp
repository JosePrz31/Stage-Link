<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.sql.*"%>
<%
    // =========================================================================
    // 1. LÓGICA DE SERVIDOR (JAVA / JDBC) - CREAR CONVOCATORIA
    // Procesamos el formulario cuando la productora hace clic en "Publicar"
    // =========================================================================
    String mensajeFeedback = "";
    String tipoMensaje = ""; // "success" o "error"

    if ("POST".equalsIgnoreCase(request.getMethod())) {
        // Capturamos los campos principales del proyecto y la logística
        String title = request.getParameter("title");
        String type = request.getParameter("type");
        String description = request.getParameter("description");
        String compensationType = request.getParameter("compensationType");
        String compensation = request.getParameter("compensation");
        String requirements = request.getParameter("requirements");
        
        String location = request.getParameter("location");
        String district = request.getParameter("district");
        String deadline = request.getParameter("deadline");
        String date = request.getParameter("date");
        String time = request.getParameter("time");

        // Parámetros de conexión local a XAMPP
        String url = "jdbc:mysql://localhost:3306/stagelink?useSSL=false&serverTimezone=UTC";
        String usuarioDb = "root";
        String passwordDb = "";

        try {
            // Cargamos el Driver JDBC de MySQL configurado en el pom.xml
            Class.forName("com.mysql.cj.jdbc.Driver");
            Connection conn = DriverManager.getConnection(url, usuarioDb, passwordDb);

            // Sentencia SQL para insertar la convocatoria en la base de datos
            // (Nota: Asegúrate de que los nombres de las columnas coincidan con tu tabla en MySQL)
            String sql = "INSERT INTO audicion (titulo, tipo, descripcion, tipo_compensacion, detalle_pago, requisitos, lugar, distrito, fecha_limite, fecha_audicion, hora) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";
            
            PreparedStatement stmt = conn.prepareStatement(sql);
            stmt.setString(1, title);
            stmt.setString(2, type);
            stmt.setString(3, description);
            stmt.setString(4, compensationType);
            stmt.setString(5, compensation);
            stmt.setString(6, requirements);
            stmt.setString(7, location);
            stmt.setString(8, district);
            stmt.setString(9, deadline);
            stmt.setString(10, date);
            stmt.setString(11, time);
            
            stmt.executeUpdate();
            stmt.close();
            conn.close();

            // Redirigimos al feed general tras publicar con éxito
            response.sendRedirect("feed.jsp");
            return;

        } catch (Exception e) {
            mensajeFeedback = "Error al publicar la convocatoria: " + e.getMessage();
            tipoMensaje = "error";
        }
    }
%>
<!doctype html>
<html lang="es">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<meta name="description"
	content="Publica una convocatoria teatral detallada en StageLink Auditions.">
<title>Crear convocatoria · StageLink</title>

<!-- Icono vectorial SVG de la plataforma -->
<link rel="icon" type="image/svg+xml"
	href="data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 64 64'%3E%3Crect width='64' height='64' rx='16' fill='%230a0a0a'/%3E%3Cpath d='M18 18h30v8H27v7h17v8H27v10h-9z' fill='white'/%3E%3C/svg%3E">

<!-- Hoja de estilos general + estilos exclusivos de Productora (en ese orden) -->
<link rel="stylesheet" href="${pageContext.request.contextPath}/css/styles.css">
<link rel="stylesheet" href="${pageContext.request.contextPath}/css/producer.css">

<!-- Scripts: shell compartido, datos simulados y lógica de la página (se ejecutan en orden) -->
<script src="${pageContext.request.contextPath}/javascript/app.js" defer></script>
<script src="${pageContext.request.contextPath}/javascript/producer-data.js" defer></script>
<script src="${pageContext.request.contextPath}/javascript/producer-create.js" defer></script>
</head>
<body data-page="create">
	<!-- Enlace de accesibilidad para saltar directamente al contenido -->
	<a class="skip-link" href="#main-content">Saltar al contenido</a>

	<div class="app-frame">
		<!-- Barra lateral de navegación -->
		<aside class="sidebar" id="sidebar"></aside>

		<div class="main-column">
			<!-- Barra superior -->
			<header class="topbar" id="topbar"></header>

			<main class="content" id="main-content">
				<div class="page-heading" id="create-heading">
					<div>
						<h1>Crear convocatoria</h1>
						<p>Completa la información en cuatro pasos. Los campos están
							agrupados para que el proceso sea claro y rápido.</p>
					</div>
					<!-- Aquí producer-create.js muestra la insignia de suscripción -->
					<div class="heading-actions" id="create-sub-status"></div>
				</div>

				<!-- Mensaje de feedback si ocurre un error al registrar en la base de datos -->
				<% if (!mensajeFeedback.isEmpty()) { %>
				<div class="auth-message" data-type="<%= tipoMensaje %>"
					style="margin-bottom: 20px;">
					<%= mensajeFeedback %>
				</div>
				<% } %>

				<!-- Control de rol: Restringe visualmente si el usuario conectado es artista -->
				<section class="role-guard card" id="create-role-guard" hidden>
					<div class="role-guard-inner">
						<span class="empty-icon"> <svg viewBox="0 0 24 24"
								fill="none" stroke="currentColor" stroke-width="1.8"
								aria-hidden="true">
                <path
									d="M4 21V4h11v17M15 9h5v12M8 8h3M8 12h3M8 16h3M2 21h20"></path>
              </svg>
						</span>
						<h2>Función exclusiva para productoras</h2>
						<p>Tu cuenta está registrada como artista y no puede publicar
							convocatorias. El tipo de cuenta no se puede cambiar desde el
							perfil.</p>
						<a class="button secondary" href="feed.jsp">Volver a
							audiciones</a>
					</div>
				</section>

				<!-- Control de suscripción: se muestra si la productora aún no tiene suscripción activa -->
				<section class="card" id="create-sub-guard" hidden>
					<div class="sub-guard">
						<div class="sub-guard-inner">
							<span class="empty-icon" aria-hidden="true"> <svg
									viewBox="0 0 24 24" fill="none" stroke="currentColor"
									stroke-width="1.8" stroke-linecap="round"
									stroke-linejoin="round">
                  <rect x="2" y="5" width="20" height="14" rx="2"></rect>
                  <path d="M2 10h20M6 15h4"></path>
                </svg>
							</span>
							<h2>Necesitas una suscripción para publicar convocatorias</h2>
							<p>Para crear y publicar convocatorias debes activar una
								suscripción de productora. Elige un plan, completa el pago y
								vuelve aquí para empezar.</p>
							<ul class="sub-guard-benefits">
								<li><svg viewBox="0 0 24 24" fill="none"
										stroke="currentColor" stroke-width="2" stroke-linecap="round"
										stroke-linejoin="round" aria-hidden="true">
                    <path d="m5 12 5 5 9-10"></path>
                  </svg><span>Publica convocatorias y define todos sus roles</span></li>
								<li><svg viewBox="0 0 24 24" fill="none"
										stroke="currentColor" stroke-width="2" stroke-linecap="round"
										stroke-linejoin="round" aria-hidden="true">
                    <path d="m5 12 5 5 9-10"></path>
                  </svg><span>Recibe y gestiona las postulaciones de los artistas</span></li>
								<li><svg viewBox="0 0 24 24" fill="none"
										stroke="currentColor" stroke-width="2" stroke-linecap="round"
										stroke-linejoin="round" aria-hidden="true">
                    <path d="m5 12 5 5 9-10"></path>
                  </svg><span>Revisa portafolios y videos sin descargas externas</span></li>
							</ul>
							<div class="sub-guard-actions">
								<a class="button" href="subscription.jsp">Ver planes y
									suscribirme</a> <a class="button secondary" href="feed.jsp">Volver
									a convocatorias</a>
							</div>
						</div>
					</div>
				</section>

				<!-- Contenedor principal del formulario de creación multipasos -->
				<section id="create-form-container">
					<ol class="stepper" aria-label="Progreso de la convocatoria">
						<li class="step is-active"><span class="step-number">1</span><span
							class="step-label">Proyecto</span></li>
						<li class="step"><span class="step-number">2</span><span
							class="step-label">Logística</span></li>
						<li class="step"><span class="step-number">3</span><span
							class="step-label">Roles</span></li>
						<li class="step"><span class="step-number">4</span><span
							class="step-label">Revisión</span></li>
					</ol>

					<!-- El formulario envía los datos mediante POST a este mismo archivo JSP -->
					<form class="card" id="create-audition-form"
						action="create-audition.jsp" method="POST">

						<!-- PASO 1: Información general del proyecto -->
						<section class="form-step" data-step="0">
							<header class="surface-header">
								<h2>Información del proyecto</h2>
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
												experiencia</option></select></label> <label class="field" id="compensation-field"><span
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
								<div class="form-actions">
									<a class="button secondary" href="feed.jsp">Cancelar</a>
									<button class="button" type="button" data-next-step>Siguiente</button>
								</div>
							</div>
						</section>

						<!-- PASO 2: Fechas, horas y ubicación -->
						<section class="form-step" data-step="1" hidden>
							<header class="surface-header">
								<h2>Fecha y ubicación</h2>
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
								<div class="form-actions">
									<button class="button secondary" type="button" data-prev-step>Anterior</button>
									<button class="button" type="button" data-next-step>Siguiente</button>
								</div>
							</div>
						</section>

						<!-- PASO 3: Roles del elenco y materiales requeridos -->
						<section class="form-step" data-step="2" hidden>
							<header class="surface-header">
								<h2>Roles y materiales</h2>
							</header>
							<div class="surface-body">
								<fieldset class="fieldset">
									<legend>Material general solicitado</legend>
									<p class="form-note">Marca los elementos que deberán
										acompañar cada postulación.</p>
									<div class="check-grid" style="margin-top: 12px">
										<label class="check-card"><input type="checkbox"
											name="materials" value="Headshot" checked> Headshot</label> <label
											class="check-card"><input type="checkbox"
											name="materials" value="CV artístico" checked> CV
											artístico</label> <label class="check-card"><input
											type="checkbox" name="materials" value="Reel de actuación">
											Reel de actuación</label> <label class="check-card"><input
											type="checkbox" name="materials" value="Video de canto">
											Video de canto</label>
									</div>
								</fieldset>

								<div class="role-builder" style="margin-top: 24px">
									<section aria-labelledby="new-role-title">
										<h3 class="section-title" id="new-role-title">Agregar un
											rol</h3>
										<div class="form-grid">
											<label class="field"><span class="field-label">Nombre
													del personaje</span><input class="input" id="role-name"
												name="roleName" placeholder="Ej. Adela"></label> <label
												class="field"><span class="field-label">Perfil
													breve</span><input class="input" name="roleProfile"
												placeholder="Ej. Joven adulta · Principal"></label> <label
												class="field"><span class="field-label">Rango
													de edad</span><input class="input" name="roleAge"
												placeholder="Ej. 18–30 años"></label> <label class="field"><span
												class="field-label">Género del personaje</span><select
												class="select" name="roleGender"><option>Cualquier
														género</option>
													<option>Femenino</option>
													<option>Masculino</option>
													<option>No binario</option></select></label> <label class="field span-2"><span
												class="field-label">Descripción del rol</span>
											<textarea class="textarea" name="roleDescription"></textarea></label>
											<label class="field span-2"><span class="field-label">Material
													específico</span>
											<textarea class="textarea" name="roleRequirement"
													placeholder="Ej. Self-tape con la escena adjunta."></textarea></label>
										</div>
										<button class="button secondary" id="add-role" type="button"
											style="margin-top: 14px">Agregar rol</button>
									</section>
									<aside aria-labelledby="added-roles-title">
										<h3 class="section-title" id="added-roles-title">Roles
											agregados</h3>
										<div class="management-list" id="draft-role-list"></div>
									</aside>
								</div>
								<div class="form-actions">
									<button class="button secondary" type="button" data-prev-step>Anterior</button>
									<button class="button" type="button" data-next-step>Revisar</button>
								</div>
							</div>
						</section>

						<!-- PASO 4: Revisión final y botón de envío al servidor -->
						<section class="form-step" data-step="3" hidden>
							<header class="surface-header">
								<h2>Revisar y publicar</h2>
							</header>
							<div class="surface-body detail-copy">
								<div id="audition-review"></div>
								<p class="form-note">Al publicar, la convocatoria aparecerá
									en el feed y quedará disponible en Gestión.</p>
								<div class="form-actions">
									<button class="button secondary" type="button" data-prev-step>Anterior</button>
									<button class="button" type="submit">Publicar
										convocatoria</button>
								</div>
							</div>
						</section>
					</form>
				</section>
			</main>

			<!-- Barra de navegación inferior móvil -->
			<nav class="mobile-nav" id="mobile-nav"></nav>
		</div>
	</div>
</body>
</html>
