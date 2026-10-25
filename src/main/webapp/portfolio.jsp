<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<<%@ page import="java.sql.*" %>
	<%
    // =========================================================================
    // LÓGICA DE SERVIDOR (JAVA / JDBC) - PORTAFOLIO ARTÍSTICO
    // Procesamos la subida/inserción de nuevos elementos al portafolio o 
    // consultamos los materiales ya registrados en la base de datos MySQL.
    // =========================================================================
    String mensajeFeedback = "";
    String tipoMensaje = ""; // "success" o "error"

    // Parámetros de conexión local a la base de datos 'stagelink' en XAMPP
    String url = "jdbc:mysql://localhost:3306/stagelink?useSSL=false&serverTimezone=UTC";
    String usuarioDb = "root";
    String passwordDb = "";

    // Si el usuario envía un nuevo material mediante POST
    if ("POST".equalsIgnoreCase(request.getMethod())) {
        String tipoMaterial = request.getParameter("type");
        String nombreVisible = request.getParameter("name");
        String etiquetas = request.getParameter("tags");
        String enlaceExterno = request.getParameter("externalUrl");

        try {
            // Cargamos el Driver JDBC configurado en Maven
            Class.forName("com.mysql.cj.jdbc.Driver");
            Connection conn = DriverManager.getConnection(url, usuarioDb, passwordDb);

            // Sentencia SQL para registrar el material en la tabla del portafolio
            String sql = "INSERT INTO portafolio (tipo_material, nombre, etiquetas, enlace_externo) VALUES (?, ?, ?, ?)";
            PreparedStatement stmt = conn.prepareStatement(sql);
            stmt.setString(1, tipoMaterial);
            stmt.setString(2, nombreVisible);
            stmt.setString(3, etiquetas);
            stmt.setString(4, enlaceExterno);
            
            stmt.executeUpdate();
            stmt.close();
            conn.close();

            mensajeFeedback = "Material guardado correctamente en tu portafolio.";
            tipoMensaje = "success";
        } catch (Exception e) {
            mensajeFeedback = "Error al guardar el material: " + e.getMessage();
            tipoMensaje = "error";
        }
    }
%><!doctype html>
<html lang="es">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <meta name="description" content="Organiza fotos, videos y documentos de tu portafolio artístico en StageLink.">
  <title>Portafolio · StageLink</title>
  
  <!-- Icono vectorial SVG de la plataforma -->
  <link rel="icon" type="image/svg+xml" href="data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 64 64'%3E%3Crect width='64' height='64' rx='16' fill='%230a0a0a'/%3E%3Cpath d='M18 18h30v8H27v7h17v8H27v10h-9z' fill='white'/%3E%3C/svg%3E">
  
  <!-- Hoja de estilos principal (ajustada con la ruta relativa '../css/styles.css') -->
  <link rel="stylesheet" href="../css/styles.css">
  
  <!-- Script local de interfaz para la gestión visual de la carga de archivos -->
  <script src="../javascript/app.js" defer></script>
</head>
<body data-page="portfolio">
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
            <h1>Mi portafolio</h1>
            <p>Reúne tus materiales una sola vez y elígelos al postularte.</p>
          </div>
          <p class="results-meta" id="material-count">Sincronizado con base de datos local</p>
        </div>

        <!-- Mensaje de feedback si se guardó un archivo con éxito o ocurrió un error -->
        <% if (!mensajeFeedback.isEmpty()) { %>
          <div class="auth-message" data-type="<%= tipoMensaje %>" style="margin-bottom: 20px;">
            <%= mensajeFeedback %>
          </div>
        <% } %>

        <div class="portfolio-layout">
          <!-- 
            PANEL IZQUIERDO: FORMULARIO PARA AGREGAR NUEVO MATERIAL 
            El formulario apunta a este mismo archivo por POST
          -->
          <section class="card panel upload-card" aria-labelledby="upload-title">
            <h2 class="section-title" id="upload-title">Agregar material</h2>
            
            <form id="upload-form" action="portfolio.jsp" method="POST">
              <input class="file-input" type="file" id="material-file" accept="image/*,video/*,.pdf,.doc,.docx,audio/*">
              
              <div class="drop-zone" id="drop-zone" role="button" tabindex="0" aria-controls="material-file">
                <div>
                  <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" aria-hidden="true">
                    <path d="M12 16V4M7 9l5-5 5 5"></path>
                    <path d="M5 15v5h14v-5"></path>
                  </svg>
                  <strong>Arrastra un archivo aquí</strong>
                  <span>o presiona para buscarlo en tu dispositivo</span>
                </div>
              </div>
              
              <p class="selected-file" id="selected-file" hidden></p>
              
              <div class="form-grid" style="margin-top:16px">
                <label class="field">
                  <span class="field-label">Tipo de material</span>
                  <select class="select" name="type">
                    <option value="image">Foto / headshot</option>
                    <option value="video">Video / reel</option>
                    <option value="document">Documento / audio</option>
                  </select>
                </label>
                
                <label class="field">
                  <span class="field-label">Nombre visible</span>
                  <input class="input" name="name" required placeholder="Ej. Monólogo dramático">
                </label>
                
                <label class="field span-2">
                  <span class="field-label">Etiquetas</span>
                  <input class="input" name="tags" placeholder="Drama, canto, headshot">
                  <span class="field-hint">Sepáralas con comas.</span>
                </label>
                
                <label class="field span-2">
                  <span class="field-label">O usar un enlace externo</span>
                  <input class="input" type="url" name="externalUrl" placeholder="https://youtube.com/…">
                  <span class="field-hint">Útil para YouTube, Vimeo o un archivo ya publicado. Puedes usar archivo o enlace.</span>
                </label>
              </div>
              
              <div class="progress-shell" id="upload-progress" hidden aria-label="Progreso de carga">
                <div class="progress-bar" id="upload-progress-bar"></div>
              </div>
              
              <button class="button" type="submit" style="width:100%;margin-top:16px">Guardar material</button>
              <p class="form-note" style="margin-top:10px">Con una cuenta conectada, los archivos quedan disponibles para las postulaciones que tú elijas.</p>
            </form>
          </section>

          <!-- 
            PANEL DERECHO: LISTADO DE MATERIALES ORGANIZADOS (CONSULTA DESDE MYSQL)
          -->
          <section aria-labelledby="materials-title">
            <h2 class="section-title" id="materials-title">Material organizado</h2>
            
            <div class="material-grid" id="material-grid">
              <%
                try {
                    Class.forName("com.mysql.cj.jdbc.Driver");
                    Connection conn = DriverManager.getConnection(url, usuarioDb, passwordDb);
                    
                    // Consultamos los elementos del portafolio ordenados del más reciente al más antiguo
                    String sql = "SELECT * FROM portafolio ORDER BY id DESC";
                    PreparedStatement stmt = conn.prepareStatement(sql);
                    ResultSet rs = stmt.executeQuery();

                    boolean hayMateriales = false;

                    while (rs.next()) {
                        hayMateriales = true;
                        String nombre = rs.getString("nombre");
                        String tipo = rs.getString("tipo_material");
                        String etiquetas = rs.getString("etiquetas");
                        String enlace = rs.getString("enlace_externo");
              %>
                        <!-- Tarjeta individual generada dinámicamente por Java con JDBC -->
                        <div class="card material-item" style="padding: 16px; margin-bottom: 12px;">
                          <span class="badge" style="background: #e0e0e0; padding: 2px 6px; border-radius: 4px; font-size: 0.75rem;"><%= tipo %></span>
                          <h3 style="margin-top: 8px; font-size: 1.1rem;"><%= nombre %></h3>
                          <% if (etiquetas != null && !etiquetas.isEmpty()) { %>
                            <p style="color: #666; font-size: 0.85rem; margin-top: 4px;">🏷️ <%= etiquetas %></p>
                          <% } %>
                          <% if (enlace != null && !enlace.isEmpty()) { %>
                            <a href="<%= enlace %>" target="_blank" style="font-size: 0.85rem; display: inline-block; margin-top: 8px;">🔗 Ver enlace externo</a>
                          <% } %>
                        </div>
              <%
                    }

                    if (!hayMateriales) {
              %>
                        <div class="empty-state" style="padding: 30px; text-align: center; grid-column: span 2;">
                          <p>Aún no has agregado materiales a tu portafolio.</p>
                        </div>
              <%
                    }

                    rs.close();
                    stmt.close();
                    conn.close();
                } catch (Exception e) {
              %>
                    <div class="auth-message" data-type="error" style="grid-column: span 2;">
                      No se pudieron cargar los materiales del portafolio desde MySQL.
                    </div>
              <%
                }
              %>
            </div>
          </section>
        </div>
      </main>
      
      <!-- Barra de navegación inferior móvil -->
      <nav class="mobile-nav" id="mobile-nav"></nav>
    </div>
  </div>
</body>
</html>