<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.sql.*"%>
<%
    // =========================================================================
    // 1. CAPTURA DE PARÁMETROS Y CONEXIÓN A LA BASE DE DATOS
    // Obtenemos el ID de la audición pasado por la URL (ej: audition.jsp?id=1)
    // para consultar la información específica en la base de datos de MySQL.
    // =========================================================================
    String idAudicion = request.getParameter("id");
    String tituloAudicion = "";
    String descripcionAudicion = "";

    // Verificamos que se haya recibido un ID válido en la petición HTTP
    if (idAudicion != null && !idAudicion.isEmpty()) {
        // Parámetros de conexión locales para XAMPP
        String url = "jdbc:mysql://localhost:3306/stagelink?useSSL=false&serverTimezone=UTC";
        String usuarioDb = "root";
        String passwordDb = "";

        try {
            // Cargamos explícitamente el Driver JDBC de MySQL configurado en Maven
            Class.forName("com.mysql.cj.jdbc.Driver");
            
            // Establecemos la conexión con la base de datos 'stagelink'
            Connection conn = DriverManager.getConnection(url, usuarioDb, passwordDb);
            
            // Preparamos la sentencia SQL segura utilizando parámetros (?) para evitar inyecciones SQL
            String sql = "SELECT * FROM audicion WHERE id = ?";
            PreparedStatement stmt = conn.prepareStatement(sql);
            stmt.setString(1, idAudicion);
            
            // Ejecutamos la consulta y almacenamos el resultado
            ResultSet rs = stmt.executeQuery();

            // Si el registro existe en la base de datos, extraemos sus valores
            if (rs.next()) {
                tituloAudicion = rs.getString("titulo");
                descripcionAudicion = rs.getString("descripcion");
            }
            
            // Cerramos la conexión para liberar recursos del servidor Tomcat
            conn.close();
        } catch (Exception e) {
            // En caso de fallo técnico, mostramos un mensaje de error controlado en las variables
            tituloAudicion = "Error al cargar la audición";
            descripcionAudicion = "Detalle técnico del error: " + e.getMessage();
        }
    }
%>
<!doctype html>
<html lang="es">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<meta name="description"
	content="Consulta los detalles y roles de una convocatoria en StageLink Auditions.">
<title>Detalle de audición · StageLink</title>

<!-- Icono de la aplicación codificado en SVG -->
<link rel="icon" type="image/svg+xml"
	href="data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 64 64'%3E%3Crect width='64' height='64' rx='16' fill='%230a0a0a'/%3E%3Cpath d='M18 18h30v8H27v7h17v8H27v10h-9z' fill='white'/%3E%3C/svg%3E">

<!-- Hoja de estilos general de la interfaz (Corregido con ContextPath) -->
<link rel="stylesheet" href="${pageContext.request.contextPath}/css/styles.css">

<!-- Script local de la interfaz (Corregido con ContextPath) -->
<script src="${pageContext.request.contextPath}/javascript/app.js" defer></script>
</head>
<body data-page="audition">
	<!-- Enlace de accesibilidad para saltar directamente al contenido principal -->
	<a class="skip-link" href="#main-content">Saltar al contenido</a>

	<div class="app-frame">
		<!-- Barra lateral de navegación compartida -->
		<aside class="sidebar" id="sidebar"></aside>

		<div class="main-column">
			<!-- Barra superior de navegación -->
			<header class="topbar" id="topbar"></header>

			<!-- Contenido principal de la vista -->
			<main class="content" id="main-content">
				<div id="audition-detail">
					<!-- 
              Impresión dinámica de los datos obtenidos de MySQL 
              utilizando etiquetas de expresión de JSP (<%= %>)
            -->
					<h1><%= tituloAudicion.isEmpty() ? "Detalle de la Convocatoria" : tituloAudicion %></h1>
					<p><%= descripcionAudicion %></p>
				</div>
			</main>

			<!-- Barra de navegación inferior para dispositivos móviles -->
			<nav class="mobile-nav" id="mobile-nav"></nav>
		</div>
	</div>

	<!-- Diálogo flotante para enviar la postulación a la audición -->
	<dialog class="dialog" id="application-dialog"
		aria-labelledby="application-heading"> <!-- El formulario envía los datos mediante el método POST a un archivo JSP encargado de procesar la inserción -->
	<form id="application-form" action="procesarPostulacion.jsp"
		method="POST">
		<header class="dialog-header">
			<div>
				<h2 id="application-heading">Enviar postulación</h2>
				<p id="application-title"></p>
			</div>
			<button class="dialog-close" type="button" data-close-dialog
				aria-label="Cerrar">
				<svg class="icon-inline" viewBox="0 0 24 24" fill="none"
					stroke="currentColor" stroke-width="1.8" aria-hidden="true">
            <path d="m6 6 12 12M18 6 6 18"></path>
          </svg>
			</button>
		</header>

		<div class="dialog-body">
			<!-- Contenedor para mensajes de estado o elegibilidad -->
			<div class="auth-message" id="eligibility-message" role="status"
				aria-live="polite" hidden></div>

			<fieldset class="fieldset">
				<legend>Materiales del portafolio</legend>
				<p class="form-note">Elige qué elementos deseas compartir con la
					productora.</p>
				<div class="check-grid" id="application-materials"
					style="margin-top: 12px"></div>
			</fieldset>

			<label class="field" style="margin-top: 18px"> <span
				class="field-label">Nota para la productora (opcional)</span> <textarea
					class="textarea" name="note"
					placeholder="Disponibilidad, enlaces o información relevante"></textarea>
			</label>
		</div>

		<footer class="dialog-actions">
			<button class="button secondary" type="button" data-close-dialog>Cancelar</button>
			<button class="button" type="submit">Confirmar y enviar</button>
		</footer>
	</form>
	</dialog>
</body>
</html>
