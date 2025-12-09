# ============================================================================
# SCRIPT SIMPLE PARA COMBINAR ARCHIVOS EXCEL CON FECHAS
# ============================================================================

# 1. Instalar paquetes (ejecutar solo la primera vez)
# install.packages("readxl")
# install.packages("dplyr")
# install.packages("tidyr")
# install.packages("stringr")

# 2. Cargar librerías
library(readxl)
library(dplyr)
library(tidyr)
library(stringr)

# 3. CONFIGURACIÓN - Cambia esta ruta a tu carpeta con los archivos Excel
ruta_carpeta <- "./datos_excel"  # Cambia esto por tu ruta

# ============================================================================
# OPCIÓN 1: FORMATO LARGO (Recomendado)
# Todos los datos apilados verticalmente con columna de Fecha
# ============================================================================

# Obtener lista de archivos Excel
archivos <- list.files(
  path = ruta_carpeta,
  pattern = "\\.(xlsx|xls)$",
  full.names = TRUE,
  ignore.case = TRUE
)

# Lista para guardar los datos
lista_datos <- list()

# Procesar cada archivo
for (archivo in archivos) {

  # Obtener nombre del archivo
  nombre <- basename(archivo)
  print(paste("Leyendo:", nombre))

  # Extraer fecha del nombre (formato dd-mm-aaaa)
  fecha <- str_extract(nombre, "\\d{2}-\\d{2}-\\d{4}")

  # Leer Excel
  datos <- read_excel(archivo)

  # Agregar columna de fecha
  datos$Fecha <- fecha

  # Guardar en lista
  lista_datos[[nombre]] <- datos
}

# Combinar todos los dataframes
datos_combinados <- bind_rows(lista_datos)

# Ver resultado
print(datos_combinados)

# Guardar resultado
write.csv(datos_combinados, "resultado_combinado.csv", row.names = FALSE)
library(writexl)
write_xlsx(datos_combinados, "resultado_combinado.xlsx")


# ============================================================================
# OPCIÓN 2: FORMATO ANCHO
# Cada fecha como columna separada (Total_08-03-2025, Total_30-11-2025, etc.)
# ============================================================================

datos_ancho <- datos_combinados %>%
  select(Codigo, Departamento, Municipio, Total, Fecha) %>%
  pivot_wider(
    names_from = Fecha,
    values_from = Total,
    names_prefix = "Total_",
    values_fill = 0  # Rellena con 0 si falta algún valor
  )

# Ver resultado
print(datos_ancho)

# Guardar resultado
write.csv(datos_ancho, "resultado_formato_ancho.csv", row.names = FALSE)
library(writexl)
write_xlsx(datos_ancho, "resultado_formato_ancho.xlsx")


# ============================================================================
# OPCIÓN 3: MANTENER TODAS LAS COLUMNAS EN FORMATO ANCHO
# ============================================================================

datos_ancho_completo <- datos_combinados %>%
  pivot_wider(
    names_from = Fecha,
    values_from = c(Sistematizado, Papel, Total),
    names_glue = "{.value}_{Fecha}"
  )

# Ver resultado
print(datos_ancho_completo)

# Guardar resultado
write.csv(datos_ancho_completo, "resultado_formato_ancho_completo.csv", row.names = FALSE)
library(writexl)
write_xlsx(datos_ancho_completo, "resultado_formato_ancho_completo.xlsx")
