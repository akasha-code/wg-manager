# WireGuard Manager (TUI)

**[🇺🇸 English](README.md) | 🇪🇸 Español**

WireGuard Admin es un asistente TUI interactivo diseñado para simplificar la gestión
diaria de un servidor VPN WireGuard autoalojado. Envuelve las herramientas `wg` con
un menú potenciado por `fzf` para que puedas configurar el servidor, agregar peers
e inspeccionar el estado sin memorizar comandos largos. El proyecto incluye prompts
bilingües (EN/ES), asistentes guiados de primera ejecución y valores predeterminados
sensatos para que puedas ir de cero a una VPN utilizable en minutos.

## Características

- 🚀 **Configuración inicial guiada** – elige entre valores predeterminados rápidos,
  un flujo de prompts simples, o un asistente guiado exhaustivo que explica cada configuración.
- 📂 **Gestión de configuración** – llena automáticamente un archivo `.env` y almacena
  archivos de cliente bajo `~/wireguard-files` (personalizable).
- 👥 **Provisión de peers** – crea perfiles de cliente con códigos QR y modos de
  enrutamiento seleccionables usando `create-client.sh` o desde el menú principal.
- 🔁 **Ayudantes de servicio** – reinicia WireGuard, valida configuración y revisa
  logs desde dentro del menú.
- 🌐 **Soporte multi-idioma** – localización en inglés y español con reinicio
  automático de aplicación al cambiar idiomas para una experiencia fluida.
- 🚪 **Interfaz amigable** – sistema de menús intuitivo con opciones de salida claras
  y proceso de instalación optimizado.

## Requisitos

- Un host GNU/Linux con WireGuard ya instalado y mínimamente configurado.
- `bash`, `wg`, `qrencode`, `fzf` y `wireguard-tools` disponibles en `$PATH`.
- Permisos `sudo` para acciones que toquen `/etc/wireguard` o reinicien servicios.

## Instalación

### 1. Clona el repositorio

```bash
git clone https://github.com/akasha-code/wg-manager.git
cd wg-manager
```

### 2. Ejecuta el instalador

El instalador detecta automáticamente tu distribución, instala los paquetes requeridos,
y prepara un archivo `.env` con una experiencia de instalación limpia y profesional.

```bash
./install.sh
```

> **💡 Consejo**: Si obtienes un error "Permission denied", haz el script ejecutable primero:
> ```bash
> chmod +x install.sh
> ./install.sh
> ```
> Alternativamente, puedes ejecutarlo directamente con: `bash install.sh`

Durante la instalación podrás:
- Seleccionar tu idioma preferido (Inglés/Español)
- Elegir un modo de configuración inicial (valores predeterminados, prompts simples, o asistente detallado)
- Tener el comando `wg-manager` automáticamente registrado en tu sistema

El instalador proporciona respaldos inteligentes, intentando instalación a nivel de sistema
primero, luego respaldando a instalación de usuario local si es necesario.

> **Nota**: El script trata de detectar tu distribución e instalar paquetes vía
> `apt`, `pacman`, `dnf` o `zypper`. Si tu distribución no es soportada necesitarás
> instalar `fzf`, `qrencode` y `wireguard-tools` manualmente antes de ejecutar
> el script nuevamente.

### Instalación manual (opcional)

Si prefieres una configuración manual:

1. Copia `.env.example` a `.env` y edita los valores para que coincidan con tu servidor.
2. Asegúrate de que los comandos requeridos (`wg`, `qrencode`, `fzf`) estén disponibles.
3. Exporta `WG_HOME` al directorio del proyecto y ejecuta `./wg-manager`.
4. Opcionalmente, crea un enlace simbólico del script en algún lugar de tu `$PATH` como `wg-manager`.

## Uso

Lanza la interfaz con:

```bash
wg-manager
```

Las operaciones clave disponibles desde el menú incluyen:

- **Crear peers**: genera llaves, archivos de configuración y códigos QR. Puedes
  elegir entre túnel completo, túnel dividido o enrutamiento personalizado.
- **Editar configuraciones**: abre `.env` en tu `$EDITOR` para ajustar valores predeterminados
  como servidores DNS, keepalive o la red base.
- **Cambiar idioma**: cambia entre inglés y español con reinicio automático
  de aplicación para aplicar el nuevo idioma inmediatamente.
- **Controles de servicio**: reinicia `wg-quick@<interface>` o valida la
  configuración actual de WireGuard.
- **Salir de aplicación**: opción de salida limpia disponible directamente desde el menú principal
  (además del soporte de tecla ESC).
- **Re-ejecutar asistente**: inicia el asistente de configuración detallado en cualquier momento con
  `wg-manager --wizard`.

Los artefactos de cliente generados se almacenan bajo `~/wireguard-files/<peer-name>/` por
defecto. Cada directorio contiene la configuración del cliente (`.conf`) y un código QR
(`.png`) que puede ser escaneado desde dispositivos móviles.

## Mejoras Recientes

- **Experiencia de usuario mejorada**: Instalación optimizada con salida de debug reducida
  para un proceso de configuración más limpio y profesional.
- **Internacionalización completa**: Todos los mensajes de cara al usuario ahora soportan
  tanto inglés como español.
- **Cambio de idioma inteligente**: Reinicio automático de aplicación al cambiar
  idiomas con confirmación de usuario para asegurar transiciones de idioma fluidas.
- **Navegación mejorada**: Agregada opción de salida clara al menú principal para mejor
  experiencia de usuario y facilidad de descubrimiento.
- **Versionado automatizado**: GitHub Actions gestiona automáticamente números de versión
  basados en mensajes de commit, eliminando la gestión manual de versiones.

## Créditos y apoyo

WireGuard Admin es mantenido por Guido Nicolás Quadrini. Puedes encontrar un
agradecimiento completo a todas las personas y proyectos que colaboraron en
[CREDITS.md](CREDITS.md).

¿Te resulta útil esta herramienta? Considera invitarme un café en
[Buy Me a Coffee](https://buymeacoffee.com/matekraft) para apoyar su
desarrollo continuo.