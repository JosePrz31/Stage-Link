<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.sql.*"%>
<%
    // =========================================================================
    // LÓGICA DE SERVIDOR (JAVA / JDBC)
    // Procesamos las peticiones POST cuando el usuario envía un formulario
    // =========================================================================
    String mensajeFeedback = "";
    String tipoMensaje = ""; // "success" o "error"

    if ("POST".equalsIgnoreCase(request.getMethod())) {
        // Identificamos qué formulario se envió revisando los parámetros recibidos
        String accion = request.getParameter("accion"); // Puede ser "login" o "register"

        // Datos de conexión local a la base de datos 'stagelink' en XAMPP
        String url = "jdbc:mysql://localhost:3306/stagelink?useSSL=false&serverTimezone=UTC";
        String usuarioDb = "root";
        String passwordDb = "";

        try {
            // Cargamos el driver JDBC de MySQL configurado en Maven
            Class.forName("com.mysql.cj.jdbc.Driver");
            Connection conn = DriverManager.getConnection(url, usuarioDb, passwordDb);

            if ("login".equals(accion)) {
                // -------------------------------------------------------------
                // PROCESO DE INICIO DE SESIÓN
                // -------------------------------------------------------------
                String email = request.getParameter("email");
                String password = request.getParameter("password");

                String sql = "SELECT * FROM usuario WHERE correo = ? AND hash_contrasena = ?";
                PreparedStatement stmt = conn.prepareStatement(sql);
                stmt.setString(1, email);
                stmt.setString(2, password);
                ResultSet rs = stmt.executeQuery();

                if (rs.next()) {
                    // Si las credenciales son correctas, redirigimos al feed principal
                    response.sendRedirect("feed.jsp");
                    return;
                } else {
                    mensajeFeedback = "El correo o la contraseña no son correctos.";
                    tipoMensaje = "error";
                }
                stmt.close();

            } else if ("register".equals(accion)) {
                // -------------------------------------------------------------
                // PROCESO DE CREACIÓN DE CUENTA (REGISTRO)
                // -------------------------------------------------------------
                String displayName = request.getParameter("displayName");
                String role = request.getParameter("role");
                String email = request.getParameter("email");
                String password = request.getParameter("password");
                String passwordConfirm = request.getParameter("passwordConfirm");

                // Verificamos que las contraseñas coincidan
                if (!password.equals(passwordConfirm)) {
                    mensajeFeedback = "Las contraseñas no coinciden.";
                    tipoMensaje = "error";
                } else {
                    // Insertamos el nuevo usuario en la base de datos local
                    String sql = "INSERT INTO usuario (nombre, rol, correo, hash_contrasena) VALUES (?, ?, ?, ?)";
                    PreparedStatement stmt = conn.prepareStatement(sql);
                    stmt.setString(1, displayName);
                    stmt.setString(2, role);
                    stmt.setString(3, email);
                    stmt.setString(4, password); // Nota: idealmente va con hash, pero usamos el campo directo por ahora
                    stmt.executeUpdate();

                    mensajeFeedback = "Cuenta creada con éxito. Ya puedes iniciar sesión.";
                    tipoMensaje = "success";
                    stmt.close();
                }
            }

            conn.close();
        } catch (Exception e) {
            mensajeFeedback = "Error en el servidor: " + e.getMessage();
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
	content="Crea una cuenta o inicia sesión en StageLink Auditions.">
<title>Acceso · StageLink Auditions</title>

<!-- Icono de la aplicación en formato SVG -->
<link rel="icon" type="image/svg+xml"
	href="data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 64 64'%3E%3Crect width='64' height='64' rx='16' fill='%230a0a0a'/%3E%3Cpath d='M18 18h30v8H27v7h17v8H27v10h-9z' fill='white'/%3E%3C/svg%3E">

<!-- Hojas de estilos generales (ajustamos la ruta relativa '../css/styles.css') -->
<link rel="stylesheet" href="../css/styles.css">

<!-- Ya no usamos Supabase ni backend.js en la nube; solo tu JS local de interfaz si se requiere -->
<script src="../javascript/auth.js" defer></script>
</head>
<body data-auth-page="access">
	<main class="welcome-page">
		<div class="welcome-shell">

			<!-- Sección izquierda: Identidad de marca y mensajes de bienvenida -->
			<section class="welcome-copy" aria-labelledby="access-copy-title">
				<a class="brand" href="index.jsp" aria-label="StageLink Auditions">
					<span class="brand-mark">SL</span> <span>StageLink<small>Auditions</small></span>
				</a>
				<h1 id="access-copy-title">
					Entra.<br>
					<span>Conecta.</span>
				</h1>
				<p>Tu perfil, convocatorias y postulaciones disponibles desde
					cualquier dispositivo.</p>
			</section>

			<!-- Sección derecha: Paneles de autenticación (Login, Registro y Recuperación) -->
			<section class="role-entry" aria-labelledby="auth-title">

				<!-- Pestañas de navegación visual gestionadas por JavaScript -->
				<div class="auth-tabs" role="tablist"
					aria-label="Acceso a StageLink">
					<button class="auth-tab" id="login-tab" type="button" role="tab"
						data-auth-mode="login" aria-controls="login-panel">Iniciar
						sesión</button>
					<button class="auth-tab" id="register-tab" type="button" role="tab"
						data-auth-mode="register" aria-controls="register-panel">Crear
						cuenta</button>
				</div>

				<!-- 
          Contenedor dinámico de mensajes. 
          Si Java procesó un error o éxito, se muestra aquí automáticamente.
        -->
				<div class="auth-message" id="auth-message" role="status"
					aria-live="polite" <% if(mensajeFeedback.isEmpty()) { %> hidden
					<% } %> data-type="<%= tipoMensaje %>">
					<%= mensajeFeedback %>
				</div>

				<!-- 1. FORMULARIO DE INICIO DE SESIÓN -->
				<form class="auth-panel" id="login-panel" role="tabpanel"
					aria-labelledby="login-tab" action="auth.jsp" method="POST">
					<!-- Campo oculto para indicar al servidor que esta petición es un login -->
					<input type="hidden" name="accion" value="login">

					<h2 id="auth-title">Bienvenido de vuelta</h2>
					<p>Accede con el correo de tu cuenta.</p>
					<div class="auth-fields">
						<label class="field"><span class="field-label">Correo
								electrónico</span><input class="input" type="email" name="email"
							required autocomplete="email"></label> <label class="field"><span
							class="field-label">Contraseña</span><input class="input"
							type="password" name="password" required minlength="8"
							autocomplete="current-password"></label>
					</div>
					<button class="button" type="submit">Iniciar sesión</button>
					<button class="text-button" id="forgot-password" type="button">Olvidé
						mi contraseña</button>
				</form>

				<!-- 2. FORMULARIO DE CREACIÓN DE CUENTA (REGISTRO) -->
				<form class="auth-panel" id="register-panel" role="tabpanel"
					aria-labelledby="register-tab" action="auth.jsp" method="POST"
					hidden>
					<!-- Campo oculto para indicar al servidor que esta petición es un registro -->
					<input type="hidden" name="accion" value="register">

					<h2>Crear una cuenta</h2>
					<p>Elige el tipo de cuenta que utilizarás. No podrá cambiarse
						desde el perfil.</p>
					<div class="auth-fields">
						<label class="field"><span class="field-label">Nombre
								visible</span><input class="input" name="displayName" required
							autocomplete="name" maxlength="80"></label> <label class="field"><span
							class="field-label">Tipo de cuenta</span><select class="select"
							name="role" required><option value="actor">Artista</option>
								<option value="producer">Productora o compañía</option></select></label> <label
							class="field"><span class="field-label">Correo
								electrónico</span><input class="input" type="email" name="email"
							required autocomplete="email"></label> <label class="field"><span
							class="field-label">Contraseña</span><input class="input"
							type="password" name="password" required minlength="8"
							autocomplete="new-password"><span class="field-hint">Mínimo
								8 caracteres.</span></label> <label class="field"><span
							class="field-label">Confirmar contraseña</span><input
							class="input" type="password" name="passwordConfirm" required
							minlength="8" autocomplete="new-password"></label>
					</div>
					<button class="button" type="submit">Crear cuenta</button>
				</form>

				<!-- 3. FORMULARIO DE RECUPERACIÓN DE CONTRASEÑA -->
				<form class="auth-panel" id="recovery-panel"
					aria-labelledby="recovery-title" hidden>
					<h2 id="recovery-title">Recuperar contraseña</h2>
					<p>Te enviaremos un enlace seguro para crear una nueva.</p>
					<div class="auth-fields">
						<label class="field"><span class="field-label">Correo
								electrónico</span><input class="input" type="email" name="email"
							required autocomplete="email"></label>
					</div>
					<button class="button" type="submit">Enviar enlace</button>
					<button class="text-button" data-back-login type="button">Volver
						a iniciar sesión</button>
				</form>

				<!-- Nota informativa fija en la parte inferior -->
				<p class="demo-note" id="connection-note">Conexión activa con
					base de datos MySQL local.</p>
			</section>
		</div>
	</main>
</body>
</html>
