# Script Directo para Descargar PDFs de la Registraduría
# Basado en el análisis del Network tab de DevTools

library(httr)
library(jsonlite)
library(stringr)

# Librerías para paralelización (instaladas automáticamente si no existen)
if (!require("future", quietly = TRUE)) {
  cat("📦 Instalando paquete 'future'...\n")
  install.packages("future", quiet = TRUE)
  library(future)
}

if (!require("furrr", quietly = TRUE)) {
  cat("📦 Instalando paquete 'furrr'...\n")
  install.packages("furrr", quiet = TRUE)
  library(furrr)
}

# ===============================================
# CONFIGURACIÓN
# ===============================================

BASE_URL <- "https://divulgacione14bucaramanga.registraduria.gov.co"
CARPETA_DESCARGA <- "./pdfs_registraduria"

# Crear carpeta
if (!dir.exists(CARPETA_DESCARGA)) {
  dir.create(CARPETA_DESCARGA, recursive = TRUE)
}

# ===============================================
# MÉTODO 1: USANDO GRAPHQL (Recomendado)
# ===============================================

#' Obtener datos de mesas mediante GraphQL
#' Basado en las llamadas que viste en el Network tab
obtener_mesas_graphql <- function(zona = NULL, puesto = NULL) {
  cat("🔍 Obteniendo datos mediante GraphQL...\n")

  graphql_url <- paste0(BASE_URL, "/graphql")

  # Query GraphQL para obtener mesas
  # Esta es una estimación basada en estructura típica
  # Ajusta según lo que veas en el Network tab
  query <- sprintf('{
    consultarMesas(
      departamento: "27",
      municipio: "001"%s%s
    ) {
      numero
      zona
      puesto
      tipo
      urlPdf
      hash
      uuid
    }
  }',
  if (!is.null(zona)) sprintf(', zona: "%s"', zona) else "",
  if (!is.null(puesto)) sprintf(', puesto: "%s"', puesto) else ""
  )

  # Headers basados en tu captura
  headers <- c(
    `User-Agent` = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36",
    `Accept` = "application/json, text/plain, */*",
    `Accept-Language` = "en-US,en;q=0.9,es;q=0.8",
    `Content-Type` = "application/json",
    `Referer` = paste0(BASE_URL, "/departamento/27"),
    `sec-fetch-dest` = "empty",
    `sec-fetch-mode` = "cors",
    `sec-fetch-site` = "same-origin"
  )

  response <- tryCatch({
    POST(
      graphql_url,
      body = toJSON(list(query = query), auto_unbox = TRUE),
      encode = "json",
      add_headers(.headers = headers),
      timeout(30)
    )
  }, error = function(e) {
    cat("✗ Error:", conditionMessage(e), "\n")
    return(NULL)
  })

  if (!is.null(response) && status_code(response) == 200) {
    datos <- content(response, "parsed")
    cat("✓ Datos obtenidos exitosamente\n")
    return(datos)
  } else {
    if (!is.null(response)) {
      cat("✗ Error HTTP:", status_code(response), "\n")
      cat("Respuesta:", content(response, "text"), "\n")
    }
    return(NULL)
  }
}

# ===============================================
# MÉTODO 2: CONSTRUCCIÓN MANUAL DE URLs
# ===============================================

#' Construir URL de PDF manualmente
#' Cuando conoces los parámetros pero no el hash/UUID
construir_url_pdf <- function(zona, puesto, mesa, tipo = "ALC", hash = NULL, uuid = NULL) {

  # Si no hay hash/uuid, no podemos construir la URL completa
  if (is.null(hash) || is.null(uuid)) {
    cat("⚠ Necesitas el hash y UUID para construir la URL completa\n")
    cat("  Estos se obtienen de la API GraphQL o del HTML de la página\n")
    return(NULL)
  }

  url <- sprintf(
    "%s/assets/temis/pdf/27/001/%s/%s/%s/%s/%s.pdf?uuid=%s",
    BASE_URL,
    zona,
    puesto,
    mesa,
    tipo,
    hash,
    uuid
  )

  return(url)
}

# ===============================================
# MÉTODO 3: COPIAR URLs DESDE DEVTOOLS
# ===============================================

#' Importar URLs desde un archivo de texto
#' Después de copiarlas del Network tab
importar_urls_desde_archivo <- function(archivo = "urls_pdfs.txt") {
  if (!file.exists(archivo)) {
    cat("✗ Archivo no encontrado:", archivo, "\n")
    cat("\n📝 INSTRUCCIONES:\n")
    cat("1. Crea un archivo llamado", archivo, "\n")
    cat("2. Pega las URLs de los PDFs (una por línea)\n")
    cat("3. Guarda el archivo\n")
    cat("4. Ejecuta esta función nuevamente\n\n")
    return(character(0))
  }

  urls <- readLines(archivo, warn = FALSE)
  urls <- urls[urls != "" & !grepl("^#", urls)]  # Eliminar líneas vacías y comentarios

  cat("✓ Leídas", length(urls), "URLs desde", archivo, "\n")
  return(urls)
}

# ===============================================
# MÉTODO 4: EXTRAER URLs DEL CLIPBOARD
# ===============================================

#' Importar URLs desde portapapeles
#' Después de copiarlas del DevTools
importar_urls_desde_clipboard <- function() {
  tryCatch({
    if (.Platform$OS.type == "windows") {
      urls <- readLines("clipboard")
    } else {
      # Linux/Mac: requiere xclip o pbpaste
      urls <- system("xclip -selection clipboard -o", intern = TRUE)
    }

    urls <- urls[urls != "" & grepl("http", urls)]
    cat("✓ Importadas", length(urls), "URLs desde portapapeles\n")
    return(urls)
  }, error = function(e) {
    cat("✗ No se pudo leer el portapapeles\n")
    cat("  Usa importar_urls_desde_archivo() en su lugar\n")
    return(character(0))
  })
}

# ===============================================
# FUNCIÓN DE DESCARGA
# ===============================================

#' Descargar un PDF con manejo de errores robusto
descargar_pdf <- function(url, carpeta = CARPETA_DESCARGA) {

  # Extraer nombre del archivo
  nombre_archivo <- basename(url)
  nombre_archivo <- str_remove(nombre_archivo, "\\?.*$")

  # Agregar subcarpetas por zona/puesto si es posible
  partes <- str_match(url, "/pdf/27/001/(\\d+)/(\\d+)/(\\d+)/([A-Z]+)/")
  if (!is.na(partes[1])) {
    zona <- partes[2]
    puesto <- partes[3]
    mesa <- partes[4]
    tipo <- partes[5]

    # Crear subcarpeta
    subcarpeta <- file.path(carpeta, paste0("Zona_", zona), paste0("Puesto_", puesto))
    if (!dir.exists(subcarpeta)) {
      dir.create(subcarpeta, recursive = TRUE)
    }

    # Nombre más descriptivo
    nombre_archivo <- sprintf("%s_Mesa_%s_%s.pdf", tipo, mesa, nombre_archivo)
    ruta_destino <- file.path(subcarpeta, nombre_archivo)
  } else {
    ruta_destino <- file.path(carpeta, nombre_archivo)
  }

  # Si ya existe, saltar
  if (file.exists(ruta_destino)) {
    cat("⏭ ", basename(ruta_destino), "\n")
    return(list(exito = TRUE, ruta = ruta_destino, nuevo = FALSE))
  }

  # Descargar
  tryCatch({
    response <- GET(
      url,
      add_headers(
        `User-Agent` = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36",
        `Referer` = paste0(BASE_URL, "/departamento/27")
      ),
      timeout(30)
    )

    if (status_code(response) == 200) {
      writeBin(content(response, "raw"), ruta_destino)
      cat("✓ ", basename(ruta_destino), "\n")
      return(list(exito = TRUE, ruta = ruta_destino, nuevo = TRUE))
    } else {
      cat("✗ Error", status_code(response), "-", basename(ruta_destino), "\n")
      return(list(exito = FALSE, ruta = NULL, nuevo = FALSE))
    }
  }, error = function(e) {
    cat("✗ Error:", conditionMessage(e), "\n")
    return(list(exito = FALSE, ruta = NULL, nuevo = FALSE))
  })
}

#' Descargar múltiples PDFs con progreso
descargar_lote <- function(urls, pausa = 0.5) {
  cat("\n📥 Descargando", length(urls), "PDFs...\n\n")

  resultados <- list()
  pb <- txtProgressBar(min = 0, max = length(urls), style = 3)

  for (i in seq_along(urls)) {
    setTxtProgressBar(pb, i)
    resultados[[i]] <- descargar_pdf(urls[i])
    Sys.sleep(pausa)  # Pausa para no saturar el servidor
  }

  close(pb)

  # Resumen
  exitosos <- sum(sapply(resultados, function(x) x$exito))
  nuevos <- sum(sapply(resultados, function(x) x$nuevo))

  cat("\n\n📊 RESUMEN:\n")
  cat("  Total:", length(urls), "\n")
  cat("  Exitosos:", exitosos, "\n")
  cat("  Nuevos:", nuevos, "\n")
  cat("  Ya existían:", exitosos - nuevos, "\n")
  cat("  Fallidos:", length(urls) - exitosos, "\n")

  return(resultados)
}

# ===============================================
# DESCARGA PARALELA CON WORKERS (⚡ RÁPIDO)
# ===============================================

#' Configurar el número de workers para descarga paralela
#' @param num_workers Número de procesos paralelos (default: detecta automáticamente)
#' @param estrategia "multicore" (Linux/Mac) o "multisession" (Windows/todos)
configurar_workers <- function(num_workers = NULL, estrategia = NULL) {

  # Detectar número óptimo de workers
  if (is.null(num_workers)) {
    # Usar el 75% de los cores disponibles
    num_cores <- parallel::detectCores()
    num_workers <- max(1, floor(num_cores * 0.75))
  }

  # Detectar estrategia según el sistema operativo
  if (is.null(estrategia)) {
    if (.Platform$OS.type == "unix") {
      estrategia <- "multicore"  # Más eficiente en Linux/Mac
    } else {
      estrategia <- "multisession"  # Compatible con Windows
    }
  }

  # Configurar plan de paralelización
  plan(estrategia, workers = num_workers)

  cat("✓ Configurados", num_workers, "workers con estrategia:", estrategia, "\n")
  cat("  Sistema operativo:", .Platform$OS.type, "\n")
  cat("  Cores disponibles:", parallel::detectCores(), "\n\n")

  return(invisible(num_workers))
}

#' Descargar un PDF (versión silenciosa para uso paralelo)
descargar_pdf_silencioso <- function(url, carpeta = CARPETA_DESCARGA) {

  # Extraer nombre del archivo
  nombre_archivo <- basename(url)
  nombre_archivo <- stringr::str_remove(nombre_archivo, "\\?.*$")

  # Agregar subcarpetas por zona/puesto si es posible
  partes <- stringr::str_match(url, "/pdf/27/001/(\\d+)/(\\d+)/(\\d+)/([A-Z]+)/")
  if (!is.na(partes[1])) {
    zona <- partes[2]
    puesto <- partes[3]
    mesa <- partes[4]
    tipo <- partes[5]

    # Crear subcarpeta
    subcarpeta <- file.path(carpeta, paste0("Zona_", zona), paste0("Puesto_", puesto))
    if (!dir.exists(subcarpeta)) {
      dir.create(subcarpeta, recursive = TRUE, showWarnings = FALSE)
    }

    # Nombre más descriptivo
    nombre_archivo <- sprintf("%s_Mesa_%s_%s.pdf", tipo, mesa, nombre_archivo)
    ruta_destino <- file.path(subcarpeta, nombre_archivo)
  } else {
    ruta_destino <- file.path(carpeta, nombre_archivo)
  }

  # Si ya existe, saltar
  if (file.exists(ruta_destino)) {
    return(list(
      exito = TRUE,
      ruta = ruta_destino,
      nuevo = FALSE,
      url = url,
      nombre = basename(ruta_destino)
    ))
  }

  # Descargar
  tryCatch({
    response <- httr::GET(
      url,
      httr::add_headers(
        `User-Agent` = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36",
        `Referer` = paste0(BASE_URL, "/departamento/27")
      ),
      httr::timeout(30)
    )

    if (httr::status_code(response) == 200) {
      writeBin(httr::content(response, "raw"), ruta_destino)
      return(list(
        exito = TRUE,
        ruta = ruta_destino,
        nuevo = TRUE,
        url = url,
        nombre = basename(ruta_destino)
      ))
    } else {
      return(list(
        exito = FALSE,
        ruta = NULL,
        nuevo = FALSE,
        url = url,
        nombre = basename(ruta_destino),
        error = paste("HTTP", httr::status_code(response))
      ))
    }
  }, error = function(e) {
    return(list(
      exito = FALSE,
      ruta = NULL,
      nuevo = FALSE,
      url = url,
      nombre = nombre_archivo,
      error = conditionMessage(e)
    ))
  })
}

#' Descargar múltiples PDFs en paralelo (⚡ VERSIÓN RÁPIDA)
#' @param urls Vector de URLs a descargar
#' @param num_workers Número de workers paralelos (NULL = auto-detectar)
#' @param estrategia "multicore" (Linux/Mac) o "multisession" (Windows)
#' @param mostrar_progreso Mostrar barra de progreso (default: TRUE)
descargar_lote_paralelo <- function(urls, num_workers = NULL, estrategia = NULL, mostrar_progreso = TRUE) {

  cat("\n⚡ DESCARGA PARALELA ACTIVADA ⚡\n")
  cat(rep("=", 70), "\n\n")

  # Configurar workers
  num_workers_real <- configurar_workers(num_workers, estrategia)

  cat("📥 Descargando", length(urls), "PDFs en paralelo...\n")
  cat("⏱  Tiempo estimado:", round(length(urls) / num_workers_real * 0.5, 1), "segundos\n\n")

  # Descargar en paralelo con barra de progreso
  if (mostrar_progreso) {
    resultados <- furrr::future_map(
      urls,
      descargar_pdf_silencioso,
      .options = furrr_options(seed = TRUE),
      .progress = TRUE
    )
  } else {
    resultados <- furrr::future_map(
      urls,
      descargar_pdf_silencioso,
      .options = furrr_options(seed = TRUE)
    )
  }

  # Resetear plan a secuencial
  plan(sequential)

  # Resumen detallado
  exitosos <- sum(sapply(resultados, function(x) x$exito))
  nuevos <- sum(sapply(resultados, function(x) x$nuevo))
  fallidos <- length(urls) - exitosos

  cat("\n\n")
  cat(rep("=", 70), "\n")
  cat("📊 RESUMEN DE DESCARGA PARALELA\n")
  cat(rep("=", 70), "\n")
  cat("  Total de PDFs:      ", length(urls), "\n")
  cat("  ✓ Exitosos:         ", exitosos, "\n")
  cat("  ✨ Nuevos:          ", nuevos, "\n")
  cat("  ⏭  Ya existían:     ", exitosos - nuevos, "\n")
  cat("  ✗ Fallidos:         ", fallidos, "\n")
  cat("  ⚡ Workers usados:  ", num_workers_real, "\n")
  cat(rep("=", 70), "\n\n")

  # Mostrar errores si los hay
  if (fallidos > 0) {
    cat("❌ PDFs que fallaron:\n")
    for (i in seq_along(resultados)) {
      if (!resultados[[i]]$exito) {
        cat("  -", resultados[[i]]$nombre, "\n")
        if (!is.null(resultados[[i]]$error)) {
          cat("    Error:", resultados[[i]]$error, "\n")
        }
      }
    }
    cat("\n")
  }

  return(resultados)
}

#' Descargar con chunks (grupos) para balancear velocidad y control
#' @param urls Vector de URLs
#' @param chunk_size Tamaño de cada grupo (default: 10)
#' @param num_workers Número de workers por chunk
#' @param pausa_entre_chunks Pausa en segundos entre chunks (default: 2)
descargar_lote_por_chunks <- function(urls, chunk_size = 10, num_workers = 4, pausa_entre_chunks = 2) {

  cat("\n📦 DESCARGA POR CHUNKS (GRUPOS)\n")
  cat(rep("=", 70), "\n\n")

  # Dividir URLs en chunks
  num_chunks <- ceiling(length(urls) / chunk_size)
  chunks <- split(urls, ceiling(seq_along(urls) / chunk_size))

  cat("📊 Configuración:\n")
  cat("  Total de PDFs:     ", length(urls), "\n")
  cat("  Tamaño de chunk:   ", chunk_size, "\n")
  cat("  Número de chunks:  ", num_chunks, "\n")
  cat("  Workers por chunk: ", num_workers, "\n")
  cat("  Pausa entre chunks:", pausa_entre_chunks, "segundos\n\n")

  # Procesar cada chunk
  todos_resultados <- list()

  for (i in seq_along(chunks)) {
    cat("\n📦 Procesando chunk", i, "de", num_chunks, "(", length(chunks[[i]]), "PDFs )\n")
    cat(rep("-", 70), "\n")

    resultados_chunk <- descargar_lote_paralelo(
      chunks[[i]],
      num_workers = num_workers,
      mostrar_progreso = TRUE
    )

    todos_resultados <- c(todos_resultados, resultados_chunk)

    # Pausa entre chunks (excepto en el último)
    if (i < num_chunks) {
      cat("⏸  Pausa de", pausa_entre_chunks, "segundos antes del siguiente chunk...\n")
      Sys.sleep(pausa_entre_chunks)
    }
  }

  # Resumen final
  exitosos <- sum(sapply(todos_resultados, function(x) x$exito))
  nuevos <- sum(sapply(todos_resultados, function(x) x$nuevo))

  cat("\n\n")
  cat(rep("=", 70), "\n")
  cat("📊 RESUMEN FINAL\n")
  cat(rep("=", 70), "\n")
  cat("  Total procesado:    ", length(urls), "\n")
  cat("  ✓ Exitosos:         ", exitosos, "\n")
  cat("  ✨ Nuevos:          ", nuevos, "\n")
  cat("  ⏭  Ya existían:     ", exitosos - nuevos, "\n")
  cat("  ✗ Fallidos:         ", length(urls) - exitosos, "\n")
  cat(rep("=", 70), "\n\n")

  return(todos_resultados)
}

# ===============================================
# FLUJO DE TRABAJO RECOMENDADO
# ===============================================

cat("\n")
cat(rep("=", 70), "\n")
cat("  DESCARGADOR DE PDFs - REGISTRADURÍA BUCARAMANGA\n")
cat(rep("=", 70), "\n\n")

cat("📋 FLUJO DE TRABAJO RECOMENDADO:\n\n")

cat("OPCIÓN 1: Capturar URLs desde DevTools (Más Fácil)\n")
cat("--------------------------------------------------\n")
cat("1. Abre la página en el navegador:\n")
cat("   ", BASE_URL, "/departamento/27\n\n", sep = "")
cat("2. Abre DevTools (F12) → Pestaña Network\n")
cat("3. Filtra por 'pdf' en el campo de búsqueda\n")
cat("4. Marca 'Preserve log' ✓\n")
cat("5. Selecciona zona/puesto y haz clic en Ver (para todas las mesas)\n")
cat("6. Copia las URLs de los PDFs que aparezcan\n")
cat("7. Pégalas en un archivo urls_pdfs.txt (una por línea)\n")
cat("8. Ejecuta:\n")
cat("     urls <- importar_urls_desde_archivo('urls_pdfs.txt')\n")
cat("     descargar_lote(urls)\n\n")

cat("OPCIÓN 2: Usar GraphQL (Automático)\n")
cat("------------------------------------\n")
cat("1. Ejecuta:\n")
cat("     datos <- obtener_mesas_graphql()\n")
cat("2. Si funciona, extrae las URLs:\n")
cat("     urls <- datos$data$consultarMesas$urlPdf\n")
cat("     descargar_lote(urls)\n\n")

cat("OPCIÓN 3: URLs directas (Si ya las tienes)\n")
cat("------------------------------------------\n")
cat("urls <- c(\n")
cat("  'https://divulgacione14bucaramanga.registraduria.gov.co/assets/temis/pdf/27/001/001/01/001/ALC/xxx.pdf?uuid=xxx',\n")
cat("  'https://divulgacione14bucaramanga.registraduria.gov.co/assets/temis/pdf/27/001/001/01/002/ALC/yyy.pdf?uuid=yyy'\n")
cat(")\n")
cat("descargar_lote(urls)           # Secuencial (lento)\n")
cat("descargar_lote_paralelo(urls)  # ⚡ PARALELO (RÁPIDO)\n\n")

cat("⚡ DESCARGA PARALELA (NUEVA FUNCIONALIDAD):\n")
cat("------------------------------------------\n")
cat("# Descarga súper rápida con todos los cores disponibles\n")
cat("descargar_lote_paralelo(urls)\n\n")
cat("# Controlar número de workers manualmente\n")
cat("descargar_lote_paralelo(urls, num_workers = 4)\n\n")
cat("# Descargar por chunks (grupos) - más controlado\n")
cat("descargar_lote_por_chunks(urls, chunk_size = 20, num_workers = 4)\n\n")

cat("📁 Los PDFs se guardarán en:", CARPETA_DESCARGA, "\n")
cat("   Organizados por: Zona_XXX/Puesto_YY/\n\n")

cat("💡 RECOMENDACIÓN:\n")
cat("   • Pocas URLs (<50):     descargar_lote_paralelo(urls)\n")
cat("   • Muchas URLs (>100):   descargar_lote_por_chunks(urls)\n")
cat("   • Servidor lento:       descargar_lote(urls) # secuencial\n\n")
