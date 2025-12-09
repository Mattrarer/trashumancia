# Script para combinar múltiples archivos Excel con fechas
# Autor: Claude
# Fecha: 2025-12-09

# Cargar librerías necesarias
library(readxl)
library(dplyr)
library(tidyr)
library(stringr)

# ============================================================================
# FUNCIÓN PRINCIPAL: Combinar archivos Excel con fechas
# ============================================================================

combinar_exceles_con_fechas <- function(ruta_carpeta, patron_fecha = "\\d{2}-\\d{2}-\\d{4}") {

  # Listar todos los archivos Excel en la carpeta
  archivos <- list.files(
    path = ruta_carpeta,
    pattern = "\\.(xlsx|xls)$",
    full.names = TRUE,
    ignore.case = TRUE
  )

  if (length(archivos) == 0) {
    stop("No se encontraron archivos Excel en la carpeta especificada.")
  }

  cat("Se encontraron", length(archivos), "archivos Excel\n")

  # Lista para almacenar los dataframes
  lista_datos <- list()

  # Procesar cada archivo
  for (archivo in archivos) {

    nombre_archivo <- basename(archivo)
    cat("Procesando:", nombre_archivo, "\n")

    # Extraer la fecha del nombre del archivo
    fecha_extraida <- str_extract(nombre_archivo, patron_fecha)

    if (is.na(fecha_extraida)) {
      warning(paste("No se pudo extraer la fecha del archivo:", nombre_archivo))
      next
    }

    # Leer el archivo Excel
    tryCatch({
      datos <- read_excel(archivo)

      # Agregar columna de fecha
      datos$Fecha <- fecha_extraida

      # Agregar a la lista
      lista_datos[[nombre_archivo]] <- datos

    }, error = function(e) {
      warning(paste("Error al leer el archivo:", nombre_archivo, "-", e$message))
    })
  }

  # Combinar todos los dataframes
  if (length(lista_datos) > 0) {
    datos_combinados <- bind_rows(lista_datos)
    cat("\nDatos combinados exitosamente!\n")
    cat("Total de filas:", nrow(datos_combinados), "\n")
    cat("Total de columnas:", ncol(datos_combinados), "\n")
    return(datos_combinados)
  } else {
    stop("No se pudo procesar ningún archivo.")
  }
}

# ============================================================================
# FUNCIÓN ALTERNATIVA: Si quieres formato de tabla ancha (wide format)
# ============================================================================

combinar_exceles_formato_ancho <- function(ruta_carpeta, patron_fecha = "\\d{2}-\\d{2}-\\d{4}") {

  # Primero obtener los datos en formato largo
  datos_largos <- combinar_exceles_con_fechas(ruta_carpeta, patron_fecha)

  # Convertir a formato ancho pivoteando por fecha
  # Esto creará una columna para cada fecha con los valores de "Total"
  datos_anchos <- datos_largos %>%
    select(Codigo, Departamento, Municipio, Total, Fecha) %>%
    pivot_wider(
      names_from = Fecha,
      values_from = Total,
      names_prefix = "Total_"
    )

  return(datos_anchos)
}

# ============================================================================
# EJEMPLO DE USO
# ============================================================================

# USO 1: Formato largo (todas las fechas en una columna)
# Este formato apila todos los datos verticalmente con una columna "Fecha"
#
# datos_combinados <- combinar_exceles_con_fechas("./datos")
# write.csv(datos_combinados, "datos_combinados_largo.csv", row.names = FALSE)

# USO 2: Formato ancho (cada fecha como columna separada)
# Este formato crea una columna para cada fecha con los totales
#
# datos_combinados_ancho <- combinar_exceles_formato_ancho("./datos")
# write.csv(datos_combinados_ancho, "datos_combinados_ancho.csv", row.names = FALSE)

# ============================================================================
# EJEMPLOS ESPECÍFICOS DE NOMBRES DE ARCHIVOS
# ============================================================================

# Si tus archivos se llaman por ejemplo:
# - "Reporte_08-03-2025.xlsx"
# - "Reporte_30-11-2025.xlsx"
# - "datos_15-06-2025.xlsx"
#
# El script automáticamente extraerá: "08-03-2025", "30-11-2025", "15-06-2025"

# ============================================================================
# NOTAS IMPORTANTES
# ============================================================================
#
# 1. El patrón de fecha por defecto busca dd-mm-aaaa en el nombre del archivo
# 2. Si tus archivos tienen un formato diferente, ajusta el patrón regex
# 3. Asegúrate de que todos los Excel tengan la misma estructura de columnas
# 4. El script maneja errores y salta archivos que no se pueden leer
