.PHONY: install backup update uninstall help test

# Colors
CYAN := \033[0;36m
GREEN := \033[0;32m
YELLOW := \033[1;33m
NC := \033[0m

help: ## Show this help
	@echo ""
	@echo "$(CYAN)Dotfiles Management$(NC)"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(GREEN)%-15s$(NC) %s\n", $$1, $$2}'
	@echo ""

install: ## Run full installation
	@chmod +x install.sh
	@./install.sh

backup: ## Backup current dotfiles
	@echo "$(CYAN)Creating backup...$(NC)"
	@mkdir -p ~/.dotfiles-backup-$$(date +%Y%m%d-%H%M%S)
	@cp -r ~/.zshrc ~/.zshenv ~/.zprofile ~/.zlogout ~/.p10k.zsh ~/.config/kitty ~/.gitconfig ~/.dotfiles-backup-$$(date +%Y%m%d-%H%M%S)/ 2>/dev/null || true
	@echo "$(GREEN)Backup created$(NC)"

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
	@echo "$(GREEN)Update complete!$(NC)"

uninstall: ## Remove symlinks and restore backups
	@echo "$(YELLOW)Removing symlinks...$(NC)"
	@rm -f ~/.zshrc ~/.zshenv ~/.zprofile ~/.zlogout ~/.p10k.zsh
	@rm -f ~/.config/zsh/aliases.zsh ~/.config/zsh/functions.zsh
	@rm -f ~/.config/kitty/kitty.conf ~/.config/kitty/dracula.conf
	@echo "$(CYAN)Looking for latest backup...$(NC)"
	@LATEST_BACKUP=$$(ls -td ~/.dotfiles-backup-* 2>/dev/null | head -1); \
	if [ -n "$$LATEST_BACKUP" ]; then \
		echo "Restoring from $$LATEST_BACKUP..."; \
		cp -r $$LATEST_BACKUP/.* ~/ 2>/dev/null || true; \
		echo "$(GREEN)Backup restored$(NC)"; \
	else \
		echo "$(YELLOW)No backup found$(NC)"; \
	fi

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
