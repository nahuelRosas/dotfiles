.PHONY: install backup update uninstall help test reinstall clean-backups nvidia vpn

# Colors
CYAN := \033[0;36m
GREEN := \033[0;32m
YELLOW := \033[1;33m
RED := \033[0;31m
NC := \033[0m

help: ## Show this help
	@echo ""
	@echo "$(CYAN)Dotfiles Management$(NC)"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(GREEN)%-18s$(NC) %s\n", $$1, $$2}'
	@echo ""

install: ## Run full installation (interactive)
	@chmod +x install.sh
	@./install.sh

reinstall: ## Force reinstall all packages
	@chmod +x install.sh
	@FORCE_REINSTALL=true ./install.sh

backup: ## Backup current dotfiles
	@echo "$(CYAN)Creating backup...$(NC)"
	@mkdir -p ~/.dotfiles-backup-$$(date +%Y%m%d-%H%M%S)
	@cp -r ~/.zshrc ~/.zshenv ~/.zprofile ~/.zlogout ~/.p10k.zsh ~/.config/kitty ~/.gitconfig ~/.dotfiles-backup-$$(date +%Y%m%d-%H%M%S)/ 2>/dev/null || true
	@echo "$(GREEN)Backup created$(NC)"

clean-backups: ## Remove all old backups (keeps latest)
	@echo "$(YELLOW)Cleaning old backups...$(NC)"
	@BACKUPS=$$(ls -dt ~/.dotfiles-backup-* 2>/dev/null); \
	COUNT=$$(echo "$$BACKUPS" | wc -w); \
	if [ "$$COUNT" -gt 1 ]; then \
		echo "$$BACKUPS" | tail -n +2 | xargs rm -rf; \
		echo "$(GREEN)Removed $$((COUNT - 1)) old backup(s)$(NC)"; \
	else \
		echo "$(GREEN)No old backups to clean$(NC)"; \
	fi

delete-all-backups: ## Delete ALL backup directories
	@echo "$(RED)WARNING: This will delete ALL backups!$(NC)"
	@read -p "Are you sure? [y/N]: " confirm; \
	if [ "$$confirm" = "y" ] || [ "$$confirm" = "Y" ]; then \
		rm -rf ~/.dotfiles-backup-*; \
		echo "$(GREEN)All backups deleted$(NC)"; \
	else \
		echo "Cancelled"; \
	fi

update: ## Update all tools and plugins
	@echo "$(CYAN)Updating Oh-My-Zsh...$(NC)"
	@cd ~/.oh-my-zsh && git pull --quiet
	@echo "$(CYAN)Updating Powerlevel10k...$(NC)"
	@cd ~/.oh-my-zsh/custom/themes/powerlevel10k && git pull --quiet
	@echo "$(CYAN)Updating plugins...$(NC)"
	@for dir in ~/.oh-my-zsh/custom/plugins/*/; do \
		echo "  Updating $$(basename $$dir)..."; \
		cd "$$dir" && git pull --quiet 2>/dev/null || true; \
	done
	@echo "$(CYAN)Updating FZF...$(NC)"
	@cd ~/.fzf && git pull --quiet && ./install --all --no-bash --no-fish --no-update-rc
	@echo "$(CYAN)Updating system packages...$(NC)"
	@sudo dnf upgrade -y --quiet
	@echo "$(CYAN)Updating Flatpak...$(NC)"
	@flatpak update -y
	@echo "$(GREEN)Update complete!$(NC)"

uninstall: ## Remove symlinks and restore backups
	@chmod +x uninstall.sh
	@./uninstall.sh

test: ## Test shell startup time
	@echo "$(CYAN)Testing shell startup time...$(NC)"
	@for i in 1 2 3; do \
		time zsh -i -c exit 2>&1; \
	done
	@echo ""
	@echo "$(GREEN)Target: <100ms$(NC)"

lint: ## Check scripts for errors
	@echo "$(CYAN)Checking scripts with shellcheck...$(NC)"
	@shellcheck install.sh scripts/*.sh 2>/dev/null || echo "$(YELLOW)Install shellcheck: sudo dnf install shellcheck$(NC)"

compile: ## Compile zsh files for faster loading
	@echo "$(CYAN)Compiling zsh files...$(NC)"
	@zsh -c 'for f in ~/.zshrc ~/.zshenv ~/.zprofile ~/.config/zsh/*.zsh; do [[ -f $$f ]] && zcompile $$f; done'
	@echo "$(GREEN)Compilation complete$(NC)"

clean: ## Remove compiled zsh files
	@echo "$(CYAN)Removing .zwc files...$(NC)"
	@rm -f ~/.zshrc.zwc ~/.zshenv.zwc ~/.zprofile.zwc ~/.config/zsh/*.zwc
	@echo "$(GREEN)Cleaned$(NC)"

nvidia: ## Install NVIDIA proprietary drivers
	@echo "$(CYAN)Installing NVIDIA drivers...$(NC)"
	@chmod +x scripts/setup-nvidia.sh
	@./scripts/setup-nvidia.sh

vpn: ## Install VPN tools (OpenVPN + WireGuard)
	@echo "$(CYAN)Installing VPN tools...$(NC)"
	@chmod +x scripts/setup-vpn.sh
	@./scripts/setup-vpn.sh

cloud: ## Install Cloud CLIs (AWS, GCloud, Firebase, Terraform, etc.)
	@echo "$(CYAN)Installing Cloud CLI tools...$(NC)"
	@chmod +x scripts/setup-cloud.sh
	@./scripts/setup-cloud.sh

docker: ## Setup Docker
	@echo "$(CYAN)Setting up Docker...$(NC)"
	@chmod +x scripts/setup-docker.sh
	@./scripts/setup-docker.sh

fonts: ## Install Nerd Fonts
	@echo "$(CYAN)Installing Nerd Fonts...$(NC)"
	@chmod +x scripts/setup-fonts.sh
	@./scripts/setup-fonts.sh

flatpak: ## Install Flatpak applications
	@echo "$(CYAN)Installing Flatpak apps...$(NC)"
	@chmod +x scripts/setup-flatpak.sh
	@./scripts/setup-flatpak.sh

status: ## Show current dotfiles status
	@echo ""
	@echo "$(CYAN)Dotfiles Status$(NC)"
	@echo ""
	@echo "Shell: $$SHELL"
	@echo "Zsh: $$(zsh --version)"
	@echo "Oh-My-Zsh: $$([[ -d ~/.oh-my-zsh ]] && echo 'installed' || echo 'not installed')"
	@echo "P10k: $$([[ -d ~/.oh-my-zsh/custom/themes/powerlevel10k ]] && echo 'installed' || echo 'not installed')"
	@echo "NVM: $$(command -v nvm >/dev/null && nvm --version || echo 'not installed')"
	@echo "Docker: $$(command -v docker >/dev/null && docker --version | awk '{print $$3}' | tr -d ',' || echo 'not installed')"
	@echo ""
	@echo "Backups: $$(ls -d ~/.dotfiles-backup-* 2>/dev/null | wc -l)"
	@echo ""
