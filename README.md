# 🚀 Dotfiles - Optimized Configuration for Fedora

[![Fedora](https://img.shields.io/badge/Fedora-294172?style=for-the-badge&logo=fedora&logoColor=white)](https://getfedora.org/)
[![Zsh](https://img.shields.io/badge/Zsh-F15A24?style=for-the-badge&logo=gnu-bash&logoColor=white)](https://www.zsh.org/)
[![License](https://img.shields.io/badge/License-MIT-green.svg?style=for-the-badge)](LICENSE)

Terminal configuration optimized for maximum performance and productivity.

## ⚡ Features

- **Load time <100ms** - Lazy loading and optimized cache
- **Interactive installer** - Sudo upfront, backup options, install/reinstall modes
- **Powerlevel10k** - Beautiful and informative prompt
- **50+ aliases** - Simplified frequent commands
- **25+ functions** - Development utilities
- **NVIDIA GPU support** - Automatic detection and driver installation
- **VPN ready** - OpenVPN and WireGuard support

## 📦 Includes

| Category | Tools |
|----------|-------|
| 🐚 Shell | Zsh, Oh-My-Zsh, Powerlevel10k |
| 📝 Editor | VSCode, Cursor |
| 🔍 Search | FZF, Ripgrep, fd-find |
| 📁 Files | lsd, eza, bat, colorls |
| 🐳 Containers | Docker, Docker Compose |
| 🌐 Browser | Brave |
| 📦 Node | NVM, Node LTS, PNPM |
| 🐍 Python | Miniconda |
| 🔧 Utils | lazygit, btop, zoxide, tldr, duf, procs, dust |
| 🔐 VPN | OpenVPN, WireGuard |
| 🎮 GPU | NVIDIA drivers (auto-detect) |

## 🚀 Quick Installation

```bash
git clone https://github.com/nahuelrosas/dotfiles.git ~/dotfiles
cd ~/dotfiles
./install.sh
```

The installer will:
1. Request sudo access upfront
2. Ask about backup preferences
3. Let you choose fresh install or reinstall mode
4. Offer optional components (NVIDIA drivers, VPN tools)

## 📋 Requirements

- **OS:** Fedora 38+ (tested on Fedora 43)
- **RAM:** 4GB minimum
- **Internet:** Required for installation

## 🔧 Make Commands

```bash
# Installation
make install          # Interactive installation
make reinstall        # Force reinstall all packages

# Backup Management
make backup           # Create a new backup
make clean-backups    # Remove old backups (keep latest)
make delete-all-backups # Delete ALL backups

# Updates
make update           # Update all tools and plugins

# Individual Components
make nvidia           # Install NVIDIA drivers
make vpn              # Install VPN tools
make docker           # Setup Docker
make fonts            # Install Nerd Fonts
make flatpak          # Install Flatpak apps

# Utilities
make test             # Test shell startup time
make compile          # Compile zsh files
make clean            # Remove compiled files
make status           # Show current status
make lint             # Check scripts for errors
make help             # Show all commands
```

## 📁 Structure

```
dotfiles/
├── zsh/                  # Modular Zsh configuration
│   ├── .zshrc            # Main config
│   ├── .zshenv           # Environment variables
│   ├── aliases.zsh       # Aliases
│   ├── functions.zsh     # Useful functions
│   └── lazy-loaders.zsh  # Lazy loading for performance
├── kitty/                # Kitty terminal configuration
├── git/                  # Git configuration
├── scripts/              # Installation scripts
│   ├── setup-fedora.sh   # Base packages
│   ├── setup-tools.sh    # Dev tools
│   ├── setup-docker.sh   # Docker
│   ├── setup-nvm.sh      # Node.js
│   ├── setup-fonts.sh    # Nerd Fonts
│   ├── setup-flatpak.sh  # Flatpak apps
│   ├── setup-nvidia.sh   # NVIDIA drivers
│   └── setup-vpn.sh      # VPN tools
└── config/               # Other configurations
```

## ⌨️ Main Aliases

| Alias | Command | Description |
|-------|---------|-------------|
| `ll` | `lsd -lh` | Detailed listing |
| `cat` | `bat` | Cat with syntax highlighting |
| `lg` | `lazygit` | Git TUI |
| `top` | `btop` | System monitor |
| `..` | `cd ..` | Go up directory |
| `gs` | `git status` | Git status |

## 🛠️ Useful Functions

| Function | Description |
|----------|-------------|
| `extract <file>` | Extract any compressed file |
| `mkcd <dir>` | Create directory and enter it |
| `ff` | Interactive file search |
| `fgr <term>` | Search in file contents |
| `gcob` | Interactive branch checkout |
| `dshell` | Shell into Docker container |
| `fkill` | Kill process interactively |
| `sysinfo` | System information |

## 🎨 Customization

### Change Kitty theme
Edit `kitty/kitty.conf` and change the line:
```conf
include dracula.conf
# For example: include tokyo-night.conf
```

### Configure Powerlevel10k
```bash
p10k configure
```

## 🔄 Update

```bash
cd ~/dotfiles
git pull
make update
```

## 📝 Post-Installation

1. **Restart the terminal** or run `exec zsh`
2. **Configure p10k** with `p10k configure`
3. **Add SSH keys** to `~/.ssh/`
4. **Configure Git:**
   ```bash
   git config --global user.name "Your Name"
   git config --global user.email "your@email.com"
   ```

## 🐛 Troubleshooting

### Icons not showing
Make sure you're using a Nerd Font in your terminal:
```bash
fc-list | grep -i "fira.*nerd"
```

### Slow load time
Check with:
```bash
make test
```

### Docker permission errors
```bash
sudo usermod -aG docker $USER
# Restart session
```

### NVIDIA driver issues
```bash
# Check if GPU is detected
lspci | grep -i nvidia

# Reinstall drivers
make nvidia
```

## 📄 License

MIT License - Use and modify freely.

---

**Author:** nahuelrosas  
**Last updated:** December 2025
