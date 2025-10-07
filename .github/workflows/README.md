# GitHub Actions for Version Management

Este directorio contiene los workflows de GitHub Actions para gestión automática de versiones.

## Workflows Disponibles

### 1. version-bump.yml (Recomendado)
**Semantic Versioning Automático**

- **Trigger**: Push a main o merge de PR
- **Funcionalidad**: 
  - Analiza mensajes de commit para determinar el tipo de cambio
  - Genera automáticamente nuevas versiones siguiendo semver
  - Crea tags automáticamente
  - Actualiza el archivo VERSION
  - Crea releases en GitHub

**Convenciones de commit:**
- `feat: nueva funcionalidad` → incrementa MINOR
- `fix: corrección` → incrementa PATCH  
- `feat!: cambio breaking` → incrementa MAJOR
- Cualquier commit con `BREAKING CHANGE` → incrementa MAJOR

### 2. simple-version.yml
**Versionado Simple por Fecha**

- **Trigger**: Push a main
- **Funcionalidad**:
  - Genera versiones basadas en fecha (YYYY.MM.BUILD_NUMBER)
  - Actualiza automáticamente el archivo VERSION
  - Más simple pero menos semántico

## Uso

### Para usar semantic versioning (recomendado):
1. Activa `version-bump.yml`
2. Usa mensajes de commit descriptivos:
   ```bash
   git commit -m "feat: add new language support"
   git commit -m "fix: resolve installation error"
   git commit -m "feat!: change API structure"
   ```

### Para usar versionado simple:
1. Activa `simple-version.yml` 
2. Cada push a main generará una nueva versión automáticamente

## Configuración

Los workflows están listos para usar. Solo necesitas:
1. Activar el workflow que prefieras (o ambos si quieres probar)
2. Hacer push a la rama main
3. El workflow automáticamente:
   - Actualizará el archivo VERSION
   - Creará tags (en caso de semantic versioning)
   - Hará commit de los cambios

## Archivo VERSION

El archivo `VERSION` en la raíz del proyecto será mantenido automáticamente por los workflows. La función `get_version()` en `install.sh` lee este archivo para mostrar la versión correcta.