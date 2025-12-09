# ============================================================================
# SCRIPT SIMPLE PARA EJECUTAR LA COMBINACIÓN DE TOTALES
# ============================================================================
# Este es un script simplificado listo para usar.
# Solo necesitas cambiar la ruta de la carpeta y ejecutar.
# ============================================================================

# Cargar el script con las funciones
source("combinar_totales_horizontal.R")

# ============================================================================
# CONFIGURACIÓN - ¡CAMBIA SOLO ESTA LÍNEA!
# ============================================================================

# Ruta a la carpeta que contiene tus archivos Excel
ruta_carpeta <- "./datos_excel"  # <-- CAMBIA ESTO A TU CARPETA

# ============================================================================
# EJECUTAR
# ============================================================================

cat("\n")
cat("╔═══════════════════════════════════════════════════════════════════════╗\n")
cat("║  COMBINACIÓN HORIZONTAL DE COLUMNAS TOTALES                          ║\n")
cat("╚═══════════════════════════════════════════════════════════════════════╝\n")
cat("\n")

# Ejecutar la función
resultado <- combinar_totales_horizontal(
  ruta_carpeta = ruta_carpeta,
  patron_fecha = "\\d{2}-\\d{2}-\\d{4}",
  archivo_salida = "totales_combinados.xlsx"
)

# ============================================================================
# VER RESULTADO
# ============================================================================

cat("\n")
cat("╔═══════════════════════════════════════════════════════════════════════╗\n")
cat("║  VISTA PREVIA DEL RESULTADO                                          ║\n")
cat("╚═══════════════════════════════════════════════════════════════════════╝\n")
cat("\n")

# Mostrar las primeras filas
print(head(resultado, 10))

# Mostrar estructura
cat("\n")
cat("Estructura del resultado:\n")
str(resultado)

# Abrir en visualizador (si estás en RStudio)
if (interactive()) {
  View(resultado)
}

cat("\n")
cat("✓ ¡Proceso completado exitosamente!\n")
cat("\n")
