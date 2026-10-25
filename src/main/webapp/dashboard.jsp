<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.sql.*"%>
<%
    // =========================================================================
    // LÓGICA DE SERVIDOR (JAVA / JDBC) - DASHBOARD / GESTIÓN
    // Aquí puedes realizar consultas dinámicas para rellenar listados, 
    // estadísticas o verificar el rol del usuario conectado.
    // =========================================================================
    String errorDashboard = "";
    
    // Parámetros de conexión local a la base de datos 'stagelink' en XAMPP
    String url = "jdbc:mysql://localhost:3306/stagelink?useSSL=false&serverTimezone=UTC";
    String usuarioDb = "root";
    String passwordDb = "";

    try {
        // Cargamos el Driver JDBC de MySQL configurado en Maven
        Class.forName("com.mysql.cj.jdbc.Driver");
        Connection conn = DriverManager.getConnection(url, usuarioDb, passwordDb);

        // Ejemplo de consulta general para verificar o precargar datos del panel
        // (Por ejemplo, podríamos contar el total de audiciones o postulaciones)
        String sqlCheck = "SELECT COUNT(*) AS total FROM audicion";
        PreparedStatement stmt = conn.prepareStatement(sqlCheck);
        ResultSet rs = stmt.executeQuery();
        
        int totalAudiciones = 0;
        if (rs.next()) {
            totalAudiciones = rs.getInt("total");
        }
        
        rs.close();
        stmt.close();
        conn.close();

    } catch (Exception e) {
        errorDashboard = "No se pudieron cargar los datos del panel: " + e.getMessage();
    }
%>
<!doctype html>
<html lang="es">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<meta name="description"
	content="Da seguimiento a postulaciones o gestiona candidatos en StageLink Auditions.">
<title>Gestión · StageLink</title>

<!-- Icono vectorial SVG de la plataforma -->
<link rel="icon" type="image/svg+xml"
	href="data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 64 64'%3E%3Crect width='64' height='64' rx='16' fill='%230a0a0a'/%3E%3Cpath d='M18 18h30v8H27v7h17v8H27v10h-9z' fill='white'/%3E%3C/svg%3E">

<!-- Hoja de estilos principal (ajustada a la ruta relativa '../css/styles.css') -->
<link rel="stylesheet" href="../css/styles.css">

<!-- Script local de interfaz para alternar vistas entre actor y productora -->
<script src="../javascript/app.js" defer></script>
</head>
<body data-page="dashboard">
	<!-- Enlace de accesibilidad para saltar directamente al contenido -->
	<a class="skip-link" href="#main-content">Saltar al contenido</a>

	<div class="app-frame">
		<!-- Barra lateral de navegación compartida -->
		<aside class="sidebar" id="sidebar"></aside>

		<div class="main-column">
			<!-- Barra superior -->
			<header class="topbar" id="topbar"></header>

			<main class="content" id="main-content">

				<!-- Mensaje de error controlado si falla la conexión con la BD -->
				<% if (!errorDashboard.isEmpty()) { %>
				<div class="auth-message" data-type="error"
					style="margin-bottom: 20px;">
					<%= errorDashboard %>
				</div>
				<% } %>

				<!-- ================================================================= -->
				<!-- 1. VISTA DEL DASHBOARD PARA EL ARTISTA (ACTOR) -->
				<!-- ================================================================= -->
				<section id="actor-dashboard">
					<div class="page-heading">
						<div>
							<h1>Mis postulaciones</h1>
							<p>Consulta el estado de cada proceso sin quedarte en una
								espera indefinida.</p>
						</div>
						<a class="button" href="feed.jsp">Buscar audiciones</a>
					</div>

					<!-- Contenedor para las estadísticas de postulaciones del artista -->
					<div class="stats-grid" id="application-stats"></div>

					<!-- Listado dinámico de postulaciones enviadas -->
					<div class="application-list" id="application-list"></div>
				</section>

				<!-- ================================================================= -->
				<!-- 2. VISTA DEL DASHBOARD PARA LA PRODUCTORA (COMPAÑÍA) -->
				<!-- ================================================================= -->
				<section id="producer-dashboard" hidden>
					<div class="page-heading">
						<div>
							<h1>Gestión de talento</h1>
							<p>Revisa perfiles, califica candidatos y registra notas
								privadas en un solo lugar.</p>
						</div>
						<a class="button" href="create-audition.jsp">Nueva
							convocatoria</a>
					</div>

					<div class="dashboard-grid">
						<!-- Columna izquierda: Listado de convocatorias creadas por la productora -->
						<aside>
							<h2 class="section-title">Mis convocatorias</h2>
							<div class="management-list" id="management-list"></div>
						</aside>

						<!-- Columna derecha: Detalle de candidatos inscritos en la audición seleccionada -->
						<section>
							<label class="field" style="margin-bottom: 16px"> <span
								class="field-label">Candidatos de</span> <select class="select"
								id="managed-audition"></select>
							</label>

							<!-- Estadísticas de candidatos postulados -->
							<div class="stats-grid" id="candidate-stats"></div>

							<!-- Listado de perfiles de los aspirantes -->
							<div class="candidate-list" id="candidate-list"></div>
						</section>
					</div>
				</section>

			</main>

			<!-- Barra de navegación inferior móvil -->
			<nav class="mobile-nav" id="mobile-nav"></nav>
		</div>
	</div>
</body>
</html>
