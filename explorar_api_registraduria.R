# Script para Explorar la API de la Registraduría
# Este script te ayuda a entender cómo funciona la API y obtener los datos reales

library(httr)
library(jsonlite)
library(rvest)

BASE_URL <- "https://divulgacione14bucaramanga.registraduria.gov.co"

# ===============================================
# FUNCIÓN 1: Explorar llamadas GraphQL
# ===============================================

#' Interceptar y analizar llamadas GraphQL de la página
explorar_graphql <- function() {
  cat("\n=== EXPLORADOR DE GRAPHQL ===\n\n")

  graphql_url <- paste0(BASE_URL, "/graphql")

  # Consultas comunes para probar
  consultas <- list(
    zonas = '{ zonas(departamento: "27", municipio: "001") { codigo nombre } }',
    puestos = '{ puestos(departamento: "27", municipio: "001", zona: "001") { codigo nombre } }',
    mesas = '{ mesas(departamento: "27", municipio: "001") { numero zona puesto urlPdf } }'
  )

  for (nombre in names(consultas)) {
    cat("Probando consulta:", nombre, "\n")

    response <- tryCatch({
      POST(
        graphql_url,
        body = list(query = consultas[[nombre]]),
        encode = "json",
        add_headers(
          `Content-Type` = "application/json",
          `Referer` = paste0(BASE_URL, "/departamento/27")
        )
      )
    }, error = function(e) NULL)

    if (!is.null(response) && status_code(response) == 200) {
      cat("✓ Éxito!\n")
      resultado <- content(response, "parsed")
      print(str(resultado))
    } else {
      cat("✗ Falló\n")
    }
    cat("\n")
  }
}

# ===============================================
# FUNCIÓN 2: Obtener configuración de la página
# ===============================================

#' Extraer configuración y datos del JavaScript de la página
obtener_config_pagina <- function() {
  cat("\n=== EXTRAYENDO CONFIGURACIÓN ===\n\n")

  url <- paste0(BASE_URL, "/departamento/27")
  response <- GET(url)

  if (status_code(response) != 200) {
    cat("✗ No se pudo acceder a la página\n")
    return(NULL)
  }

  contenido <- content(response, "text", encoding = "UTF-8")
  pagina <- read_html(contenido)

  # Buscar scripts con configuración
  scripts <- html_nodes(pagina, "script")

  for (i in seq_along(scripts)) {
    script_text <- html_text(scripts[[i]])

    # Buscar patrones comunes de configuración
    if (grepl("config|ZONAS|MESAS|API", script_text, ignore.case = TRUE)) {
      cat("Script", i, "contiene configuración relevante:\n")
      cat(substr(script_text, 1, 500), "...\n\n")
    }
  }

  # Buscar elementos de datos
  cat("\n=== ELEMENTOS SELECT (Zonas/Puestos) ===\n")
  selects <- html_nodes(pagina, "select")

  for (select in selects) {
    id <- html_attr(select, "id")
    name <- html_attr(select, "name")

    if (!is.na(id) || !is.na(name)) {
      cat("\nSelect encontrado:", id, "/", name, "\n")
      opciones <- html_nodes(select, "option")
      cat("Opciones:", length(opciones), "\n")

      if (length(opciones) > 0 && length(opciones) < 50) {
        for (opt in opciones) {
          valor <- html_attr(opt, "value")
          texto <- html_text(opt)
          if (!is.na(valor) && valor != "") {
            cat("  -", valor, ":", texto, "\n")
          }
        }
      }
    }
  }

  return(invisible(contenido))
}

# ===============================================
# FUNCIÓN 3: Simular selección de zona/puesto
# ===============================================

#' Simular la selección de una zona y puesto para obtener las mesas
obtener_mesas <- function(zona = "001", puesto = "01") {
  cat("\n=== OBTENIENDO MESAS ===\n")
  cat("Zona:", zona, "| Puesto:", puesto, "\n\n")

  # Probar diferentes endpoints posibles
  endpoints <- c(
    sprintf("/api/mesas?zona=%s&puesto=%s", zona, puesto),
    sprintf("/api/departamento/27/municipio/001/zona/%s/puesto/%s/mesas", zona, puesto),
    sprintf("/temis/mesas?zona=%s&puesto=%s", zona, puesto)
  )

  for (endpoint in endpoints) {
    url <- paste0(BASE_URL, endpoint)
    cat("Probando:", endpoint, "... ")

    response <- tryCatch({
      GET(url, add_headers(Referer = paste0(BASE_URL, "/departamento/27")))
    }, error = function(e) NULL)

    if (!is.null(response) && status_code(response) == 200) {
      cat("✓\n")
      datos <- content(response, "parsed")
      print(str(datos))
      return(datos)
    } else {
      cat("✗\n")
    }
  }

  cat("\nℹ No se encontró endpoint de API. Puede que use JavaScript para cargar los datos.\n")
  return(NULL)
}

# ===============================================
# FUNCIÓN 4: Obtener todas las zonas disponibles
# ===============================================

#' Obtener lista de zonas desde la página
obtener_zonas <- function() {
  cat("\n=== OBTENIENDO ZONAS ===\n\n")

  url <- paste0(BASE_URL, "/departamento/27")
  response <- GET(url)

  if (status_code(response) != 200) {
    cat("✗ Error al cargar la página\n")
    return(NULL)
  }

  pagina <- read_html(content(response, "text", encoding = "UTF-8"))

  # Buscar el select de zonas
  zona_select <- html_node(pagina, "#zona, [name='zona'], select.zona")

  if (!is.null(zona_select)) {
    opciones <- html_nodes(zona_select, "option")
    zonas <- data.frame(
      codigo = html_attr(opciones, "value"),
      nombre = html_text(opciones),
      stringsAsFactors = FALSE
    )

    zonas <- zonas[!is.na(zonas$codigo) & zonas$codigo != "", ]

    cat("✓ Zonas encontradas:", nrow(zonas), "\n")
    print(zonas)
    return(zonas)
  }

  cat("ℹ No se encontró select de zonas en HTML\n")
  return(NULL)
}

# ===============================================
# FUNCIÓN 5: Analizar un PDF de ejemplo
# ===============================================

#' Analizar la estructura de una URL de PDF conocida
analizar_url_pdf <- function(url_ejemplo = NULL) {
  cat("\n=== ANALIZADOR DE URL PDF ===\n\n")

  if (is.null(url_ejemplo)) {
    url_ejemplo <- "https://divulgacione14bucaramanga.registraduria.gov.co/assets/temis/pdf/27/001/001/01/001/ALC/754c79125074d0e6afb8eb0e63c35a6f196ae806cd840d264b6591b367112e60.pdf?uuid=29c38017-c8fc-40f7-86e1-05b2090a6aab"
  }

  cat("URL:", url_ejemplo, "\n\n")

  # Parsear componentes
  patron <- ".*/pdf/(\\d+)/(\\d+)/(\\d+)/(\\d+)/(\\d+)/([A-Z]+)/([a-f0-9]+)\\.pdf\\?uuid=([a-f0-9-]+)"
  match <- regmatches(url_ejemplo, regexec(patron, url_ejemplo))[[1]]

  if (length(match) > 0) {
    cat("Componentes extraídos:\n")
    cat("  Departamento:", match[2], "\n")
    cat("  Municipio:", match[3], "\n")
    cat("  Zona:", match[4], "\n")
    cat("  Puesto:", match[5], "\n")
    cat("  Mesa:", match[6], "\n")
    cat("  Tipo:", match[7], "\n")
    cat("  Hash:", match[8], "\n")
    cat("  UUID:", match[9], "\n")
  } else {
    cat("⚠ No se pudo parsear la URL\n")
  }

  # Verificar si existe
  cat("\nVerificando existencia... ")
  response <- HEAD(url_ejemplo, timeout(10))

  if (status_code(response) == 200) {
    cat("✓ Existe\n")
    cat("Tamaño:", headers(response)$`content-length`, "bytes\n")
  } else {
    cat("✗ No existe (", status_code(response), ")\n")
  }
}

# ===============================================
# FUNCIÓN 6: Buscar PDFs en el contenido de la página
# ===============================================

#' Buscar todas las referencias a PDFs en la página
buscar_referencias_pdf <- function() {
  cat("\n=== BUSCANDO REFERENCIAS A PDF ===\n\n")

  url <- paste0(BASE_URL, "/departamento/27")
  response <- GET(url)

  contenido <- content(response, "text", encoding = "UTF-8")

  # Patrones para buscar
  patrones <- c(
    "PDF" = "\\.pdf[\"']?",
    "Hash" = "[a-f0-9]{64}",
    "UUID" = "[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}",
    "URL PDF" = "/assets/temis/pdf/[^\"'\\s]+"
  )

  for (nombre in names(patrones)) {
    matches <- gregexpr(patrones[[nombre]], contenido, ignore.case = TRUE)[[1]]

    if (matches[1] != -1) {
      num_matches <- length(matches)
      cat(nombre, ":", num_matches, "coincidencias\n")

      if (nombre == "URL PDF" && num_matches > 0) {
        urls <- regmatches(contenido, matches)
        urls_unicas <- unique(substr(urls, 1, 100))  # Primeros 100 caracteres
        cat("\nEjemplos de URLs encontradas:\n")
        print(head(urls_unicas, 5))
        cat("\n")
      }
    } else {
      cat(nombre, ": 0 coincidencias\n")
    }
  }
}

# ===============================================
# MENÚ PRINCIPAL
# ===============================================

menu_explorador <- function() {
  cat("\n")
  cat(rep("=", 60), "\n")
  cat("  EXPLORADOR DE API - REGISTRADURÍA BUCARAMANGA\n")
  cat(rep("=", 60), "\n\n")

  cat("Funciones disponibles:\n\n")
  cat("1. explorar_graphql()          - Probar consultas GraphQL\n")
  cat("2. obtener_config_pagina()     - Extraer config del HTML/JS\n")
  cat("3. obtener_mesas(zona, puesto) - Obtener mesas de zona/puesto\n")
  cat("4. obtener_zonas()             - Listar zonas disponibles\n")
  cat("5. analizar_url_pdf(url)       - Analizar estructura de URL\n")
  cat("6. buscar_referencias_pdf()    - Buscar PDFs en la página\n\n")

  cat("💡 Ejemplo de uso:\n")
  cat("  obtener_config_pagina()\n")
  cat("  zonas <- obtener_zonas()\n")
  cat("  obtener_mesas('001', '01')\n\n")
}

# Mostrar menú al cargar
menu_explorador()
