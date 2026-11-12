<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.sql.*"%>
<%
    // =========================================================================
    // LÓGICA DE SERVIDOR (JAVA / JDBC) - PERFIL DE USUARIO
    // Procesamos la actualización de datos del perfil cuando el usuario 
    // hace clic en "Guardar cambios" y enviamos la petición por POST.
    // =========================================================================
    String mensajeFeedback = "";
    String tipoMensaje = ""; // "success" o "error"

    // Parámetros de conexión local a la base de datos 'stagelink' en XAMPP
    String url = "jdbc:mysql://localhost:3306/stagelink?useSSL=false&serverTimezone=UTC";
    String usuarioDb = "root";
    String passwordDb = "";

    // Si el usuario envía la actualización del perfil mediante POST
    if ("POST".equalsIgnoreCase(request.getMethod())) {
        String displayName = request.getParameter("displayName");
        String city = request.getParameter("city");
        String bio = request.getParameter("bio");
        String phone = request.getParameter("phone");

        try {
            // Cargamos el Driver JDBC configurado en Maven
            Class.forName("com.mysql.cj.jdbc.Driver");
            Connection conn = DriverManager.getConnection(url, usuarioDb, passwordDb);

            // Sentencia SQL para actualizar la información principal del usuario
            // (Nota: Ajusta el identificador del usuario según tu sesión activa o ID en la BD)
            String sql = "UPDATE usuario SET nombre = ?, ciudad = ?, biografia = ?, telefono = ? WHERE id = 1";
            PreparedStatement stmt = conn.prepareStatement(sql);
            stmt.setString(1, displayName);
            stmt.setString(2, city);
            stmt.setString(3, bio);
            stmt.setString(4, phone);
            
            stmt.executeUpdate();
            stmt.close();
            conn.close();

            mensajeFeedback = "Perfil actualizado correctamente en la base de datos.";
            tipoMensaje = "success";
        } catch (Exception e) {
            mensajeFeedback = "Error al actualizar el perfil: " + e.getMessage();
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
	content="Edita tu perfil profesional de StageLink Auditions.">
<title>Mi perfil · StageLink</title>

<!-- Icono vectorial SVG de la plataforma -->
<link rel="icon" type="image/svg+xml"
	href="data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 64 64'%3E%3Crect width='64' height='64' rx='16' fill='%230a0a0a'/%3E%3Cpath d='M18 18h30v8H27v7h17v8H27v10h-9z' fill='white'/%3E%3C/svg%3E">

<!-- Hoja de estilos general + estilos exclusivos de Productora (en ese orden) -->
<link rel="stylesheet" href="${pageContext.request.contextPath}/css/styles.css">
<link rel="stylesheet" href="${pageContext.request.contextPath}/css/producer.css">

<!-- Scripts: shell compartido, datos simulados y lógica de perfil de Productora (en orden) -->
<script src="${pageContext.request.contextPath}/javascript/app.js" defer></script>
<script src="${pageContext.request.contextPath}/javascript/producer-data.js" defer></script>
<script src="${pageContext.request.contextPath}/javascript/producer-profile.js" defer></script>
</head>
<body data-page="profile">
	<!-- Enlace de accesibilidad para saltar directamente al contenido principal -->
	<a class="skip-link" href="#main-content">Saltar al contenido</a>

	<div class="app-frame">
		<!-- Barra lateral de navegación compartida -->
		<aside class="sidebar" id="sidebar"></aside>

		<div class="main-column">
			<!-- Barra superior -->
			<header class="topbar" id="topbar"></header>

			<main class="content" id="main-content">
				<div class="page-heading">
					<div>
						<h1>Mi perfil</h1>
						<p>Mantén actualizados tus datos para postularte o publicar
							convocatorias con menos pasos.</p>
					</div>
				</div>

				<!-- Mensaje de feedback si se guardaron los cambios con éxito o ocurrió un error -->
				<% if (!mensajeFeedback.isEmpty()) { %>
				<div class="auth-message" data-type="<%= tipoMensaje %>"
					style="margin-bottom: 20px;">
					<%= mensajeFeedback %>
				</div>
				<% } %>

				<!-- Mensaje del guardado simulado de Productora (lo gestiona producer-profile.js) -->
				<div class="auth-message" id="profile-message" role="status"
					data-type="success" hidden style="margin-bottom: 20px;"></div>

				<div class="profile-layout">
					<!-- Columna izquierda: Panel de avatar y foto de perfil -->
					<aside class="card panel profile-card">
						<div class="profile-avatar-large" id="profile-avatar-preview"
							aria-live="polite"></div>
						<h2 id="profile-preview-name">Nombre de perfil</h2>
						<p id="profile-preview-role">Artista escénico</p>
						<label class="button secondary" for="profile-avatar-input">Cambiar
							foto</label> <input class="file-input" id="profile-avatar-input"
							type="file" accept="image/png,image/jpeg,image/webp">
					</aside>

					<!-- Columna derecha: Formulario completo de datos del perfil -->
					<form class="card panel" id="profile-form" action="profile.jsp"
						method="POST">

						<!-- Tipo de cuenta (Informativo / Bloqueado) -->
						<section id="tipo-cuenta" aria-labelledby="role-section-title">
							<h2 class="section-title" id="role-section-title">Tipo de
								cuenta</h2>
							<p class="form-note">El tipo de cuenta se definió al
								registrarte y no puede cambiarse desde el perfil.</p>
							<div class="card" style="margin-top: 12px; padding: 18px"
								aria-live="polite">
								<strong id="account-type-label">Tipo de cuenta</strong>
								<p class="form-note" id="account-type-description"
									style="margin-top: 4px"></p>
							</div>
						</section>

						<!-- Suscripción de la productora (la muestra y rellena producer-profile.js) -->
						<section id="subscription-section" style="margin-top: 28px"
							aria-labelledby="subscription-title" hidden>
							<h2 class="section-title" id="subscription-title">Suscripción</h2>
							<div class="card subscription-card" id="subscription-card"
								aria-live="polite"></div>
						</section>

						<!-- Información principal editable -->
						<section style="margin-top: 28px"
							aria-labelledby="profile-data-title">
							<h2 class="section-title" id="profile-data-title">Información
								principal</h2>
							<div class="form-grid">
								<label class="field"><span class="field-label">Nombre
										visible</span><input class="input" name="displayName" required
									autocomplete="name"></label> <label class="field"><span
									class="field-label">Ciudad</span><input class="input"
									name="city" required autocomplete="address-level2"></label> <label
									class="field span-2"><span class="field-label">Biografía</span>
								<textarea class="textarea" name="bio" required></textarea></label> <label
									class="field"><span class="field-label">Teléfono</span><input
									class="input" name="phone" autocomplete="tel"></label>
							</div>
						</section>

						<!-- Campos específicos para Artistas -->
						<section id="actor-fields" style="margin-top: 28px"
							aria-labelledby="actor-data-title">
							<h2 class="section-title" id="actor-data-title">Información
								artística</h2>
							<div class="form-grid">
								<label class="field"><span class="field-label">Fecha
										de nacimiento</span><input class="input" type="date" name="birthdate"></label>
								<label class="field"><span class="field-label">Género
										para requisitos de casting</span><select class="select" name="gender"><option
											value="">Prefiero no indicarlo</option>
										<option>Femenino</option>
										<option>Masculino</option>
										<option>No binario</option></select></label> <label class="field"><span
									class="field-label">Estatura</span><input class="input"
									name="height" placeholder="Ej. 165 cm"></label> <label
									class="field"><span class="field-label">Rango de
										representación</span><input class="input" name="ageRange"
									placeholder="Ej. 18–28 años"></label> <label class="field"><span
									class="field-label">Idiomas</span><input class="input"
									name="languages"></label> <label class="field span-2"><span
									class="field-label">Habilidades</span><input class="input"
									name="skills" placeholder="Actuación, canto, danza…"></label>
							</div>

							<!-- Historial de experiencia -->
							<div class="history-builder">
								<h3 class="section-title">Experiencia en producciones</h3>
								<p class="form-note">Registra obras, cortos o montajes que
									formen parte de tu hoja de vida.</p>
								<div class="form-grid" style="margin-top: 14px">
									<label class="field"><span class="field-label">Producción</span><input
										class="input" name="historyProduction"
										placeholder="Ej. La vida es sueño"></label> <label
										class="field"><span class="field-label">Compañía</span><input
										class="input" name="historyCompany"></label> <label
										class="field"><span class="field-label">Personaje
											o función</span><input class="input" name="historyRole"></label> <label
										class="field"><span class="field-label">Año</span><input
										class="input" type="number" name="historyYear" min="1900"
										max="2200" placeholder="2026"></label> <label
										class="field span-2"><span class="field-label">Descripción
											breve</span><input class="input" name="historyDescription"
										placeholder="Participación, director o reconocimiento"></label>
								</div>
								<button class="button secondary small" id="add-work-history"
									type="button" style="margin-top: 12px">Agregar
									experiencia</button>
								<div class="management-list" id="work-history-list"
									style="margin-top: 14px"></div>
							</div>
						</section>

						<!-- Campos específicos para Productoras (ocultos por defecto según el rol) -->
						<section id="producer-fields" style="margin-top: 28px"
							aria-labelledby="producer-data-title" hidden>
							<h2 class="section-title" id="producer-data-title">Información
								de la compañía</h2>

							<!-- Estado de aprobación de la cuenta (Fase 2, sección 1.4-D) -->
							<div id="company-approval" style="margin-bottom: 16px"></div>

							<div class="form-grid">
								<label class="field"><span class="field-label">Tipo
										de compañía</span><input class="input" name="companyType"></label> <label
									class="field"><span class="field-label">Tamaño
										de la compañía</span><select class="select" name="companySize"><option
											value="">Sin especificar</option>
										<option>Independiente</option>
										<option>Pequeña</option>
										<option>Mediana</option>
										<option>Grande</option></select></label> <label class="field"><span
									class="field-label">Persona de contacto</span><input
									class="input" name="contactName"></label> <label class="field"><span
									class="field-label">Correo de contacto</span><input
									class="input" type="email" name="contactEmail"
									autocomplete="email"></label> <label class="field span-2"><span
									class="field-label">Sitio web</span><input class="input"
									type="url" name="website" placeholder="https://"></label>
							</div>
						</section>

						<!-- Botones de acción del formulario -->
						<div class="form-actions">
							<button class="button danger small" id="reset-demo" type="button">Restablecer
								demo</button>
							<button class="button" type="submit">Guardar cambios</button>
						</div>
					</form>
				</div>
			</main>

			<!-- Barra de navegación inferior móvil -->
			<nav class="mobile-nav" id="mobile-nav"></nav>
		</div>
	</div>
</body>
</html>
