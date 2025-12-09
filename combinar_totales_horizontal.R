# ============================================================================
# SCRIPT PARA COMBINAR COLUMNAS "TOTAL" HORIZONTALMENTE
# ============================================================================
# Este script lee múltiples archivos Excel con reportes de diferentes fechas
# y combina SOLO la columna "Total" de cada uno, agregándolas horizontalmente
# sin duplicar filas.
#
# IMPORTANTE:
# - La fila 1 se ignora (es el título del documento)
# - La fila 2 se usa como encabezados de columnas
# - Solo se agrega la columna "Total" de cada archivo
# - Las filas NO aumentan, solo se agregan columnas
# ============================================================================

# 1. Instalar paquetes (ejecutar solo la primera vez)
# install.packages("readxl")
# install.packages("dplyr")
# install.packages("stringr")
# install.packages("writexl")

# 2. Cargar librerías
library(readxl)
library(dplyr)
library(stringr)
library(writexl)

# ============================================================================
# FUNCIÓN PRINCIPAL
# ============================================================================

combinar_totales_horizontal <- function(ruta_carpeta,
                                        patron_fecha = "\\d{2}-\\d{2}-\\d{4}",
                                        archivo_salida = "resultado_totales_combinados.xlsx") {

  # Obtener lista de archivos Excel ordenados alfabéticamente
  archivos <- list.files(
    path = ruta_carpeta,
    pattern = "\\.(xlsx|xls)$",
    full.names = TRUE,
    ignore.case = TRUE
  )

  if (length(archivos) == 0) {
    stop("No se encontraron archivos Excel en la carpeta especificada.")
  }

  # Ordenar archivos por fecha extraída del nombre
  fechas_archivos <- sapply(archivos, function(x) {
    str_extract(basename(x), patron_fecha)
  })

  # Convertir fechas a formato Date para ordenamiento correcto
  fechas_date <- as.Date(fechas_archivos, format = "%d-%m-%Y")
  orden <- order(fechas_date)

  archivos <- archivos[orden]
  fechas_archivos <- fechas_archivos[orden]

  cat("Se encontraron", length(archivos), "archivos Excel\n")
  cat("Orden de procesamiento:\n")
  for (i in seq_along(archivos)) {
    cat(sprintf("  %d. %s (Fecha: %s)\n", i, basename(archivos[i]), fechas_archivos[i]))
  }
  cat("\n")

  # Variable para almacenar el resultado final
  resultado <- NULL

  # Procesar cada archivo
  for (i in seq_along(archivos)) {

    archivo <- archivos[i]
    nombre_archivo <- basename(archivo)
    fecha <- fechas_archivos[i]

    cat("Procesando archivo", i, "de", length(archivos), ":", nombre_archivo, "\n")

    tryCatch({

      # Leer el archivo Excel IGNORANDO la primera fila (título)
      # skip = 1 significa que se salta la fila 1 y usa la fila 2 como encabezados
      datos <- read_excel(archivo, skip = 1)

      # Verificar que existan las columnas necesarias
      if (i == 1) {
        # Primer archivo: tomarlo como base
        # Verificar que tenga las columnas básicas
        columnas_requeridas <- c("Código", "Departamento", "Municipio", "Total")

        # A veces los nombres de columna pueden tener espacios o caracteres especiales
        # Normalizar nombres de columnas
        names(datos) <- trimws(names(datos))

        if (!all(columnas_requeridas %in% names(datos))) {
          # Mostrar las columnas disponibles
          cat("Columnas disponibles en el archivo:", paste(names(datos), collapse = ", "), "\n")

          # Intentar encontrar columnas similares
          codigo_col <- grep("^[Cc]ódigo|^[Cc]odigo|^CÓDIGO|^CODIGO", names(datos), value = TRUE)[1]
          depto_col <- grep("^[Dd]epartamento|^DEPARTAMENTO", names(datos), value = TRUE)[1]
          muni_col <- grep("^[Mm]unicipio|^MUNICIPIO", names(datos), value = TRUE)[1]
          total_col <- grep("^[Tt]otal|^TOTAL", names(datos), value = TRUE)[1]

          if (any(is.na(c(codigo_col, depto_col, muni_col, total_col)))) {
            stop(paste("No se encontraron las columnas requeridas en el primer archivo:", nombre_archivo))
          }

          # Renombrar columnas encontradas
          names(datos)[names(datos) == codigo_col] <- "Código"
          names(datos)[names(datos) == depto_col] <- "Departamento"
          names(datos)[names(datos) == muni_col] <- "Municipio"
          names(datos)[names(datos) == total_col] <- "Total"
        }

        # Seleccionar columnas relevantes del primer archivo
        resultado <- datos %>%
          select(Código, Departamento, Municipio, Total)

        # Renombrar la columna Total con la fecha
        names(resultado)[names(resultado) == "Total"] <- fecha

        cat("  ✓ Archivo base cargado:", nrow(resultado), "filas\n")

      } else {
        # Archivos siguientes: solo extraer columna Total

        # Normalizar nombres de columnas
        names(datos) <- trimws(names(datos))

        # Buscar columna Código y Total
        codigo_col <- grep("^[Cc]ódigo|^[Cc]odigo|^CÓDIGO|^CODIGO", names(datos), value = TRUE)[1]
        total_col <- grep("^[Tt]otal|^TOTAL", names(datos), value = TRUE)[1]

        if (is.na(codigo_col) || is.na(total_col)) {
          warning(paste("No se encontraron columnas Código o Total en:", nombre_archivo, "- Saltando archivo"))
          next
        }

        # Extraer solo Código y Total
        datos_nuevos <- datos %>%
          select(all_of(c(codigo_col, total_col))) %>%
          rename(Código = all_of(codigo_col))

        # Renombrar la columna Total con la fecha
        nombre_total <- fecha
        names(datos_nuevos)[names(datos_nuevos) == total_col] <- nombre_total

        # Hacer merge horizontal con el resultado existente
        # left_join mantiene todas las filas del resultado y agrega la nueva columna
        filas_antes <- nrow(resultado)
        resultado <- resultado %>%
          left_join(datos_nuevos, by = "Código")

        filas_despues <- nrow(resultado)

        if (filas_antes != filas_despues) {
          warning(paste("ADVERTENCIA: El número de filas cambió después de agregar", nombre_archivo))
          warning(paste("  Filas antes:", filas_antes, "- Filas después:", filas_despues))
        }

        cat("  ✓ Columna agregada:", nombre_total, "\n")
      }

    }, error = function(e) {
      warning(paste("ERROR al procesar:", nombre_archivo, "-", e$message))
    })
  }

  # Guardar resultado
  if (!is.null(resultado)) {

    cat("\n")
    cat("=" , rep("=", 70), "\n", sep = "")
    cat("RESULTADO FINAL\n")
    cat("=" , rep("=", 70), "\n", sep = "")
    cat("Total de filas:", nrow(resultado), "\n")
    cat("Total de columnas:", ncol(resultado), "\n")
    cat("Columnas:\n")
    for (col in names(resultado)) {
      cat("  -", col, "\n")
    }
    cat("\n")

    # ========================================================================
    # CALCULAR TOP 10 MUNICIPIOS CON MAYOR ÍNDICE DE CRECIMIENTO
    # ========================================================================

    # Identificar columnas de fechas (todas excepto Código, Departamento, Municipio)
    columnas_fechas <- setdiff(names(resultado), c("Código", "Departamento", "Municipio"))

    if (length(columnas_fechas) >= 2) {
      cat("=" , rep("=", 70), "\n", sep = "")
      cat("CALCULANDO ÍNDICE DE CRECIMIENTO\n")
      cat("=" , rep("=", 70), "\n", sep = "")

      # Primera y última fecha
      primera_fecha <- columnas_fechas[1]
      ultima_fecha <- columnas_fechas[length(columnas_fechas)]

      cat("Primera fecha:", primera_fecha, "\n")
      cat("Última fecha:", ultima_fecha, "\n\n")

      # Calcular crecimiento
      tabla_crecimiento <- resultado %>%
        mutate(
          Total_Inicial = .data[[primera_fecha]],
          Total_Final = .data[[ultima_fecha]],
          Crecimiento_Absoluto = Total_Final - Total_Inicial,
          Indice_Crecimiento_Pct = ifelse(
            Total_Inicial > 0,
            round((Total_Final - Total_Inicial) / Total_Inicial * 100, 2),
            NA
          )
        ) %>%
        select(Código, Departamento, Municipio, Total_Inicial, Total_Final,
               Crecimiento_Absoluto, Indice_Crecimiento_Pct) %>%
        arrange(desc(Indice_Crecimiento_Pct))

      # Top 10 municipios
      top_10_crecimiento <- tabla_crecimiento %>%
        filter(!is.na(Indice_Crecimiento_Pct)) %>%
        head(10)

      # Renombrar columnas para mejor presentación
      top_10_presentacion <- top_10_crecimiento %>%
        rename(
          `Total Inicial` = Total_Inicial,
          `Total Final` = Total_Final,
          `Crecimiento Absoluto` = Crecimiento_Absoluto,
          `Índice de Crecimiento (%)` = Indice_Crecimiento_Pct
        )

      cat("TOP 10 MUNICIPIOS CON MAYOR ÍNDICE DE CRECIMIENTO:\n\n")
      for (i in 1:nrow(top_10_presentacion)) {
        cat(sprintf(
          "%2d. %s (%s) - %s%% de crecimiento (de %s a %s)\n",
          i,
          top_10_presentacion$Municipio[i],
          top_10_presentacion$Departamento[i],
          format(top_10_presentacion$`Índice de Crecimiento (%)`[i], nsmall = 2),
          format(top_10_presentacion$`Total Inicial`[i], big.mark = ","),
          format(top_10_presentacion$`Total Final`[i], big.mark = ",")
        ))
      }
      cat("\n")

      # Crear lista de hojas para el Excel
      hojas_excel <- list(
        "Datos Combinados" = resultado,
        "Top 10 Crecimiento" = top_10_presentacion
      )

    } else {
      cat("No hay suficientes fechas para calcular crecimiento.\n")
      hojas_excel <- list("Datos Combinados" = resultado)
    }

    # Guardar en Excel con múltiples hojas
    ruta_completa <- file.path(ruta_carpeta, archivo_salida)
    write_xlsx(hojas_excel, ruta_completa)
    cat("Archivo guardado en:", ruta_completa, "\n")

    # También guardar en CSV por si acaso
    archivo_csv <- sub("\\.xlsx$", ".csv", archivo_salida)
    ruta_csv <- file.path(ruta_carpeta, archivo_csv)
    write.csv(resultado, ruta_csv, row.names = FALSE, fileEncoding = "UTF-8")
    cat("También guardado en CSV:", ruta_csv, "\n")

    return(resultado)

  } else {
    stop("No se pudo procesar ningún archivo correctamente.")
  }
}

# ============================================================================
# EJEMPLO DE USO
# ============================================================================

# CONFIGURACIÓN
# Cambia esta ruta a la carpeta donde están tus archivos Excel
ruta_mis_datos <- "./datos_excel"  # <-- CAMBIA ESTO

# EJECUTAR
# Descomenta las siguientes líneas para ejecutar el script:
#
# resultado <- combinar_totales_horizontal(
#   ruta_carpeta = ruta_mis_datos,
#   patron_fecha = "\\d{2}-\\d{2}-\\d{4}",  # Formato dd-mm-aaaa
#   archivo_salida = "totales_combinados.xlsx"
# )
#
# # Ver resultado
# print(resultado)
# View(resultado)

# ============================================================================
# NOTAS IMPORTANTES
# ============================================================================
#
# 1. ESTRUCTURA ESPERADA DE LOS ARCHIVOS:
#    - Fila 1: Título del documento (SE IGNORA)
#    - Fila 2: Nombres de columnas (Código, Departamento, Municipio, Total, etc.)
#    - Fila 3+: Datos
#
# 2. COLUMNAS REQUERIDAS:
#    - "Código" (o "Codigo"): Identificador único para cada fila
#    - "Departamento": Nombre del departamento
#    - "Municipio": Nombre del municipio
#    - "Total": Valor total que se quiere combinar
#
# 3. FORMATO DE NOMBRES DE ARCHIVOS:
#    - Los archivos deben tener la fecha en el nombre
#    - Ejemplo: "Reporte_08-03-2025.xlsx", "datos_30-11-2025.xlsx"
#    - El patrón por defecto busca dd-mm-aaaa
#
# 4. RESULTADO:
#    - El primer archivo se toma como base (Código, Departamento, Municipio, Total)
#    - Cada archivo adicional agrega UNA columna con el nombre de la fecha
#    - Las filas NO se duplican, solo se agregan columnas horizontalmente
#    - Se hace match por el campo "Código"
#    - El archivo Excel de salida contiene DOS HOJAS:
#      * "Datos Combinados": Todos los datos con columnas por fecha
#      * "Top 10 Crecimiento": Los 10 municipios con mayor índice de crecimiento
#
# 5. ORDEN DE PROCESAMIENTO:
#    - Los archivos se procesan en orden cronológico ascendente (por fecha en el nombre)
#    - Las columnas aparecen de izquierda a derecha en orden cronológico
#
# 6. ÍNDICE DE CRECIMIENTO:
#    - Se calcula comparando la primera fecha con la última fecha
#    - Fórmula: ((Total_Final - Total_Inicial) / Total_Inicial) * 100
#    - Se muestran los 10 municipios con mayor porcentaje de crecimiento
#
# ============================================================================
