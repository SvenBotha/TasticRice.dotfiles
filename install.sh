#!/bin/zsh

# =============================================================================
#  Sven's Tastic macOS Setup Script
# =============================================================================
# This script sets up a complete development environment on macOS
# Usage: ./install.sh
# =============================================================================

set -e  # Exit on error

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Emoji prefixes for different types of output
INFO="ℹ️"
SUCCESS="✅"
WARNING="⚠️"
ERROR="❌"
INSTALL="📦"
CONFIG="⚙️"
COPY="📋"

# Space-separated list of casks to skip. Useful for headless/CI runs where
# password-prompting .pkg casks (e.g. the Microsoft apps) can't complete.
# Example: SKIP_CASKS="microsoft-teams microsoft-outlook" ./install.sh
SKIP_CASKS="${SKIP_CASKS:-}"

# Get the directory where this script is located.
# Note: this script runs under zsh (see shebang), which does not populate
# ${BASH_SOURCE[0]}. ${0:A:h} resolves the script's own absolute directory
# regardless of the current working directory it was invoked from.
SCRIPT_DIR="${0:A:h}"

# Logging function
log() {
    local level=$1
    local message=$2
    local color=$3
    echo -e "${color}${level} ${message}${NC}"
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Install Homebrew package if not already installed
install_brew_package() {
    local package=$1
    local is_cask=$2
    
    if [[ "$is_cask" == "cask" ]]; then
        if [[ " $SKIP_CASKS " == *" $package "* ]]; then
            log "$WARNING" "Skipping $package (listed in SKIP_CASKS)" "$YELLOW"
            return 0
        fi
        if brew list --cask "$package" >/dev/null 2>&1; then
            log "$SUCCESS" "$package (cask) already installed" "$GREEN"
        else
            log "$INSTALL" "Installing $package (cask)..." "$BLUE"
            # --adopt takes over a pre-existing (manually installed) app instead
            # of erroring. Cask failures are non-fatal (a GUI app that needs a
            # password, or is already present) so the rest of the setup — most
            # importantly the config-copy phase — still runs to completion.
            if ! brew install --cask --adopt "$package"; then
                log "$WARNING" "Could not install $package (cask) automatically — install it manually later" "$YELLOW"
            fi
        fi
    else
        if brew list --formula "$package" >/dev/null 2>&1; then
            log "$SUCCESS" "$package already installed" "$GREEN"
        else
            log "$INSTALL" "Installing $package..." "$BLUE"
            # Non-fatal so a single formula (e.g. one from a not-yet-trusted
            # third-party tap) can't abort the whole setup before configs copy.
            if ! brew install "$package"; then
                log "$WARNING" "Could not install $package — install it manually later" "$YELLOW"
            fi
        fi
    fi
}

# =============================================================================
# 🍺 Install Homebrew
# =============================================================================
echo -e "\n${PURPLE}=== Installing Homebrew ===${NC}"

if ! command_exists brew; then
    log "$INSTALL" "Installing Homebrew..." "$BLUE"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    
    # Add Homebrew to PATH for this session
    if [[ -f "/opt/homebrew/bin/brew" ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    elif [[ -f "/usr/local/bin/brew" ]]; then
        eval "$(/usr/local/bin/brew shellenv)"
    fi
    
    log "$SUCCESS" "Homebrew installed successfully" "$GREEN"
else
    log "$SUCCESS" "Homebrew already installed" "$GREEN"
fi

# Update Homebrew
log "$INFO" "Updating Homebrew..." "$CYAN"
brew update

# =============================================================================
# 🛠️ Install CLI Tools
# =============================================================================
echo -e "\n${PURPLE}=== Installing CLI Tools ===${NC}"

# Essential CLI tools
install_brew_package "git"
install_brew_package "zsh"
install_brew_package "tmux"
install_brew_package "neovim"
install_brew_package "fzf"
install_brew_package "bash"
install_brew_package "lazygit"
install_brew_package "python@3.12"
install_brew_package "node"
install_brew_package "eza"        # Modern ls replacement
install_brew_package "zoxide"     # Better cd
install_brew_package "ripgrep"    # Better grep
install_brew_package "fd"         # Better find
install_brew_package "bat"        # Better cat
install_brew_package "htop"       # Process viewer
install_brew_package "tree"       # Directory tree viewer
install_brew_package "wget"
install_brew_package "curl"
install_brew_package "jq"         # JSON processor
install_brew_package "gh"         # GitHub CLI

# =============================================================================
# 🖥️ Install GUI Applications
# =============================================================================
echo -e "\n${PURPLE}=== Installing GUI Applications ===${NC}"

install_brew_package "zen" "cask"
install_brew_package "google-chrome" "cask"   # bound to alt-d in AeroSpace
install_brew_package "visual-studio-code" "cask"
install_brew_package "cursor" "cask"          # bound to alt-c in AeroSpace
install_brew_package "microsoft-teams" "cask"
install_brew_package "microsoft-outlook" "cask" # bound to alt-m in AeroSpace
install_brew_package "whatsapp" "cask"        # bound to alt-p in AeroSpace
install_brew_package "obsidian" "cask"        # bound to alt-o in AeroSpace
install_brew_package "wezterm" "cask"
install_brew_package "zed" "cask"

# AeroSpace lives in the maintainer's tap, not homebrew/cask.
if ! brew tap | grep -qi "nikitabobko/tap"; then
    log "$INFO" "Adding nikitabobko/tap..." "$CYAN"
    brew tap nikitabobko/tap
fi
# Homebrew 6+ requires third-party taps to be explicitly trusted before it
# will load their casks/formulae.
brew trust nikitabobko/tap 2>/dev/null || true
install_brew_package "aerospace" "cask"
install_brew_package "raycast" "cask"

# Sketchybar (status bar driven by AeroSpace) lives in the FelixKratz tap,
# not homebrew-core, so tap it first.
if ! brew tap | grep -qi "felixkratz/formulae"; then
    log "$INFO" "Adding FelixKratz/formulae tap..." "$CYAN"
    brew tap FelixKratz/formulae
fi
# Homebrew 6+ requires third-party taps to be explicitly trusted.
brew trust felixkratz/formulae 2>/dev/null || true
install_brew_package "sketchybar"

# =============================================================================
# 🔤 Install Fonts
# =============================================================================
echo -e "\n${PURPLE}=== Installing Fonts ===${NC}"

# Note: the old 'homebrew/cask-fonts' tap was deprecated/archived in 2024.
# Nerd Font casks now live in the default 'homebrew/cask', so no tap is needed.
install_brew_package "font-meslo-lg-nerd-font" "cask"
install_brew_package "font-fira-code-nerd-font" "cask"
install_brew_package "font-hack-nerd-font" "cask"

# =============================================================================
# 🐚 Configure Zsh and Plugins
# =============================================================================
echo -e "\n${PURPLE}=== Configuring Zsh and Plugins ===${NC}"

# Install Zsh plugins
install_brew_package "powerlevel10k"
install_brew_package "zsh-autosuggestions"
install_brew_package "zsh-syntax-highlighting"

# Set Zsh as default shell only if the login shell isn't already a zsh.
# (Comparing basenames avoids a pointless password-prompting chsh when the
# user is already on macOS's default /bin/zsh but Homebrew provides its own.)
if [[ "$(basename "$SHELL")" != "zsh" ]]; then
    log "$CONFIG" "Setting Zsh as default shell..." "$YELLOW"
    chsh -s "$(which zsh)"
fi

# =============================================================================
# 📁 Create necessary directories
# =============================================================================
echo -e "\n${PURPLE}=== Creating necessary directories ===${NC}"

directories=(
    "$HOME/.config"
    "$HOME/.config/nvim"
    "$HOME/.config/zed"
    "$HOME/.tmux/plugins"
)

for dir in "${directories[@]}"; do
    if [[ ! -d "$dir" ]]; then
        log "$CONFIG" "Creating directory: $dir" "$YELLOW"
        mkdir -p "$dir"
    fi
done

# =============================================================================
# 🔗 Copy Configuration Files
# =============================================================================
echo -e "\n${PURPLE}=== Copying Configuration Files ===${NC}"

# Backup existing configs
backup_config() {
    local config_file=$1
    if [[ -f "$config_file" ]] || [[ -d "$config_file" ]]; then
        local backup_file="${config_file}.backup.$(date +%Y%m%d_%H%M%S)"
        log "$WARNING" "Backing up existing $config_file to $backup_file" "$YELLOW"
        mv "$config_file" "$backup_file"
    fi
}

# Copy Zsh configuration
log "$COPY" "Copying Zsh configuration..." "$CYAN"
backup_config "$HOME/.zshrc"
cp -v "$SCRIPT_DIR/Zshrc/zshrc" "$HOME/.zshrc"

# Copy WezTerm configuration
log "$COPY" "Copying WezTerm configuration..." "$CYAN"
backup_config "$HOME/.wezterm.lua"
cp -v "$SCRIPT_DIR/WezTerm/wezterm.lua" "$HOME/.wezterm.lua"

# Copy AeroSpace configuration
log "$COPY" "Copying AeroSpace configuration..." "$CYAN"
backup_config "$HOME/.aerospace.toml"
cp -v "$SCRIPT_DIR/AeroSpace/aerospace.toml" "$HOME/.aerospace.toml"

# Copy Tmux configuration
log "$COPY" "Copying Tmux configuration..." "$CYAN"
backup_config "$HOME/.tmux.conf"
cp -v "$SCRIPT_DIR/Tmux/tmux.conf" "$HOME/.tmux.conf"

# Copy Neovim configuration
log "$COPY" "Copying Neovim configuration..." "$CYAN"
backup_config "$HOME/.config/nvim"
cp -r "$SCRIPT_DIR/nvim" "$HOME/.config/"

# Zed configuration comes from its own repo (TasticRice.zed), which ships a
# platform-aware keymap + settings and its own symlink installer. We clone it to
# a persistent source dir and run that installer so edits there stay live.
log "$COPY" "Installing Zed configuration from TasticRice.zed..." "$CYAN"
ZED_SRC="$HOME/.local/share/tastic-zed"
if [[ -d "$ZED_SRC/.git" ]]; then
    git -C "$ZED_SRC" pull --ff-only || log "$WARNING" "Could not update TasticRice.zed" "$YELLOW"
else
    git clone https://github.com/SvenBotha/TasticRice.zed.git "$ZED_SRC" \
        || log "$WARNING" "Could not clone TasticRice.zed" "$YELLOW"
fi
if [[ -f "$ZED_SRC/install.sh" ]]; then
    bash "$ZED_SRC/install.sh" || log "$WARNING" "TasticRice.zed installer failed" "$YELLOW"
fi

# Copy Sketchybar configuration (referenced by aerospace.toml)
log "$COPY" "Copying Sketchybar configuration..." "$CYAN"
backup_config "$HOME/.config/sketchybar"
cp -r "$SCRIPT_DIR/Sketchybar/." "$HOME/.config/sketchybar/"
chmod +x "$HOME/.config/sketchybar/sketchybarrc" "$HOME"/.config/sketchybar/plugins/*.sh

# =============================================================================
# 🎨 Set Wallpaper
# =============================================================================
echo -e "\n${PURPLE}=== Setting Wallpaper ===${NC}"

if [[ -f "$SCRIPT_DIR/wallpapers/koi-fish.jpg" ]]; then
    log "$CONFIG" "Setting wallpaper..." "$YELLOW"
    osascript -e "tell application \"Finder\" to set desktop picture to POSIX file \"$SCRIPT_DIR/wallpapers/koi-fish.jpg\""
    log "$SUCCESS" "Wallpaper set successfully" "$GREEN"
else
    log "$WARNING" "Wallpaper file not found" "$YELLOW"
fi

# =============================================================================
# 🔧 Configure Tmux Plugin Manager
# =============================================================================
echo -e "\n${PURPLE}=== Configuring Tmux Plugin Manager ===${NC}"

if [[ ! -d "$HOME/.tmux/plugins/tpm" ]]; then
    log "$INSTALL" "Installing Tmux Plugin Manager..." "$BLUE"
    git clone https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
    log "$SUCCESS" "TPM installed successfully" "$GREEN"
else
    log "$SUCCESS" "TPM already installed" "$GREEN"
fi

# Install tmux plugins
if command_exists tmux; then
    log "$CONFIG" "Installing Tmux plugins..." "$YELLOW"
    "$HOME/.tmux/plugins/tpm/bin/install_plugins"
fi

# =============================================================================
# 📊 Start Sketchybar
# =============================================================================
echo -e "\n${PURPLE}=== Starting Sketchybar ===${NC}"

if command_exists sketchybar; then
    log "$CONFIG" "Starting Sketchybar service..." "$YELLOW"
    brew services restart sketchybar
    log "$SUCCESS" "Sketchybar started" "$GREEN"
else
    log "$WARNING" "Sketchybar not found; skipping" "$YELLOW"
fi

# =============================================================================
# 🧹 Cleanup and Final Steps
# =============================================================================
echo -e "\n${PURPLE}=== Cleanup and Final Steps ===${NC}"

# Cleanup Homebrew
log "$INFO" "Cleaning up Homebrew..." "$CYAN"
brew cleanup

# Initialize fzf
if command_exists fzf; then
    log "$CONFIG" "Setting up fzf..." "$YELLOW"
    "$(brew --prefix)"/opt/fzf/install --all --no-bash --no-fish
fi

# =============================================================================
# 🎉 Installation Complete
# =============================================================================
echo -e "\n${GREEN}=== Installation Complete! ===${NC}"
echo -e "\n${CYAN}🎊 Your macOS development environment has been set up successfully!${NC}\n"

log "$INFO" "Please complete the following manual steps:" "$CYAN"
echo -e "  ${YELLOW}1.${NC} Restart your terminal or run: ${BLUE}source ~/.zshrc${NC}"
echo -e "  ${YELLOW}2.${NC} Configure Powerlevel10k by running: ${BLUE}p10k configure${NC}"
echo -e "  ${YELLOW}3.${NC} Start AeroSpace from Applications folder"
echo -e "  ${YELLOW}4.${NC} Open WezTerm and verify the configuration"
echo -e "  ${YELLOW}5.${NC} Launch Neovim and let Lazy.nvim install plugins"
echo -e "  ${YELLOW}6.${NC} Open Zed; reload with '\\ space -> workspace: reload' so the symlinked keymap loads"

echo -e "\n${PURPLE}🚀 Happy coding!${NC}\n"

# =============================================================================
# 📝 Configuration Summary
# =============================================================================
echo -e "${BLUE}=== Configuration Summary ===${NC}"
echo -e "  ${CYAN}Shell:${NC}        Zsh with Powerlevel10k theme"
echo -e "  ${CYAN}Terminal:${NC}     WezTerm with custom config"
echo -e "  ${CYAN}Window Mgr:${NC}   AeroSpace (tiling window manager)"
echo -e "  ${CYAN}Editor:${NC}       Neovim with custom configuration"
echo -e "  ${CYAN}GUI Editor:${NC}   Zed (config from TasticRice.zed: leader-key keymap, Cursor base)"
echo -e "  ${CYAN}Multiplexer:${NC}  Tmux with plugins"
echo -e "  ${CYAN}Git UI:${NC}       Lazygit"
echo -e "  ${CYAN}File Browser:${NC} Eza (modern ls)"
echo -e "  ${CYAN}Directory Nav:${NC} Zoxide (better cd)"
echo -e "\n${GREEN}All configurations have been backed up with timestamps.${NC}"
