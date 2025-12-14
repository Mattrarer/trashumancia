# Script para Scrapear PDFs de Resultados Electorales - Registraduría Bucaramanga
# Fecha: Diciembre 2025
# Autor: Script automatizado

library(httr)
library(jsonlite)
library(rvest)
library(dplyr)
library(purrr)
library(stringr)

# ===============================================
# CONFIGURACIÓN
# ===============================================

# URL base
BASE_URL <- "https://divulgacione14bucaramanga.registraduria.gov.co"
DEPARTAMENTO <- "27"  # Santander
MUNICIPIO <- "001"     # Bucaramanga

# Directorio donde se guardarán los PDFs
CARPETA_DESCARGA <- "./pdfs_registraduria"

# Crear carpeta si no existe
if (!dir.exists(CARPETA_DESCARGA)) {
  dir.create(CARPETA_DESCARGA, recursive = TRUE)
  cat("✓ Carpeta creada:", CARPETA_DESCARGA, "\n")
}

# ===============================================
# FUNCIONES AUXILIARES
# ===============================================

#' Obtener cookies y headers necesarios
obtener_headers <- function() {
  list(
    `User-Agent` = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36",
    `Accept` = "application/json, text/plain, */*",
    `Accept-Language` = "en-US,en;q=0.9,es;q=0.8",
    `Referer` = paste0(BASE_URL, "/departamento/", DEPARTAMENTO),
    `sec-fetch-dest` = "empty",
    `sec-fetch-mode` = "cors",
    `sec-fetch-site` = "same-origin"
  )
}

#' Hacer request con manejo de errores
hacer_request <- function(url, max_reintentos = 3) {
  for (intento in 1:max_reintentos) {
    tryCatch({
      response <- GET(url, add_headers(.headers = obtener_headers()), timeout(30))

      if (status_code(response) == 200) {
        return(response)
      } else {
        cat("⚠ Intento", intento, "- Status code:", status_code(response), "\n")
      }
    }, error = function(e) {
      cat("⚠ Error en intento", intento, ":", conditionMessage(e), "\n")
      if (intento < max_reintentos) Sys.sleep(2^intento)
    })
  }
  return(NULL)
}

#' Obtener datos de zonas y puestos mediante scraping de la página principal
obtener_estructura_mesas <- function() {
  cat("🔍 Obteniendo estructura de zonas y puestos...\n")

  url_pagina <- paste0(BASE_URL, "/departamento/", DEPARTAMENTO)
  response <- hacer_request(url_pagina)

  if (is.null(response)) {
    stop("No se pudo acceder a la página principal")
  }

  # Parsear HTML
  pagina <- read_html(content(response, "text", encoding = "UTF-8"))

  # Intentar extraer información de scripts o elementos de la página
  # La estructura exacta depende del HTML de la página

  # Por ahora, vamos a intentar con una estructura típica de elecciones colombianas
  # Generalmente hay zonas y dentro de cada zona hay puestos, y dentro de cada puesto hay mesas

  cat("✓ Página principal cargada\n")
  return(pagina)
}

#' Intentar obtener datos mediante API GraphQL
obtener_datos_graphql <- function() {
  cat("🔍 Intentando obtener datos mediante GraphQL...\n")

  graphql_url <- paste0(BASE_URL, "/graphql")

  # Query para obtener información de mesas
  # Esta estructura es una estimación - necesitaría ver el request real
  query <- '{
    departamento(codigo: "27") {
      municipios {
        codigo
        nombre
        zonas {
          codigo
          nombre
          puestos {
            codigo
            nombre
            mesas {
              numero
              tipo
              urlPdf
            }
          }
        }
      }
    }
  }'

  tryCatch({
    response <- POST(
      graphql_url,
      body = list(query = query),
      encode = "json",
      add_headers(.headers = obtener_headers())
    )

    if (status_code(response) == 200) {
      datos <- content(response, "parsed")
      return(datos)
    }
  }, error = function(e) {
    cat("ℹ GraphQL no disponible, usando método alternativo\n")
  })

  return(NULL)
}

#' Generar combinaciones de zonas, puestos y mesas
#' Basado en el patrón observado: /pdf/27/001/{zona}/{puesto}/{mesa}/ALC/
generar_combinaciones_mesas <- function(
  zonas = sprintf("%03d", 1:20),     # Zonas del 001 al 020
  puestos = sprintf("%02d", 1:50),   # Puestos del 01 al 50
  mesas = sprintf("%03d", 1:100),    # Mesas del 001 al 100
  tipos = c("ALC", "CON", "GOB")     # Alcalde, Concejo, Gobernación
) {
  cat("🔧 Generando combinaciones posibles...\n")

  combinaciones <- expand.grid(
    zona = zonas,
    puesto = puestos,
    mesa = mesas,
    tipo = tipos,
    stringsAsFactors = FALSE
  )

  cat("✓ Generadas", nrow(combinaciones), "combinaciones\n")
  return(combinaciones)
}

#' Verificar si existe un PDF en una URL
verificar_pdf_existe <- function(url) {
  response <- HEAD(url, add_headers(.headers = obtener_headers()), timeout(10))

  if (status_code(response) == 200) {
    return(list(existe = TRUE, url = url))
  } else {
    return(list(existe = FALSE, url = url))
  }
}

#' Buscar PDFs mediante fuerza bruta (probando combinaciones)
buscar_pdfs_fuerza_bruta <- function(limite_zona = 5, limite_puesto = 10, limite_mesa = 20) {
  cat("🔍 Buscando PDFs mediante exploración...\n")
  cat("⚠ Esto puede tardar varios minutos...\n\n")

  zonas <- sprintf("%03d", 1:limite_zona)
  puestos <- sprintf("%02d", 1:limite_puesto)
  mesas <- sprintf("%03d", 1:limite_mesa)
  tipos <- c("ALC")  # Empezamos solo con Alcalde

  urls_encontradas <- list()
  total_verificados <- 0

  for (zona in zonas) {
    for (puesto in puestos) {
      for (mesa in mesas) {
        for (tipo in tipos) {
          # Construir URL base (sin hash ni UUID por ahora)
          url_base <- sprintf(
            "%s/assets/temis/pdf/%s/%s/%s/%s/%s/%s/",
            BASE_URL, DEPARTAMENTO, MUNICIPIO, zona, puesto, mesa, tipo
          )

          total_verificados <- total_verificados + 1

          if (total_verificados %% 100 == 0) {
            cat("📊 Verificados:", total_verificados, "| Encontrados:", length(urls_encontradas), "\n")
          }

          # Nota: Esta función está incompleta porque necesitamos el hash del archivo
          # La mejor manera es extraerlo del HTML/JavaScript de la página
        }
      }
    }
  }

  return(urls_encontradas)
}

#' Extraer URLs de PDFs del JavaScript de la página
extraer_urls_desde_pagina <- function() {
  cat("🔍 Extrayendo URLs de PDFs desde la página web...\n")

  url_pagina <- paste0(BASE_URL, "/departamento/", DEPARTAMENTO)
  response <- hacer_request(url_pagina)

  if (is.null(response)) {
    stop("No se pudo acceder a la página")
  }

  contenido <- content(response, "text", encoding = "UTF-8")

  # Buscar URLs de PDFs en el contenido
  patron_pdf <- "https://divulgacione14bucaramanga\\.registraduria\\.gov\\.co/assets/temis/pdf/[^\"']+"
  urls <- str_extract_all(contenido, patron_pdf)[[1]]

  if (length(urls) == 0) {
    # Intentar patrón alternativo (solo la ruta)
    patron_pdf_relativo <- "/assets/temis/pdf/27/[^\"']+"
    urls_relativas <- str_extract_all(contenido, patron_pdf_relativo)[[1]]
    urls <- paste0(BASE_URL, urls_relativas)
  }

  urls <- unique(urls)
  cat("✓ Encontradas", length(urls), "URLs de PDFs en la página\n")

  return(urls)
}

#' Obtener URLs de PDFs mediante API REST
obtener_urls_api <- function() {
  cat("🔍 Intentando obtener URLs mediante API...\n")

  # Probar diferentes endpoints comunes
  endpoints <- c(
    "/api/mesas",
    "/api/resultados",
    "/api/departamento/27/municipio/001/mesas",
    "/temis/api/mesas"
  )

  for (endpoint in endpoints) {
    url <- paste0(BASE_URL, endpoint)
    cat("  Probando:", endpoint, "... ")

    tryCatch({
      response <- GET(url, add_headers(.headers = obtener_headers()), timeout(10))

      if (status_code(response) == 200) {
        cat("✓ Éxito\n")
        datos <- content(response, "parsed")
        return(datos)
      } else {
        cat("✗ (", status_code(response), ")\n")
      }
    }, error = function(e) {
      cat("✗ Error\n")
    })
  }

  cat("ℹ No se encontró API REST disponible\n")
  return(NULL)
}

#' Descargar un PDF
descargar_pdf <- function(url, nombre_archivo = NULL) {
  if (is.null(nombre_archivo)) {
    # Generar nombre desde la URL
    nombre_archivo <- basename(url)
    nombre_archivo <- str_remove(nombre_archivo, "\\?.*$")  # Quitar parámetros
  }

  ruta_destino <- file.path(CARPETA_DESCARGA, nombre_archivo)

  # Si ya existe, no descargar
  if (file.exists(ruta_destino)) {
    cat("⏭ Ya existe:", nombre_archivo, "\n")
    return(list(exito = TRUE, ruta = ruta_destino, descargado = FALSE))
  }

  tryCatch({
    response <- GET(url, add_headers(.headers = obtener_headers()), timeout(30))

    if (status_code(response) == 200) {
      writeBin(content(response, "raw"), ruta_destino)
      cat("✓ Descargado:", nombre_archivo, "\n")
      return(list(exito = TRUE, ruta = ruta_destino, descargado = TRUE))
    } else {
      cat("✗ Error", status_code(response), ":", nombre_archivo, "\n")
      return(list(exito = FALSE, ruta = NULL, descargado = FALSE))
    }
  }, error = function(e) {
    cat("✗ Error descargando", nombre_archivo, ":", conditionMessage(e), "\n")
    return(list(exito = FALSE, ruta = NULL, descargado = FALSE))
  })
}

#' Descargar todos los PDFs de una lista de URLs
descargar_todos_pdfs <- function(urls) {
  cat("\n📥 Iniciando descarga de", length(urls), "PDFs...\n\n")

  resultados <- list()

  for (i in seq_along(urls)) {
    cat("[", i, "/", length(urls), "] ")
    resultado <- descargar_pdf(urls[i])
    resultados[[i]] <- resultado

    # Pausa pequeña para no saturar el servidor
    Sys.sleep(0.5)
  }

  # Resumen
  exitosos <- sum(sapply(resultados, function(x) x$exito))
  nuevos <- sum(sapply(resultados, function(x) x$descargado))

  cat("\n" , rep("=", 50), "\n")
  cat("📊 RESUMEN DE DESCARGAS\n")
  cat(rep("=", 50), "\n")
  cat("Total de PDFs: ", length(urls), "\n")
  cat("Descargados exitosamente: ", exitosos, "\n")
  cat("Nuevos (no existían): ", nuevos, "\n")
  cat("Ya existían: ", exitosos - nuevos, "\n")
  cat("Fallidos: ", length(urls) - exitosos, "\n")
  cat("Carpeta de destino: ", CARPETA_DESCARGA, "\n")
  cat(rep("=", 50), "\n\n")

  return(resultados)
}

# ===============================================
# FUNCIÓN PRINCIPAL
# ===============================================

#' Función principal para scrapear todos los PDFs
scrapear_pdfs_registraduria <- function(metodo = "auto") {
  cat("\n")
  cat(rep("=", 60), "\n")
  cat("  SCRAPER DE PDFs - REGISTRADURÍA BUCARAMANGA  \n")
  cat(rep("=", 60), "\n\n")

  urls_pdfs <- c()

  # Intentar diferentes métodos para obtener las URLs
  if (metodo == "auto" || metodo == "api") {
    datos_api <- obtener_urls_api()
    if (!is.null(datos_api)) {
      # Extraer URLs de la respuesta de la API
      # (esto depende de la estructura real de la API)
    }
  }

  if (metodo == "auto" || metodo == "graphql") {
    datos_graphql <- obtener_datos_graphql()
    if (!is.null(datos_graphql)) {
      # Extraer URLs del GraphQL
    }
  }

  if (metodo == "auto" || metodo == "pagina") {
    urls_pagina <- tryCatch({
      extraer_urls_desde_pagina()
    }, error = function(e) {
      cat("⚠ Error al extraer URLs de la página:", conditionMessage(e), "\n")
      c()
    })

    urls_pdfs <- c(urls_pdfs, urls_pagina)
  }

  # Si no se encontraron URLs, mostrar instrucciones
  if (length(urls_pdfs) == 0) {
    cat("\n⚠ No se pudieron obtener URLs automáticamente.\n\n")
    cat("📝 INSTRUCCIONES MANUALES:\n")
    cat("1. Abre el navegador y ve a: ", BASE_URL, "/departamento/", DEPARTAMENTO, "\n", sep = "")
    cat("2. Abre las DevTools (F12) y ve a la pestaña Network\n")
    cat("3. Filtra por 'pdf' o 'XHR'\n")
    cat("4. Interactúa con la página (selecciona zonas/puestos/mesas)\n")
    cat("5. Copia las URLs de los PDFs que aparezcan\n")
    cat("6. Usa la función: descargar_pdf(url) para descargar cada uno\n\n")
    cat("O bien, proporciona las URLs directamente:\n")
    cat("urls <- c('url1', 'url2', '...')\n")
    cat("descargar_todos_pdfs(urls)\n\n")

    return(invisible(NULL))
  }

  # Descargar todos los PDFs encontrados
  resultados <- descargar_todos_pdfs(urls_pdfs)

  return(resultados)
}

# ===============================================
# EJECUCIÓN
# ===============================================

# Descomentar para ejecutar:
# resultados <- scrapear_pdfs_registraduria()

cat("\n✓ Script cargado exitosamente\n\n")
cat("📖 FUNCIONES DISPONIBLES:\n")
cat("  • scrapear_pdfs_registraduria()  - Función principal\n")
cat("  • descargar_pdf(url)             - Descargar un PDF específico\n")
cat("  • descargar_todos_pdfs(urls)     - Descargar lista de PDFs\n")
cat("  • extraer_urls_desde_pagina()    - Extraer URLs del HTML\n\n")
cat("💡 EJEMPLO DE USO:\n")
cat("  # Método 1: Automático\n")
cat("  resultados <- scrapear_pdfs_registraduria()\n\n")
cat("  # Método 2: URLs manuales\n")
cat("  urls <- c(\n")
cat("    'https://divulgacione14bucaramanga.registraduria.gov.co/assets/temis/pdf/27/001/001/01/001/ALC/xxx.pdf?uuid=xxx'\n")
cat("  )\n")
cat("  descargar_todos_pdfs(urls)\n\n")
