<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.sql.*"%>
<%
    // =========================================================================
    // LÓGICA DE SERVIDOR (JAVA / JDBC) - FEED DE AUDICIONES Y FILTROS
    // =========================================================================
    String queryParam = request.getParameter("query");
    String typeParam = request.getParameter("type");
    String compParam = request.getParameter("compensation");
    
    String url = "jdbc:mysql://localhost:3306/stagelink?useSSL=false&serverTimezone=UTC";
    String usuarioDb = "root";
    String passwordDb = "";

    StringBuilder sqlBuilder = new StringBuilder("SELECT * FROM audicion WHERE 1=1");
    
    if (queryParam != null && !queryParam.trim().isEmpty()) {
        sqlBuilder.append(" AND (titulo LIKE ? OR descripcion LIKE ?)");
    }
    if (typeParam != null && !typeParam.trim().isEmpty()) {
        sqlBuilder.append(" AND tipo = ?");
    }
    if (compParam != null && !compParam.trim().isEmpty()) {
        sqlBuilder.append(" AND tipo_compensacion = ?");
    }
    sqlBuilder.append(" ORDER BY id DESC");
%>
<!doctype html>
<html lang="es">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<meta name="description"
	content="Explora convocatorias teatrales activas en StageLink Auditions.">
<title>Audiciones · StageLink</title>

<!-- Icono vectorial SVG de la plataforma -->
<link rel="icon" type="image/svg+xml"
	href="data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 64 64'%3E%3Crect width='64' height='64' rx='16' fill='%230a0a0a'/%3E%3Cpath d='M18 18h30v8H27v7h17v8H27v10h-9z' fill='white'/%3E%3C/svg%3E">

<!-- Hojas de estilo y scripts corregidos con ContextPath -->
<link rel="stylesheet" href="${pageContext.request.contextPath}/css/styles.css">
<script src="${pageContext.request.contextPath}/javascript/app.js" defer></script>
</head>
<body data-page="feed">
	<a class="skip-link" href="#main-content">Saltar al contenido</a>

	<div class="app-frame">
		<aside class="sidebar" id="sidebar"></aside>

		<div class="main-column">
			<header class="topbar" id="topbar"></header>

			<main class="content" id="main-content">
				<div class="page-heading">
					<div>
						<h1>Audiciones abiertas</h1>
						<p>Encuentra oportunidades por disciplina, ubicación y tipo de compensación.</p>
					</div>
					<div class="heading-actions">
						<a class="button secondary" id="feed-primary-action"
							href="${pageContext.request.contextPath}/create-audition.jsp">Publicar convocatoria</a>
					</div>
				</div>

				<form class="filters" id="filter-form" role="search"
					action="feed.jsp" method="GET">
					<label class="search-field"> <span class="sr-only">Buscar
							por obra, compañía, rol o ubicación</span> <svg viewBox="0 0 24 24"
							fill="none" stroke="currentColor" stroke-width="1.8"
							aria-hidden="true">
              <circle cx="11" cy="11" r="7"></circle>
              <path d="m20 20-4-4"></path>
            </svg> <input class="input" type="search" name="query"
						placeholder="Obra, compañía, rol…" autocomplete="off"
						value="<%= (queryParam != null) ? queryParam : "" %>">
					</label> <label class="field"> <span class="sr-only">Tipo de
							proyecto</span> <select class="select" name="type"
						onchange="this.form.submit()">
							<option value="">Todo tipo</option>
							<option value="Teatro"
								<%= "Teatro".equals(typeParam) ? "selected" : "" %>>Teatro</option>
							<option value="Musical"
								<%= "Musical".equals(typeParam) ? "selected" : "" %>>Musical</option>
							<option value="Cortometraje"
								<%= "Cortometraje".equals(typeParam) ? "selected" : "" %>>Cortometraje</option>
					</select>
					</label> <label class="field"> <span class="sr-only">Tipo de
							compensación</span> <select class="select" name="compensation"
						onchange="this.form.submit()">
							<option value="">Toda compensación</option>
							<option value="paid"
								<%= "paid".equals(compParam) ? "selected" : "" %>>Remunerado</option>
							<option value="ad-honorem"
								<%= "ad-honorem".equals(compParam) ? "selected" : "" %>>Ad
								honorem</option>
							<option value="experience"
								<%= "experience".equals(compParam) ? "selected" : "" %>>Intercambio</option>
					</select>
					</label> <label class="field"> <span class="sr-only">Tipo de
							rol</span> <select class="select" name="role">
							<option value="">Todo rol</option>
							<option>Principal</option>
							<option>Reparto</option>
							<option>Ensamble</option>
					</select>
					</label> <label class="field"> <span class="sr-only">Ubicación</span>
						<select class="select" name="location">
							<option value="">Toda ubicación</option>
					</select>
					</label> <label class="field"> <span class="sr-only">Tamaño
							de la compañía</span> <select class="select" name="companySize">
							<option value="">Toda compañía</option>
							<option>Independiente</option>
							<option>Pequeña</option>
							<option>Mediana</option>
							<option>Grande</option>
					</select>
					</label> <label class="filter-toggle"> <input type="checkbox"
						name="saved"> Solo guardadas
					</label>
					<button type="submit" class="button ghost small">Buscar</button>
				</form>

				<div class="page-heading" style="margin-bottom: 12px">
					<p class="results-meta" id="results-count" aria-live="polite">Resultados
						en vivo desde MySQL</p>
					<a class="button ghost small" id="clear-filters" href="feed.jsp">Limpiar
						filtros</a>
				</div>

				<section class="audition-grid" id="audition-results"
					aria-label="Resultados de audiciones">
					<%
            int cantidadResultados = 0;
            try {
                Class.forName("com.mysql.cj.jdbc.Driver");
                Connection conn = DriverManager.getConnection(url, usuarioDb, passwordDb);
                
                PreparedStatement stmt = conn.prepareStatement(sqlBuilder.toString());
                
                int paramIndex = 1;
                if (queryParam != null && !queryParam.trim().isEmpty()) {
                    String pattern = "%" + queryParam.trim() + "%";
                    stmt.setString(paramIndex++, pattern);
                    stmt.setString(paramIndex++, pattern);
                }
                if (typeParam != null && !typeParam.trim().isEmpty()) {
                    stmt.setString(paramIndex++, typeParam);
                }
                if (compParam != null && !compParam.trim().isEmpty()) {
                    stmt.setString(paramIndex++, compParam);
                }

                ResultSet rs = stmt.executeQuery();

                while (rs.next()) {
                    cantidadResultados++;
                    int id = rs.getInt("id");
                    String titulo = rs.getString("titulo");
                    String tipo = rs.getString("tipo");
                    String descripcion = rs.getString("descripcion");
                    String lugar = rs.getString("lugar");
          %>
					<article class="card audition-card"
						style="padding: 20px; margin-bottom: 16px;">
						<header style="margin-bottom: 10px;">
							<span class="badge"
								style="background: #e0e0e0; padding: 4px 8px; border-radius: 4px; font-size: 0.8rem;"><%= tipo %></span>
							<h2 style="margin-top: 8px;">
								<a href="${pageContext.request.contextPath}/audition.jsp?id=<%= id %>"
									style="text-decoration: none; color: inherit;"><%= titulo %></a>
							</h2>
						</header>
						<p style="color: #666; font-size: 0.95rem;"><%= descripcion %></p>
						<footer
							style="margin-top: 15px; display: flex; justify-content: space-between; align-items: center;">
							<small>📍 <%= lugar %></small> <a
								href="${pageContext.request.contextPath}/audition.jsp?id=<%= id %>" class="button secondary small">Ver
								detalles</a>
						</footer>
					</article>
					<%
                }
                
                if (cantidadResultados == 0) {
          %>
					<div class="empty-state" style="padding: 40px; text-align: center;">
						<p>No se encontraron convocatorias que coincidan con los filtros seleccionados.</p>
					</div>
					<%
                }

                rs.close();
                stmt.close();
                conn.close();
            } catch (Exception e) {
          %>
					<div class="auth-message" data-type="error">
						Error al cargar las convocatorias:
						<%= e.getMessage() %>
					</div>
					<%
            }
          %>
				</section>
			</main>

			<nav class="mobile-nav" id="mobile-nav"></nav>
		</div>
	</div>
</body>
</html>