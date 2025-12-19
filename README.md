# 🚀 Dotfiles - Configuración Optimizada para Fedora

[![Fedora](https://img.shields.io/badge/Fedora-294172?style=for-the-badge&logo=fedora&logoColor=white)](https://getfedora.org/)
[![Zsh](https://img.shields.io/badge/Zsh-F15A24?style=for-the-badge&logo=gnu-bash&logoColor=white)](https://www.zsh.org/)
[![License](https://img.shields.io/badge/License-MIT-green.svg?style=for-the-badge)](LICENSE)

Configuración de terminal optimizada para máximo rendimiento y productividad.

## ⚡ Características

- **Tiempo de carga <100ms** - Lazy loading y caché optimizado
- **Powerlevel10k** - Prompt hermoso e informativo
- **40+ aliases** - Comandos frecuentes simplificados
- **20+ funciones** - Utilidades para desarrollo
- **Instalación automática** - Un comando para configurar todo

## 📦 Incluye

| Categoría | Herramientas |
|-----------|-------------|
| 🐚 Shell | Zsh, Oh-My-Zsh, Powerlevel10k |
| 📝 Editor | VSCode, Cursor |
| 🔍 Búsqueda | FZF, Ripgrep, fd-find |
| 📁 Archivos | lsd, bat, eza, colorls |
| 🐳 Containers | Docker, Docker Compose |
| 🌐 Browser | Brave |
| 📦 Node | NVM, Node LTS, PNPM |
| 🐍 Python | Miniconda |
| 🔧 Utils | lazygit, btop, zoxide, tldr |

## 🚀 Instalación Rápida

```bash
git clone https://github.com/nahuelrosas/dotfiles.git ~/dotfiles
cd ~/dotfiles
./install.sh
```

O con Make:
```bash
make install
```

## 📋 Requisitos

- **SO:** Fedora 38+ (probado en Fedora 41)
- **RAM:** 4GB mínimo
- **Internet:** Requerido para instalación

## 🔧 Comandos Make

```bash
make install    # Instalación completa
make backup     # Backup de configs actuales
make update     # Actualizar herramientas
make uninstall  # Revertir cambios
make help       # Ver todos los comandos
```

## 📁 Estructura

```
dotfiles/
├── zsh/              # Configuración Zsh modular
│   ├── .zshrc        # Config principal
│   ├── .zshenv       # Variables de entorno
│   ├── aliases.zsh   # Aliases
│   └── functions.zsh # Funciones útiles
├── kitty/            # Configuración terminal Kitty
├── git/              # Configuración Git
├── scripts/          # Scripts de instalación
└── config/           # Otras configuraciones
```

## ⌨️ Aliases Principales

| Alias | Comando | Descripción |
|-------|---------|-------------|
| `ll` | `lsd -lh` | Lista detallada |
| `cat` | `bat` | Cat con syntax highlighting |
| `lg` | `lazygit` | Git TUI |
| `top` | `btop` | Monitor de sistema |
| `..` | `cd ..` | Subir directorio |
| `gs` | `git status` | Estado de git |

## 🛠️ Funciones Útiles

| Función | Descripción |
|---------|-------------|
| `extract <file>` | Extrae cualquier archivo comprimido |
| `mkcd <dir>` | Crea directorio y entra |
| `ff` | Búsqueda interactiva de archivos |
| `fgrep <term>` | Búsqueda en contenido de archivos |
| `gcob` | Checkout interactivo de branches |
| `dshell` | Shell en contenedor Docker |
| `fkill` | Matar proceso interactivamente |
| `sysinfo` | Información del sistema |

## 🎨 Personalización

### Cambiar tema de Kitty
Edita `kitty/kitty.conf` y cambia la línea:
```conf
include dracula.conf
# Por ejemplo: include tokyo-night.conf
```

### Configurar Powerlevel10k
```bash
p10k configure
```

## 🔄 Actualización

```bash
cd ~/dotfiles
git pull
make update
```

## 📝 Post-Instalación

1. **Reinicia la terminal** o ejecuta `exec zsh`
2. **Configura p10k** con `p10k configure`
3. **Añade claves SSH** a `~/.ssh/`
4. **Configura Git:**
   ```bash
   git config --global user.name "Tu Nombre"
   git config --global user.email "tu@email.com"
   ```

## 🐛 Solución de Problemas

### Icons no se muestran
Asegúrate de usar una Nerd Font en tu terminal:
```bash
fc-list | grep -i "fira.*nerd"
```

### Tiempo de carga lento
Verifica con:
```bash
time zsh -i -c exit
```

### Errores de permisos Docker
```bash
sudo usermod -aG docker $USER
# Reinicia sesión
```

## 📄 Licencia

MIT License - Usa y modifica libremente.

---

**Autor:** nahuelrosas  
**Última actualización:** Diciembre 2024
