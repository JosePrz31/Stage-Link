<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.sql.*"%>
<%
    // =========================================================================
    // LÓGICA DE SERVIDOR (JAVA / JDBC) - NOTIFICACIONES
    // Consultamos la tabla de notificaciones en la base de datos local de MySQL
    // para listar los cambios de estado y confirmaciones del usuario.
    // =========================================================================
    String errorNotificaciones = "";
    
    // Parámetros de conexión local a XAMPP
    String url = "jdbc:mysql://localhost:3306/stagelink?useSSL=false&serverTimezone=UTC";
    String usuarioDb = "root";
    String passwordDb = "";
%>
<!doctype html>
<html lang="es">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<meta name="description"
	content="Revisa cambios de estado y nuevas oportunidades en StageLink Auditions.">
<title>Notificaciones · StageLink</title>

<!-- Icono vectorial SVG de la plataforma -->
<link rel="icon" type="image/svg+xml"
	href="data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 64 64'%3E%3Crect width='64' height='64' rx='16' fill='%230a0a0a'/%3E%3Cpath d='M18 18h30v8H27v7h17v8H27v10h-9z' fill='white'/%3E%3C/svg%3E">

<!-- Hoja de estilos principal (ajustada a la ruta relativa '../css/styles.css') -->
<link rel="stylesheet" href="../css/styles.css">

<!-- Script local de interfaz para la gestión visual -->
<script src="../javascript/app.js" defer></script>
</head>
<body data-page="notifications">
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
						<h1>Notificaciones</h1>
						<p>Cada postulación tiene un cierre claro: aquí recibirás
							confirmaciones y cambios de estado.</p>
					</div>
					<button class="button secondary" id="mark-all-read" type="button">Marcar
						todas como leídas</button>
				</div>

				<!-- 
          SECCIÓN DINÁMICA DE NOTIFICACIONES (CONSULTA A MYSQL)
        -->
				<section class="notification-list" id="notification-list"
					aria-label="Lista de notificaciones">
					<%
            try {
                Class.forName("com.mysql.cj.jdbc.Driver");
                Connection conn = DriverManager.getConnection(url, usuarioDb, passwordDb);
                
                // Consulta para obtener las notificaciones más recientes (ajusta el nombre de tu tabla si difiere)
                String sql = "SELECT * FROM notificacion ORDER BY id DESC LIMIT 20";
                PreparedStatement stmt = conn.prepareStatement(sql);
                ResultSet rs = stmt.executeQuery();

                boolean hayNotificaciones = false;

                while (rs.next()) {
                    hayNotificaciones = true;
                    String mensaje = rs.getString("mensaje");
                    String fecha = rs.getString("fecha");
                    boolean leida = rs.getBoolean("leida");
          %>
					<!-- Tarjeta de notificación individual generada por Java -->
					<article class="card notification-card"
						style="padding: 16px; margin-bottom: 12px; <%= leida ? "opacity: 0.7;" : "border-left: 4px solid #0a0a0a;" %>">
						<p style="margin: 0; font-size: 0.95rem;"><%= mensaje %></p>
						<small style="color: #666; display: block; margin-top: 8px;"><%= fecha != null ? fecha : "Reciente" %></small>
					</article>
					<%
                }

                if (!hayNotificaciones) {
          %>
					<div class="empty-state" style="padding: 40px; text-align: center;">
						<p>No tienes notificaciones pendientes.</p>
					</div>
					<%
                }

                rs.close();
                stmt.close();
                conn.close();
            } catch (Exception e) {
          %>
					<div class="auth-message" data-type="error">No se pudieron
						cargar las notificaciones desde la base de datos local.</div>
					<%
            }
          %>
				</section>
			</main>

			<!-- Barra de navegación inferior móvil -->
			<nav class="mobile-nav" id="mobile-nav"></nav>
		</div>
	</div>
</body>
</html>