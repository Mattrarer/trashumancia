# Ejemplo de Uso Rápido - Descargar PDFs de Registraduría
# =========================================================

# Cargar el script principal
source("descargar_pdfs_metodo_directo.R")

# ===============================================
# EJEMPLO 1: DESCARGAR DESDE ARCHIVO DE URLs
# ===============================================

# 1. Crea un archivo llamado "urls_pdfs.txt" con las URLs (una por línea)
# 2. Ejecuta este código:

if (file.exists("urls_pdfs.txt")) {
  cat("Importando URLs desde archivo...\n")
  urls <- importar_urls_desde_archivo("urls_pdfs.txt")

  if (length(urls) > 0) {
    cat("\n¿Descargar", length(urls), "PDFs? (Presiona Enter para continuar, Ctrl+C para cancelar)\n")
    readline()

    # Opción 1: Descarga secuencial (más lenta)
    # resultados <- descargar_lote(urls)

    # Opción 2: ⚡ Descarga paralela (RECOMENDADO - más rápida)
    resultados <- descargar_lote_paralelo(urls)

    # Opción 3: Descarga por chunks (para muchas URLs)
    # resultados <- descargar_lote_por_chunks(urls, chunk_size = 20, num_workers = 4)
  }
} else {
  cat("⚠ No se encontró el archivo urls_pdfs.txt\n")
  cat("Crea el archivo y pega las URLs de los PDFs (una por línea)\n\n")
}

# ===============================================
# EJEMPLO 2: URLs DIRECTAS (COPIAR Y PEGAR)
# ===============================================

# Si ya tienes las URLs, simplemente pégalas aquí:

urls_ejemplo <- c(
  # Pega aquí las URLs de los PDFs del DevTools
  # Una por línea, entre comillas
  # Ejemplo:
  # "https://divulgacione14bucaramanga.registraduria.gov.co/assets/temis/pdf/27/001/001/01/001/ALC/xxx.pdf?uuid=xxx"
)

# Descomentar para ejecutar:
# if (length(urls_ejemplo) > 0) {
#   resultados <- descargar_lote(urls_ejemplo)
# }

# ===============================================
# EJEMPLO 3: EXPLORAR LA API PRIMERO
# ===============================================

# Si quieres entender cómo funciona la API antes de descargar:

# source("explorar_api_registraduria.R")

# # Ver configuración de la página
# obtener_config_pagina()

# # Listar zonas disponibles
# zonas <- obtener_zonas()

# # Buscar referencias a PDFs
# buscar_referencias_pdf()

# ===============================================
# EJEMPLO 4: INTENTAR GRAPHQL
# ===============================================

# # Probar si la API GraphQL funciona
# datos_graphql <- obtener_mesas_graphql()
#
# # Si funciona, extraer URLs
# if (!is.null(datos_graphql)) {
#   # Ajusta según la estructura real de la respuesta
#   urls <- datos_graphql$data$mesas$urlPdf
#   descargar_lote_paralelo(urls)  # ⚡ Usar versión paralela
# }

# ===============================================
# EJEMPLO 5: ⚡ DESCARGA PARALELA AVANZADA
# ===============================================

# # Configurar workers manualmente (ejemplo: 8 workers)
# urls <- importar_urls_desde_archivo("urls_pdfs.txt")
# resultados <- descargar_lote_paralelo(urls, num_workers = 8)

# # Para muchas URLs (>100), usar chunks
# urls <- importar_urls_desde_archivo("urls_pdfs.txt")
# resultados <- descargar_lote_por_chunks(
#   urls,
#   chunk_size = 30,        # Descargar en grupos de 30
#   num_workers = 6,         # 6 workers por chunk
#   pausa_entre_chunks = 2   # 2 segundos entre chunks
# )

# # Comparación de velocidad
# urls <- importar_urls_desde_archivo("urls_pdfs.txt")
#
# # Método lento (secuencial)
# cat("Descarga secuencial:\n")
# system.time({
#   descargar_lote(urls[1:10], pausa = 0.1)
# })
#
# # Método rápido (paralelo)
# cat("\nDescarga paralela:\n")
# system.time({
#   descargar_lote_paralelo(urls[1:10])
# })

# ===============================================
# NOTAS IMPORTANTES
# ===============================================

cat("\n📝 NOTAS:\n")
cat("• Los PDFs se guardan en:", CARPETA_DESCARGA, "\n")
cat("• Se organizan en carpetas por Zona y Puesto\n")
cat("• Si un PDF ya existe, se saltea automáticamente\n")
cat("• ⚡ NUEVO: Descarga paralela es 5-10x más rápida\n")
cat("• Usa descargar_lote_paralelo() para máxima velocidad\n\n")
