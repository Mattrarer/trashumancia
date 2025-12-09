# Script para Combinar Archivos Excel con Fechas

Este proyecto contiene scripts en R para combinar múltiples archivos Excel que contienen datos del Reporte IDC, agregando una columna con la fecha extraída del nombre del archivo.

## 📋 Requisitos

Instalar los siguientes paquetes de R:

```r
install.packages("readxl")
install.packages("dplyr")
install.packages("tidyr")
install.packages("stringr")
install.packages("writexl")  # Opcional, para guardar en Excel
```

## 📁 Estructura de Archivos Esperada

Tus archivos Excel deben tener la fecha en el nombre en formato **dd-mm-aaaa**. Por ejemplo:

- `Reporte_08-03-2025.xlsx`
- `Reporte_30-11-2025.xlsx`
- `IDC_15-06-2025.xlsx`
- `datos_01-12-2025.xls`

## 🚀 Uso Rápido

### Paso 1: Organiza tus archivos

Coloca todos tus archivos Excel en una carpeta, por ejemplo `./datos_excel/`

### Paso 2: Ejecuta el script

```r
source("ejemplo_uso_simple.R")
```

### Paso 3: Cambia la ruta de la carpeta

En el archivo `ejemplo_uso_simple.R`, modifica la línea:

```r
ruta_carpeta <- "./datos_excel"  # Cambia esto por tu ruta
```

## 📊 Formatos de Salida

### Formato 1: Largo (Recomendado)

Todos los datos apilados verticalmente con una columna `Fecha`:

| Código | Departamento | Municipio | Sistematizado | Papel | Total | Fecha |
|--------|-------------|-----------|---------------|-------|-------|------------|
| 01001 | ANTIOQUIA | MEDELLIN | 36102 | 197 | 36299 | 08-03-2025 |
| 01004 | ANTIOQUIA | ABEJORRAL | 96 | 16 | 112 | 08-03-2025 |
| 01001 | ANTIOQUIA | MEDELLIN | 37000 | 200 | 37200 | 30-11-2025 |
| 01004 | ANTIOQUIA | ABEJORRAL | 100 | 18 | 118 | 30-11-2025 |

**Archivo generado:** `resultado_combinado.xlsx`

### Formato 2: Ancho (Por Totales)

Cada fecha como columna separada con los totales:

| Código | Departamento | Municipio | Total_08-03-2025 | Total_30-11-2025 |
|--------|-------------|-----------|------------------|------------------|
| 01001 | ANTIOQUIA | MEDELLIN | 36299 | 37200 |
| 01004 | ANTIOQUIA | ABEJORRAL | 112 | 118 |

**Archivo generado:** `resultado_formato_ancho.xlsx`

### Formato 3: Ancho Completo

Todas las columnas (Sistematizado, Papel, Total) por fecha:

| Código | Municipio | Sistematizado_08-03-2025 | Papel_08-03-2025 | Total_08-03-2025 | Sistematizado_30-11-2025 | ... |
|--------|-----------|-------------------------|------------------|------------------|-------------------------|-----|
| 01001 | MEDELLIN | 36102 | 197 | 36299 | 37000 | ... |

**Archivo generado:** `resultado_formato_ancho_completo.xlsx`

## 💡 Ejemplos de Uso

### Ejemplo 1: Uso Básico

```r
library(readxl)
library(dplyr)
library(stringr)

# Cargar función
source("merge_excel_files.R")

# Combinar archivos
datos <- combinar_exceles_con_fechas("./mis_datos")

# Guardar resultado
write.csv(datos, "resultado.csv", row.names = FALSE)
```

### Ejemplo 2: Formato Ancho

```r
source("merge_excel_files.R")

# Combinar en formato ancho
datos_ancho <- combinar_exceles_formato_ancho("./mis_datos")

# Guardar
write.csv(datos_ancho, "resultado_ancho.csv", row.names = FALSE)
```

### Ejemplo 3: Filtrar por Municipio

```r
# Después de combinar
datos <- combinar_exceles_con_fechas("./mis_datos")

# Filtrar solo Medellín
medellin <- datos %>%
  filter(Municipio == "MEDELLIN")

# Ver evolución en el tiempo
library(ggplot2)
ggplot(medellin, aes(x = Fecha, y = Total)) +
  geom_line() +
  theme_minimal() +
  labs(title = "Evolución Total - Medellín")
```

## 🔧 Personalización

### Cambiar el Patrón de Fecha

Si tus archivos tienen un formato diferente, modifica el patrón regex:

```r
# Para formato aaaa-mm-dd
combinar_exceles_con_fechas("./datos", patron_fecha = "\\d{4}-\\d{2}-\\d{2}")

# Para formato mm/dd/aaaa (escapar la barra)
combinar_exceles_con_fechas("./datos", patron_fecha = "\\d{2}/\\d{2}/\\d{4}")
```

## ❓ Solución de Problemas

### Error: "No se encontraron archivos Excel"

- Verifica que la ruta sea correcta
- Asegúrate de que los archivos tengan extensión `.xlsx` o `.xls`

### Warning: "No se pudo extraer la fecha"

- Verifica que el nombre del archivo contenga la fecha en formato `dd-mm-aaaa`
- Ejemplo válido: `Reporte_08-03-2025.xlsx`
- Ejemplo inválido: `Reporte_marzo_2025.xlsx`

### Los datos no se combinan correctamente

- Verifica que todos los Excel tengan las mismas columnas
- Revisa que los nombres de columnas sean exactamente iguales

## 📝 Archivos Incluidos

- `merge_excel_files.R`: Funciones principales reutilizables
- `ejemplo_uso_simple.R`: Script simple listo para usar
- `README.md`: Este archivo de documentación

## 👤 Autor

Script creado para combinar reportes IDC de múltiples fechas.

## 📅 Fecha

9 de diciembre de 2025
