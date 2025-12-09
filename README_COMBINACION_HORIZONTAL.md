# Combinación Horizontal de Columnas "Total" desde Múltiples Archivos Excel

## 📋 Descripción del Problema Resuelto

Este script soluciona el problema de combinar reportes Excel donde:

- ✅ **La fila 1 es el título del documento** (se ignora automáticamente)
- ✅ **La fila 2 contiene los nombres reales de las columnas**
- ✅ **Solo necesitas agregar la columna "Total" de cada archivo**
- ✅ **Las filas NO deben duplicarse** (solo se agregan columnas horizontalmente)
- ✅ **Cada columna "Total" se renombra como "total al día [fecha]"**

## 🎯 Resultado Esperado

### ANTES (múltiples archivos):

**Archivo 1: Reporte_08-03-2025.xlsx**
```
Fila 1: REPORTE IDC DESDE EL 08-03-2025 AL 02-06-2025
Fila 2: Código | Departamento | Municipio | Total
Fila 3: 01001  | ANTIOQUIA    | MEDELLIN  | 1051
Fila 4: 01004  | ANTIOQUIA    | ABELORRAL | 17
```

**Archivo 2: Reporte_30-11-2025.xlsx**
```
Fila 1: REPORTE IDC DESDE EL 08-03-2025 AL 30-11-2025
Fila 2: Código | Departamento | Municipio | Total
Fila 3: 01001  | ANTIOQUIA    | MEDELLIN  | 1200
Fila 4: 01004  | ANTIOQUIA    | ABELORRAL | 25
```

### DESPUÉS (archivo combinado):

```
Código | Departamento | Municipio | total al día 08-03-2025 | total al día 30-11-2025
01001  | ANTIOQUIA    | MEDELLIN  | 1051                    | 1200
01004  | ANTIOQUIA    | ABELORRAL | 17                      | 25
```

**Nota:** Las filas NO aumentan, solo se agregan columnas a la derecha.

## 📦 Instalación

### 1. Instalar R y RStudio

Si no tienes R instalado:
- Descargar R: https://cran.r-project.org/
- Descargar RStudio: https://posit.co/download/rstudio-desktop/

### 2. Instalar paquetes necesarios

Abre RStudio y ejecuta:

```r
install.packages("readxl")
install.packages("dplyr")
install.packages("stringr")
install.packages("writexl")
```

## 🚀 Uso Rápido

### Opción 1: Script Simple (Recomendado para principiantes)

1. **Abre el archivo `ejecutar_combinacion.R`**

2. **Cambia solo esta línea:**
   ```r
   ruta_carpeta <- "./datos_excel"  # <-- Cambia esto a tu carpeta
   ```

   Por ejemplo:
   ```r
   ruta_carpeta <- "C:/Users/TuUsuario/Documentos/Reportes"
   ```

3. **Ejecuta todo el script** (Ctrl + A y luego Ctrl + Enter en RStudio)

4. **¡Listo!** El archivo combinado se guardará como `totales_combinados.xlsx` en la misma carpeta.

### Opción 2: Uso Avanzado con Función

```r
# Cargar el script
source("combinar_totales_horizontal.R")

# Ejecutar con configuración personalizada
resultado <- combinar_totales_horizontal(
  ruta_carpeta = "C:/Users/TuUsuario/Documentos/Reportes",
  patron_fecha = "\\d{2}-\\d{2}-\\d{4}",
  archivo_salida = "mi_resultado_personalizado.xlsx"
)

# Ver resultado
print(resultado)
View(resultado)
```

## 📁 Estructura de Archivos Esperada

### Nombres de Archivos

Los archivos deben tener la fecha en el nombre en formato `dd-mm-aaaa`:

✅ Correcto:
- `Reporte_08-03-2025.xlsx`
- `datos_30-11-2025.xlsx`
- `IDC_15-06-2025.xls`

❌ Incorrecto:
- `Reporte_2025-03-08.xlsx` (formato yyyy-mm-dd)
- `datos_marzo_2025.xlsx` (sin fecha numérica)
- `archivo_sin_fecha.xlsx` (sin fecha)

### Estructura Dentro de Cada Archivo Excel

```
Fila 1: [TÍTULO DEL DOCUMENTO - SE IGNORA]
Fila 2: Código | Departamento | Municipio | Sistematizado | Papel | Total | ...
Fila 3: 01001  | ANTIOQUIA    | MEDELLIN  | 0             | 1051  | 1051  | ...
Fila 4: 01004  | ANTIOQUIA    | ABELORRAL | 17            | 0     | 17    | ...
...
```

**Columnas requeridas:**
- `Código` (o `Codigo`): Identificador único
- `Departamento`: Nombre del departamento
- `Municipio`: Nombre del municipio
- `Total`: Valor a combinar

## 🔧 Parámetros de Configuración

| Parámetro        | Descripción                                      | Valor por defecto              |
|------------------|--------------------------------------------------|--------------------------------|
| `ruta_carpeta`   | Ruta a la carpeta con los archivos Excel        | `"./datos_excel"`              |
| `patron_fecha`   | Expresión regular para extraer la fecha         | `"\\d{2}-\\d{2}-\\d{4}"`       |
| `archivo_salida` | Nombre del archivo de resultado                 | `"totales_combinados.xlsx"`    |

## ❓ Preguntas Frecuentes

### ¿Qué pasa si un archivo tiene un código que no está en otros?

El script usa `left_join`, lo que significa que:
- **Se mantienen todos los códigos del primer archivo**
- Si un código no aparece en archivos posteriores, se pone `NA` en esa celda

### ¿Qué pasa si los archivos no están en orden cronológico?

El script **automáticamente ordena los archivos por fecha** antes de procesarlos.

### ¿Puedo cambiar el formato de fecha?

Sí, cambia el parámetro `patron_fecha`. Ejemplos:

```r
# Para formato dd/mm/yyyy
patron_fecha = "\\d{2}/\\d{2}/\\d{4}"

# Para formato yyyy-mm-dd
patron_fecha = "\\d{4}-\\d{2}-\\d{2}"

# Para formato ddmmyyyy
patron_fecha = "\\d{8}"
```

### ¿El script también guarda en CSV?

Sí, automáticamente guarda dos versiones:
- `totales_combinados.xlsx` (Excel)
- `totales_combinados.csv` (CSV con codificación UTF-8)

## 🐛 Solución de Problemas

### Error: "No se encontraron archivos Excel"

**Solución:** Verifica que la ruta sea correcta y que haya archivos `.xlsx` o `.xls` en la carpeta.

```r
# Listar archivos para verificar
list.files("C:/tu/ruta/aqui", pattern = "\\.xlsx$")
```

### Error: "No se encontraron las columnas requeridas"

**Solución:** El script buscará automáticamente variaciones como "Codigo", "CÓDIGO", etc. Si el error persiste, verifica que la segunda fila tenga los nombres correctos.

### Advertencia: "El número de filas cambió"

**Solución:** Esto puede pasar si algunos archivos tienen códigos diferentes. Verifica que todos los archivos tengan los mismos códigos en el mismo orden.

## 📊 Ejemplo Completo

```r
# 1. Cargar librerías (si no has ejecutado el script principal)
library(readxl)
library(dplyr)
library(stringr)
library(writexl)

# 2. Cargar el script con las funciones
source("combinar_totales_horizontal.R")

# 3. Definir la carpeta con tus archivos
mi_carpeta <- "C:/Users/MiUsuario/Documentos/Reportes_IDC"

# 4. Ejecutar
resultado <- combinar_totales_horizontal(
  ruta_carpeta = mi_carpeta,
  archivo_salida = "reporte_final_combinado.xlsx"
)

# 5. Ver primeras filas
head(resultado)

# 6. Ver en RStudio
View(resultado)

# 7. Obtener resumen
summary(resultado)
```

## 📝 Archivos Incluidos

- `combinar_totales_horizontal.R` - Script principal con la función
- `ejecutar_combinacion.R` - Script simple listo para ejecutar
- `README_COMBINACION_HORIZONTAL.md` - Esta documentación
- `merge_excel_files.R` - Script antiguo (combinación vertical)
- `ejemplo_uso_simple.R` - Ejemplo antiguo (combinación vertical)

## 🆚 Diferencia con Scripts Anteriores

| Característica                  | Scripts Antiguos | Script Nuevo |
|---------------------------------|------------------|--------------|
| Ignora fila 1 (título)          | ❌ No            | ✅ Sí        |
| Usa fila 2 como encabezados     | ❌ No            | ✅ Sí        |
| Solo agrega columna Total       | ❌ No            | ✅ Sí        |
| Mantiene número de filas        | ❌ No            | ✅ Sí        |
| Renombra como "total al día"    | ❌ No            | ✅ Sí        |
| Combinación horizontal          | ❌ No (vertical) | ✅ Sí        |

## 📧 Soporte

Si encuentras algún problema:
1. Verifica que los archivos tengan la estructura correcta
2. Revisa los mensajes de error en la consola
3. Asegúrate de que todos los paquetes estén instalados

---

**Creado por:** Claude AI
**Fecha:** 2025-12-09
**Versión:** 1.0
