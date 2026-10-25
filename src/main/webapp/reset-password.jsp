<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.sql.*"%>
<%
    // =========================================================================
    // LÓGICA DE SERVIDOR (JAVA / JDBC) - RESTABLECER CONTRASEÑA
    // Procesamos la solicitud POST cuando el usuario ingresa y confirma 
    // su nueva contraseña.
    // =========================================================================
    String mensajeFeedback = "";
    String tipoMensaje = ""; // "success" o "error"

    // Parámetros de conexión local a la base de datos 'stagelink' en XAMPP
    String url = "jdbc:mysql://localhost:3306/stagelink?useSSL=false&serverTimezone=UTC";
    String usuarioDb = "root";
    String passwordDb = "";

    if ("POST".equalsIgnoreCase(request.getMethod())) {
        String password = request.getParameter("password");
        String passwordConfirm = request.getParameter("passwordConfirm");
        // Nota: Puedes capturar el correo o token si viene oculto o por parámetro URL
        String correo = request.getParameter("email"); 

        // Verificamos que ambas contraseñas coincidan
        if (password == null || !password.equals(passwordConfirm)) {
            mensajeFeedback = "Las contraseñas no coinciden. Por favor, revísalas.";
            tipoMensaje = "error";
        } else {
            try {
                // Cargamos el Driver JDBC de MySQL configurado en Maven
                Class.forName("com.mysql.cj.jdbc.Driver");
                Connection conn = DriverManager.getConnection(url, usuarioDb, passwordDb);

                // Sentencia SQL para actualizar la contraseña del usuario en MySQL
                String sql = "UPDATE usuario SET hash_contrasena = ? WHERE correo = ?";
                PreparedStatement stmt = conn.prepareStatement(sql);
                stmt.setString(1, password); // Idealmente con hash en producción
                stmt.setString(2, correo != null ? correo : ""); // Identificador del usuario

                int filasAfectadas = stmt.executeUpdate();
                
                if (filasAfectadas > 0) {
                    mensajeFeedback = "Contraseña actualizada con éxito. Ya puedes iniciar sesión.";
                    tipoMensaje = "success";
                } else {
                    mensajeFeedback = "No se pudo actualizar la contraseña. El usuario no fue encontrado.";
                    tipoMensaje = "error";
                }

                stmt.close();
                conn.close();
            } catch (Exception e) {
                mensajeFeedback = "Error en el servidor al actualizar la contraseña: " + e.getMessage();
                tipoMensaje = "error";
            }
        }
    }
%>
<!doctype html>
<html lang="es">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<meta name="description"
	content="Crea una contraseña nueva para StageLink Auditions.">
<title>Nueva contraseña · StageLink Auditions</title>

<!-- Icono vectorial SVG de la plataforma -->
<link rel="icon" type="image/svg+xml"
	href="data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 64 64'%3E%3Crect width='64' height='64' rx='16' fill='%230a0a0a'/%3E%3Cpath d='M18 18h30v8H27v7h17v8H27v10h-9z' fill='white'/%3E%3C/svg%3E">

<!-- Hoja de estilos principal (ajustada con ruta relativa '../css/styles.css') -->
<link rel="stylesheet" href="../css/styles.css">

<!-- Script local de autenticación y validaciones visuales -->
<script src="../javascript/auth.js" defer></script>
</head>
<body data-auth-page="reset">
	<main class="welcome-page">
		<div class="welcome-shell">

			<!-- Sección izquierda: Identidad de marca y mensajes informativos -->
			<section class="welcome-copy">
				<a class="brand" href="index.jsp" aria-label="StageLink Auditions">
					<span class="brand-mark">SL</span> <span>StageLink<small>Auditions</small></span>
				</a>
				<h1>
					Nueva.<br>
					<span>Contraseña.</span>
				</h1>
				<p>Protege tu cuenta con una contraseña que no utilices en otros
					servicios.</p>
			</section>

			<!-- Sección derecha: Panel de restablecimiento de credenciales -->
			<section class="role-entry">

				<!-- Contenedor dinámico de mensajes si Java procesó un error o éxito -->
				<div class="auth-message" id="auth-message" role="status"
					aria-live="polite" <% if(mensajeFeedback.isEmpty()) { %> hidden
					<% } %> data-type="<%= tipoMensaje %>">
					<%= mensajeFeedback %>
				</div>

				<!-- Formulario que envía los datos mediante POST a este mismo archivo JSP -->
				<form class="auth-panel" id="reset-password-form"
					action="reset-password.jsp" method="POST">
					<h2>Crear contraseña nueva</h2>
					<p>El enlace recibido por correo autoriza este cambio.</p>

					<!-- Campo oculto opcional para recibir el correo o token de recuperación -->
					<input type="hidden" name="email"
						value="<%= request.getParameter("email") != null ? request.getParameter("email") : "" %>">

					<div class="auth-fields">
						<label class="field"> <span class="field-label">Nueva
								contraseña</span> <input class="input" type="password" name="password"
							required minlength="8" autocomplete="new-password">
						</label> <label class="field"> <span class="field-label">Confirmar
								contraseña</span> <input class="input" type="password"
							name="passwordConfirm" required minlength="8"
							autocomplete="new-password">
						</label>
					</div>
					<button class="button" type="submit">Guardar contraseña</button>
				</form>

				<!-- Indicador de estado de conexión local -->
				<p class="demo-note" id="connection-note">Conexión activa con
					base de datos MySQL local.</p>
			</section>
		</div>
	</main>
</body>
</html>
