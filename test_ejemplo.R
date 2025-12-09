# ============================================================================
# SCRIPT DE PRUEBA - Genera datos de ejemplo y prueba la combinación
# ============================================================================

library(writexl)
library(readxl)
library(dplyr)
library(tidyr)
library(stringr)

# Crear carpeta de prueba si no existe
dir.create("datos_ejemplo", showWarnings = FALSE)

# ============================================================================
# PASO 1: Crear archivos Excel de ejemplo
# ============================================================================

# Datos base (municipios de Antioquia)
municipios <- data.frame(
  Codigo = c("01001", "01004", "01007", "01010", "01013", "01016", "01019", "01022"),
  Departamento = rep("ANTIOQUIA", 8),
  Municipio = c("MEDELLIN", "ABEJORRAL", "ABRIAQUI", "ALEJANDRIA",
                "AMAGA", "AMALFI", "ANDES", "ANGELOPOLIS")
)

# Fecha 1: 08-03-2025
set.seed(123)
datos1 <- municipios %>%
  mutate(
    Sistematizado = sample(50:500, 8),
    Papel = sample(0:50, 8),
    Total = Sistematizado + Papel
  )

write_xlsx(datos1, "datos_ejemplo/Reporte_08-03-2025.xlsx")
cat("✓ Creado: Reporte_08-03-2025.xlsx\n")

# Fecha 2: 15-06-2025
set.seed(456)
datos2 <- municipios %>%
  mutate(
    Sistematizado = sample(60:550, 8),
    Papel = sample(5:55, 8),
    Total = Sistematizado + Papel
  )

write_xlsx(datos2, "datos_ejemplo/Reporte_15-06-2025.xlsx")
cat("✓ Creado: Reporte_15-06-2025.xlsx\n")

# Fecha 3: 30-11-2025
set.seed(789)
datos3 <- municipios %>%
  mutate(
    Sistematizado = sample(70:600, 8),
    Papel = sample(10:60, 8),
    Total = Sistematizado + Papel
  )

write_xlsx(datos3, "datos_ejemplo/IDC_30-11-2025.xlsx")
cat("✓ Creado: IDC_30-11-2025.xlsx\n")

cat("\n")
cat("=" %R% 70 %R% "\n")
cat("ARCHIVOS DE EJEMPLO CREADOS EN ./datos_ejemplo/\n")
cat("=" %R% 70 %R% "\n\n")

# ============================================================================
# PASO 2: Combinar los archivos (FORMATO LARGO)
# ============================================================================

archivos <- list.files(
  path = "datos_ejemplo",
  pattern = "\\.(xlsx|xls)$",
  full.names = TRUE,
  ignore.case = TRUE
)

lista_datos <- list()

for (archivo in archivos) {
  nombre <- basename(archivo)
  fecha <- str_extract(nombre, "\\d{2}-\\d{2}-\\d{4}")

  datos <- read_excel(archivo)
  datos$Fecha <- fecha

  lista_datos[[nombre]] <- datos
  cat("Procesado:", nombre, "-> Fecha:", fecha, "\n")
}

# Combinar
datos_combinados <- bind_rows(lista_datos)

cat("\n✓ Datos combinados exitosamente!\n")
cat("  Total filas:", nrow(datos_combinados), "\n")
cat("  Fechas únicas:", length(unique(datos_combinados$Fecha)), "\n\n")

# Mostrar muestra
cat("MUESTRA DE DATOS (Formato Largo):\n")
print(head(datos_combinados, 10))

# Guardar
write_xlsx(datos_combinados, "resultado_largo_ejemplo.xlsx")
cat("\n✓ Guardado: resultado_largo_ejemplo.xlsx\n\n")

# ============================================================================
# PASO 3: Convertir a FORMATO ANCHO
# ============================================================================

datos_ancho <- datos_combinados %>%
  select(Codigo, Departamento, Municipio, Total, Fecha) %>%
  pivot_wider(
    names_from = Fecha,
    values_from = Total,
    names_prefix = "Total_"
  )

cat("DATOS EN FORMATO ANCHO (cada fecha = columna):\n")
print(datos_ancho)

# Guardar
write_xlsx(datos_ancho, "resultado_ancho_ejemplo.xlsx")
cat("\n✓ Guardado: resultado_ancho_ejemplo.xlsx\n\n")

# ============================================================================
# PASO 4: ANÁLISIS SIMPLE
# ============================================================================

cat("=" %R% 70 %R% "\n")
cat("ANÁLISIS RÁPIDO\n")
cat("=" %R% 70 %R% "\n\n")

# Resumen por fecha
resumen_fecha <- datos_combinados %>%
  group_by(Fecha) %>%
  summarise(
    Total_Sistematizado = sum(Sistematizado, na.rm = TRUE),
    Total_Papel = sum(Papel, na.rm = TRUE),
    Total_General = sum(Total, na.rm = TRUE)
  ) %>%
  arrange(Fecha)

cat("Resumen por Fecha:\n")
print(resumen_fecha)

# Municipio con mayor total
mayor_total <- datos_combinados %>%
  group_by(Municipio) %>%
  summarise(Total_Acumulado = sum(Total, na.rm = TRUE)) %>%
  arrange(desc(Total_Acumulado)) %>%
  head(3)

cat("\n\nTop 3 Municipios (Total Acumulado):\n")
print(mayor_total)

cat("\n\n")
cat("=" %R% 70 %R% "\n")
cat("✓ PRUEBA COMPLETADA EXITOSAMENTE\n")
cat("=" %R% 70 %R% "\n")
cat("\nRevisa los archivos generados:\n")
cat("  - resultado_largo_ejemplo.xlsx\n")
cat("  - resultado_ancho_ejemplo.xlsx\n")
