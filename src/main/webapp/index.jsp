<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*"%>
<%
    // =========================================================================
    // LÓGICA DE SERVIDOR (JAVA / JDBC) - PÁGINA DE BIENVENIDA (INDEX)
    // =========================================================================
    boolean conexionActiva = false;
    
    // Parámetros de conexión local a XAMPP
    String url = "jdbc:mysql://localhost:3306/stagelink?useSSL=false&serverTimezone=UTC";
    String usuarioDb = "root";
    String passwordDb = "";

    try {
        // Cargamos el Driver JDBC configurado en Maven
        Class.forName("com.mysql.cj.jdbc.Driver");
        Connection conn = DriverManager.getConnection(url, usuarioDb, passwordDb);
        
        if (conn != null && !conn.isClosed()) {
            conexionActiva = true;
            conn.close();
        }
    } catch (Exception e) {
        conexionActiva = false;
    }
%>
<!doctype html>
<html lang="es">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<meta name="description"
	content="StageLink Auditions conecta artistas escénicos con convocatorias teatrales en Panamá.">
<title>StageLink Auditions</title>

<!-- Icono vectorial SVG de la plataforma -->
<link rel="icon" type="image/svg+xml"
	href="data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 64 64'%3E%3Crect width='64' height='64' rx='16' fill='%230a0a0a'/%3E%3Cpath d='M18 18h30v8H27v7h17v8H27v10h-9z' fill='white'/%3E%3C/svg%3E">

<!-- Hoja de estilos principal con ruta dinámica -->
<link rel="stylesheet" href="${pageContext.request.contextPath}/css/styles.css">

<!-- Script local de interfaz -->
<script src="${pageContext.request.contextPath}/javascript/app.js" defer></script>
</head>
<body data-page="welcome">
	<main class="welcome-page">
		<div class="welcome-shell">

			<!-- Sección izquierda: Identidad de marca -->
			<section class="welcome-copy" aria-labelledby="welcome-title">
				<a class="brand" href="${pageContext.request.contextPath}/index.jsp" aria-label="StageLink Auditions">
					<span class="brand-mark">SL</span> <span>StageLink<small>Auditions</small></span>
				</a>
				<h1 id="welcome-title">
					Tu talento.<br>
					<span>La escena.</span>
				</h1>
				<p>Convocatorias, portafolio y seguimiento profesional para el
					ecosistema teatral de Panamá.</p>
			</section>

			<!-- Sección derecha: Selección de rol inicial -->
			<section class="role-entry" aria-labelledby="role-title">
				<h2 id="role-title">¿Cómo usarás StageLink?</h2>
				<p>Elige cuidadosamente el tipo de cuenta. No podrás cambiarlo
					después desde tu perfil.</p>

				<div class="entry-roles">
					<!-- Opción de acceso para Artistas (apunta directamente a auth.jsp) -->
					<button class="entry-role" type="button" data-enter-role="actor"
						onclick="window.location.href='${pageContext.request.contextPath}/auth.jsp?mode=register&role=actor'">
						<span class="entry-role-icon" aria-hidden="true"> 
							<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8">
				                <circle cx="12" cy="8" r="4"></circle>
				                <path d="M4 21a8 8 0 0 1 16 0"></path>
				            </svg>
						</span> 
						<span class="entry-role-copy"> 
							<strong>Soy artista</strong> 
							<span>Quiero buscar audiciones, mostrar mi trabajo y postularme.</span>
						</span>
						<svg class="icon-inline" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" aria-hidden="true">
              				<path d="m9 18 6-6-6-6"></path>
            			</svg>
					</button>

					<!-- Opción de acceso para Productoras o Compañías -->
					<button class="entry-role" type="button" data-enter-role="producer"
						onclick="window.location.href='${pageContext.request.contextPath}/auth.jsp?mode=register&role=producer'">
						<span class="entry-role-icon" aria-hidden="true"> 
							<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8">
				                <path d="M4 21V4h11v17M15 9h5v12M8 8h3M8 12h3M8 16h3M18 13h.01M18 17h.01M2 21h20"></path>
				            </svg>
						</span> 
						<span class="entry-role-copy"> 
							<strong>Soy productora o compañía</strong> 
							<span>Quiero publicar convocatorias y gestionar candidatos.</span>
						</span>
						<svg class="icon-inline" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" aria-hidden="true">
              				<path d="m9 18 6-6-6-6"></path>
            			</svg>
					</button>
				</div>

				<!-- Botón alternativo para reanudar sesión previa -->
				<a class="button secondary" id="resume-session" href="${pageContext.request.contextPath}/feed.jsp"
					hidden style="width: 100%; margin-top: 14px"></a>

				<!-- Enlace directo para iniciar sesión -->
				<a class="text-button" id="sign-in-link"
					href="${pageContext.request.contextPath}/auth.jsp?mode=login">
					Ya tengo una cuenta · Iniciar sesión
				</a>

				<!-- Indicador dinámico de estado de conexión -->
				<p class="demo-note" id="welcome-mode-note">
					<% if (conexionActiva) { %>
					✅ Conexión con base de datos MySQL local activa.
					<% } else { %>
					⚠️ No se pudo conectar a MySQL (Verifica XAMPP).
					<% } %>
				</p>
			</section>

		</div>
	</main>
</body>
</html>
