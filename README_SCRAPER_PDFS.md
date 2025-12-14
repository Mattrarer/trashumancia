# Scraper de PDFs - Registraduría Bucaramanga

Scripts en R para descargar automáticamente los PDFs de resultados electorales de la Registraduría de Bucaramanga.

## 📋 Requisitos

Instalar los siguientes paquetes de R:

```r
install.packages("httr")
install.packages("jsonlite")
install.packages("rvest")
install.packages("dplyr")
install.packages("purrr")
install.packages("stringr")
```

## 📁 Archivos Incluidos

- **`scrapear_pdfs_registraduria.R`** - Script completo con múltiples métodos de scraping
- **`descargar_pdfs_metodo_directo.R`** - Método directo y más simple (RECOMENDADO)
- **`explorar_api_registraduria.R`** - Herramientas para explorar la API
- **`ejemplo_uso_pdfs.R`** - Ejemplos de uso rápido

## 🚀 Uso Rápido (Recomendado)

### Método 1: Capturar URLs desde DevTools (Más Fácil)

Este es el método más confiable:

#### Paso 1: Capturar las URLs

1. Abre la página en tu navegador:
   ```
   https://divulgacione14bucaramanga.registraduria.gov.co/departamento/27
   ```

2. Abre las **DevTools** (presiona `F12`)

3. Ve a la pestaña **Network**

4. Marca la opción **"Preserve log"** ✓

5. En el filtro, escribe: `pdf`

6. En la página, selecciona:
   - **Zona**: Zona 01 (o la que quieras)
   - **Puesto**: 01 - IE MAIPOR (o el que quieras)
   - Haz clic en el botón **"Consultar"**

7. Haz clic en **"Ver"** en cada mesa que aparezca

8. En el Network tab, verás aparecer requests a archivos `.pdf`

9. Haz clic derecho en cada uno → **Copy → Copy URL**

10. Pega todas las URLs en un archivo llamado `urls_pdfs.txt` (una URL por línea)

#### Paso 2: Descargar los PDFs

```r
# Cargar el script
source("descargar_pdfs_metodo_directo.R")

# Importar URLs desde el archivo
urls <- importar_urls_desde_archivo("urls_pdfs.txt")

# Descargar todos los PDFs
resultados <- descargar_lote(urls)
```

¡Listo! Los PDFs se descargarán automáticamente.

---

### Método 2: URLs Directas (Si Ya las Tienes)

Si ya tienes las URLs, simplemente cópialas en el código:

```r
source("descargar_pdfs_metodo_directo.R")

urls <- c(
  "https://divulgacione14bucaramanga.registraduria.gov.co/assets/temis/pdf/27/001/001/01/001/ALC/754c79125074d0e6afb8eb0e63c35a6f196ae806cd840d264b6591b367112e60.pdf?uuid=29c38017-c8fc-40f7-86e1-05b2090a6aab",
  "https://divulgacione14bucaramanga.registraduria.gov.co/assets/temis/pdf/27/001/001/01/002/ALC/xxx.pdf?uuid=yyy"
  # ... más URLs
)

descargar_lote(urls)
```

---

### Método 3: Intentar GraphQL (Automático)

**⚠ Este método puede requerir ajustes** según cómo esté implementada la API:

```r
source("descargar_pdfs_metodo_directo.R")

# Intentar obtener datos de mesas
datos <- obtener_mesas_graphql()

# Si funciona, extraer URLs y descargar
if (!is.null(datos)) {
  # Ajusta según la estructura real de la respuesta
  urls <- datos$data$consultarMesas$urlPdf
  descargar_lote(urls)
}
```

## 📂 Organización de Archivos

Los PDFs descargados se organizan automáticamente en carpetas:

```
pdfs_registraduria/
├── Zona_001/
│   ├── Puesto_01/
│   │   ├── ALC_Mesa_001_xxx.pdf
│   │   ├── ALC_Mesa_002_yyy.pdf
│   │   └── ...
│   ├── Puesto_02/
│   │   └── ...
│   └── ...
└── Zona_002/
    └── ...
```

## 🔧 Funciones Disponibles

### En `descargar_pdfs_metodo_directo.R`:

- **`importar_urls_desde_archivo(archivo)`** - Importa URLs desde un archivo de texto
- **`descargar_pdf(url)`** - Descarga un PDF individual
- **`descargar_lote(urls)`** - Descarga múltiples PDFs con barra de progreso
- **`obtener_mesas_graphql(zona, puesto)`** - Intenta obtener datos vía GraphQL
- **`construir_url_pdf(...)`** - Construye URL manualmente (requiere hash y UUID)

### En `explorar_api_registraduria.R`:

- **`obtener_config_pagina()`** - Extrae configuración del HTML/JavaScript
- **`obtener_zonas()`** - Lista las zonas disponibles
- **`obtener_mesas(zona, puesto)`** - Obtiene mesas de una zona/puesto
- **`analizar_url_pdf(url)`** - Analiza la estructura de una URL
- **`buscar_referencias_pdf()`** - Busca PDFs en el código fuente

## 💡 Ejemplos de Uso

### Ejemplo 1: Descargar PDFs de una Zona Específica

1. Abre el navegador y ve a la página
2. Selecciona Zona 01 y Puesto 01
3. Copia las URLs de todas las mesas
4. Guárdalas en `urls_zona01_puesto01.txt`
5. Ejecuta:

```r
source("descargar_pdfs_metodo_directo.R")
urls <- importar_urls_desde_archivo("urls_zona01_puesto01.txt")
descargar_lote(urls)
```

### Ejemplo 2: Descargar TODAS las Zonas y Puestos

Para descargar todos los PDFs de todas las zonas y puestos:

1. En el DevTools, marca **"Preserve log"**
2. Recorre TODAS las combinaciones de Zona/Puesto
3. Haz clic en "Ver" en todas las mesas
4. Al final, exporta TODAS las URLs capturadas
5. Ejecútalo con el script

### Ejemplo 3: Explorar la Estructura Primero

```r
source("explorar_api_registraduria.R")

# Ver qué zonas hay disponibles
zonas <- obtener_zonas()

# Ver configuración de la página
obtener_config_pagina()

# Buscar referencias a PDFs
buscar_referencias_pdf()

# Analizar una URL de ejemplo
analizar_url_pdf("https://divulgacione14bucaramanga.registraduria.gov.co/assets/temis/pdf/27/001/001/01/001/ALC/xxx.pdf?uuid=yyy")
```

## 🔍 Estructura de las URLs

Las URLs de los PDFs siguen este patrón:

```
https://divulgacione14bucaramanga.registraduria.gov.co/assets/temis/pdf/
  ↓
  27/      ← Departamento (Santander)
  001/     ← Municipio (Bucaramanga)
  001/     ← Zona
  01/      ← Puesto
  001/     ← Mesa
  ALC/     ← Tipo (ALC=Alcalde, CON=Concejo, GOB=Gobernación)
  [hash].pdf?uuid=[uuid]
```

**Importante**: El hash y UUID son únicos para cada mesa y se obtienen de la API o del HTML.

## ⚙️ Configuración Avanzada

### Cambiar la Carpeta de Descarga

```r
CARPETA_DESCARGA <- "./mis_pdfs"
```

### Ajustar el Tiempo de Pausa entre Descargas

```r
# Pausa de 1 segundo (más lento, más seguro)
descargar_lote(urls, pausa = 1.0)

# Pausa de 0.2 segundos (más rápido, puede fallar)
descargar_lote(urls, pausa = 0.2)
```

### Descargar Solo un Tipo de Elección

Filtra las URLs antes de descargar:

```r
# Solo Alcalde (ALC)
urls_alc <- urls[grepl("/ALC/", urls)]
descargar_lote(urls_alc)

# Solo Concejo (CON)
urls_con <- urls[grepl("/CON/", urls)]
descargar_lote(urls_con)
```

## ❓ Solución de Problemas

### No se Descarga Ningún PDF

- **Verifica las URLs**: Asegúrate de que las URLs sean correctas
- **Revisa el archivo**: Verifica que `urls_pdfs.txt` tenga las URLs correctas
- **Internet**: Confirma que tienes conexión a internet
- **Servidor**: Es posible que el servidor esté caído temporalmente

### Error 403 o 401

- El servidor puede estar bloqueando requests automáticos
- Intenta aumentar la pausa entre descargas: `descargar_lote(urls, pausa = 2)`
- Verifica que las cookies/headers sean correctos

### Error 404 (No Encontrado)

- El hash o UUID de la URL es incorrecto
- Verifica que copiaste la URL completa desde DevTools
- La mesa puede no existir

### Se Descargan PDFs Vacíos o Corruptos

- Puede ser un problema con el servidor
- Intenta descargar nuevamente
- Abre el PDF en el navegador para confirmar que existe

## 📊 Estadísticas

El script muestra un resumen al finalizar:

```
📊 RESUMEN:
  Total: 42
  Exitosos: 40
  Nuevos: 35
  Ya existían: 5
  Fallidos: 2
```

## 🤝 Contribuciones

Si encuentras bugs o mejoras, siéntete libre de modificar los scripts.

## 📝 Notas Importantes

1. **Respeta el servidor**: No hagas descargas masivas muy rápidas
2. **Verifica las URLs**: Siempre confirma que las URLs sean válidas
3. **Backup**: Guarda las URLs en un archivo por si necesitas volver a descargar
4. **Legal**: Asegúrate de tener permiso para descargar estos documentos

## 📅 Última Actualización

Diciembre 2025

---

**¿Necesitas ayuda?** Revisa los ejemplos en `ejemplo_uso_pdfs.R` o explora la API con `explorar_api_registraduria.R`
