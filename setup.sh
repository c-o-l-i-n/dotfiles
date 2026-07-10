#!/usr/bin/env zsh

set -e

# ============================================================================
# macOS Dotfiles Setup Script
# ============================================================================
# This script automates system configuration for macOS
# Safe to run multiple times (idempotent)
# Requires: zsh
# ============================================================================

# Verify we're running in zsh
if [[ -z "$ZSH_VERSION" ]]; then
  echo "Error: This script requires zsh"
  echo "Please install zsh and run: zsh $0"
  exit 1
fi

# Colors and formatting
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

# Manual steps tracking
MANUAL_STEPS=()

# Helper functions
print_header() {
  echo -e "\n${CYAN}${BOLD}╔════════════════════════════════════════════════════════════════╗${RESET}"
  printf "${CYAN}${BOLD}║  %-62s║${RESET}\n" "$1"
  echo -e "${CYAN}${BOLD}╚════════════════════════════════════════════════════════════════╝${RESET}\n"
}

print_step() {
  echo -e "${BLUE}▸${RESET} ${BOLD}$1${RESET}"
}

print_success() {
  echo -e "${GREEN}✓${RESET} $1"
}

print_warning() {
  echo -e "${YELLOW}⚠${RESET} $1"
}

print_error() {
  echo -e "${RED}✗${RESET} $1"
}

add_manual_step() {
  MANUAL_STEPS+=("$1")
}

command_exists() {
  command -v "$1" >/dev/null 2>&1
}

# ============================================================================
# Verify Operating System
# ============================================================================

check_os() {
  if [[ "$OSTYPE" != "darwin"* ]]; then
    echo "Error: This script only supports macOS"
    exit 1
  fi
}

check_os

# ============================================================================
# Package Manager Setup
# ============================================================================

install_package_manager() {
  print_header "Homebrew Installation"
  if command_exists brew; then
    print_success "Homebrew already installed"
  else
    print_step "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    eval "$(/opt/homebrew/bin/brew shellenv)"
    print_success "Homebrew installed successfully"
  fi
}

# ============================================================================
# Install Packages
# ============================================================================

install_packages() {
  print_header "Installing Packages"

  local brew_packages=(
    borders
    btop
    cmatrix
    cowsay
    eza
    fastfetch
    fd
    ffmpeg
    fzf
    gh
    git
    gnupg
    imagemagick
    lazygit
    mise
    neovim
    ripgrep
    shfmt
    asmvik/formulae/skhd
    starship
    stow
    asmvik/formulae/yabai
    zoxide
  )

  local brew_casks=(
    font-caskaydia-cove-nerd-font
    font-sf-pro
    ghostty
    localsend
  )

  # Run Homebrew non-interactively so it doesn't pause for "Do you want to
  # proceed with the installation? [Y/n]" or other confirmation prompts.
  export HOMEBREW_NO_ASK=1
  export HOMEBREW_NO_AUTO_UPDATE=1
  export HOMEBREW_NO_ENV_HINTS=1

  # borders is distributed via the FelixKratz tap; skhd via asmvik/formulae
  print_step "Tapping required formulae..."
  brew tap FelixKratz/formulae
  brew tap asmvik/formulae

  print_step "Installing Homebrew packages..."
  for package in "${brew_packages[@]}"; do
    local pkg_name="${package##*/}"
    if brew list "$pkg_name" &>/dev/null; then
      echo "  → $package already installed"
    else
      brew install "$package"
    fi
  done

  print_step "Installing Homebrew casks..."
  for cask in "${brew_casks[@]}"; do
    if brew list --cask "$cask" &>/dev/null; then
      echo "  → $cask already installed"
    else
      brew install --cask "$cask"
    fi
  done

  print_success "All packages installed"
}

# ============================================================================
# Setup Dotfiles
# ============================================================================

setup_dotfiles() {
  print_header "Dotfiles Configuration"

  local dotfiles_dir="$HOME/dotfiles"

  if [[ -d "$dotfiles_dir" ]]; then
    print_warning "Dotfiles directory already exists"
    print_step "Pulling latest changes..."
    cd "$dotfiles_dir"
    git pull
  else
    print_step "Cloning dotfiles repository..."
    git clone https://github.com/c-o-l-i-n/dotfiles "$dotfiles_dir"
    cd "$dotfiles_dir"
  fi

  print_step "Stowing dotfiles..."
  stow --restow .

  print_success "Dotfiles configured"
}

# ============================================================================
# Apply Wallpaper
# ============================================================================

apply_wallpaper() {
  print_header "Applying Wallpaper"

  local wallpaper_path="$HOME/dotfiles/wallpapers/eclipse.jpg"

  if [[ -f "$wallpaper_path" ]]; then
    print_step "Setting desktop wallpaper..."
    osascript -e "tell application \"Finder\" to set desktop picture to POSIX file \"$wallpaper_path\""
    print_success "Wallpaper applied"
  else
    print_warning "Wallpaper not found at $wallpaper_path"
  fi
}

# ============================================================================
# Install Übersicht and simple-bar
# ============================================================================

setup_uebersicht() {
  print_header "Übersicht Setup"

  if [[ -d "/Applications/Übersicht.app" ]]; then
    print_success "Übersicht already installed"
  else
    print_warning "Übersicht not installed"
    add_manual_step "Install Übersicht from: https://tracesof.net/uebersicht/"
  fi

  # Install simple-bar widget
  local simplebar_dir="$HOME/Library/Application Support/Übersicht/widgets/simple-bar"

  if [[ -d "$simplebar_dir" ]]; then
    print_success "simple-bar widget already installed"
    cd "$simplebar_dir"
    git pull
  else
    print_step "Installing simple-bar widget..."
    mkdir -p "$HOME/Library/Application Support/Übersicht/widgets"
    git clone https://github.com/Jean-Tinland/simple-bar "$simplebar_dir"
    print_success "simple-bar widget installed"
  fi
}

# ============================================================================
# Create Development Directory
# ============================================================================

create_dev_directory() {
  print_header "Development Environment"

  local dev_dir="$HOME/code"

  if [[ -d "$dev_dir" ]]; then
    print_success "Development directory already exists"
  else
    print_step "Creating development directory..."
    mkdir -p "$dev_dir"
    print_success "Development directory created"
  fi
}

# ============================================================================
# Setup Node.js with mise
# ============================================================================

setup_nodejs() {
  print_step "Setting up Node.js..."

  if mise which node &>/dev/null; then
    print_success "Node.js already configured with mise"
  else
    mise use --global node@lts
    print_success "Node.js LTS installed via mise"
  fi

  # Reload mise
  eval "$(mise activate zsh)"
}

# ============================================================================
# Install simple-bar-server
# ============================================================================

setup_simplebar_server() {
  print_step "Setting up simple-bar-server..."

  local server_dir="$HOME/code/simple-bar-server"

  if [[ -d "$server_dir" ]]; then
    print_success "simple-bar-server already cloned"
    cd "$server_dir"
    git pull
  else
    print_step "Cloning simple-bar-server..."
    git clone https://github.com/Jean-Tinland/simple-bar-server.git "$server_dir"
    cd "$server_dir"
  fi

  print_step "Installing server dependencies..."
  npm install

  if command_exists pm2; then
    print_success "pm2 already installed"
  else
    print_step "Installing pm2..."
    npm install pm2 -g
  fi

  print_step "Starting simple-bar-server..."
  pm2 delete simple-bar-server 2>/dev/null || true
  pm2 startOrRestart ecosystem.config.cjs
  pm2 save

  print_success "simple-bar-server configured"

  # Configure pm2 startup automatically
  print_step "Checking pm2 startup configuration..."

  # Check if pm2 startup is already configured by looking for the plist file
  local pm2_plist="$HOME/Library/LaunchAgents/pm2.$(whoami).plist"

  if [[ ! -f "$pm2_plist" ]]; then
    # Need to run pm2 startup command
    local startup_cmd=$(pm2 startup 2>&1 | grep -E "sudo env PATH" | head -1)

    if [[ -n "$startup_cmd" ]]; then
      echo ""
      echo -e "${YELLOW}${BOLD}pm2 needs to be configured to start on boot.${RESET}"
      echo -e "${YELLOW}This requires running a command with sudo privileges.${RESET}"
      echo ""
      echo -e "${BLUE}The command will:${RESET}"
      echo -e "  • Configure pm2 to automatically start simple-bar-server on login"
      echo -e "  • Create necessary system files for startup management"
      echo ""
      echo -ne "${BOLD}Would you like to run this command now? [y/N]: ${RESET}"
      read -r response

      if [[ "$response" =~ ^[Yy]$ ]]; then
        echo ""
        echo -e "${CYAN}Running pm2 startup command...${RESET}"
        echo -e "${CYAN}(You'll be prompted for your password to allow pm2 system configuration)${RESET}"
        echo ""
        eval "$startup_cmd"
        print_success "pm2 startup configured"
      else
        print_warning "Skipping pm2 startup configuration"
        add_manual_step "Configure pm2 to start on boot by running: pm2 startup
    Then run the sudo command it provides"
      fi
    fi
  else
    print_success "pm2 startup already configured"
  fi

  # Patch the plist to use the mise 'lts' symlink for Node instead of a
  # hard-coded version number. This ensures pm2 keeps working after upgrading
  # Node LTS (e.g. node/24.12.0 → node/lts).
  if [[ -f "$pm2_plist" ]]; then
    print_step "Patching pm2 plist to use Node LTS symlink..."
    local mise_node_dir="$HOME/.local/share/mise/installs/node"

    # Replace any hard-coded node version (e.g. /node/24.12.0/) with /node/lts/
    # Uses an in-place sed substitution; the pattern matches a version-like string
    # (digits, dots) sitting between /node/ and the next path component.
    if sed -i '' "s|${mise_node_dir}/[0-9][^/]*/|${mise_node_dir}/lts/|g" "$pm2_plist"; then
      print_success "pm2 plist patched to use Node LTS symlink"
    else
      print_warning "Could not patch pm2 plist — you may need to update it manually"
      add_manual_step "Edit $pm2_plist and replace hard-coded node version paths (e.g. /node/24.12.0/) with /node/lts/"
    fi

    # Reload the LaunchAgent so the change takes effect immediately
    launchctl unload "$pm2_plist" 2>/dev/null || true
    launchctl load "$pm2_plist"
    print_success "LaunchAgent reloaded"
  fi

  cd ~
}

# ============================================================================
# Yabai Configuration
# ============================================================================

setup_yabai() {
  print_header "Yabai Configuration"

  # Check if SIP is partially disabled
  local sip_status=$(csrutil status 2>/dev/null)

  if echo "$sip_status" | grep -q "System Integrity Protection status: disabled"; then
    print_success "SIP is fully disabled (yabai features will work)"
  elif echo "$sip_status" | grep -q "Filesystem Protections: disabled" &&
    echo "$sip_status" | grep -q "Debugging Restrictions: disabled" &&
    echo "$sip_status" | grep -q "NVRAM Protections: disabled"; then
    print_success "SIP is partially disabled for yabai (correct configuration)"
  else
    print_warning "SIP needs to be partially disabled for advanced yabai features"
    add_manual_step "Partially disable SIP for yabai features: https://github.com/koekeishiya/yabai/wiki/Disabling-System-Integrity-Protection"
  fi

  # Configure passwordless sudo for yabai scripting addition.
  # The sha256 hash is tied to the current yabai binary, so re-running after
  # a yabai upgrade will update the entry automatically.
  print_step "Configuring yabai sudoers entry..."
  local yabai_path=$(which yabai)
  local yabai_sha=$(shasum -a 256 "$yabai_path" | cut -d " " -f 1)
  local sudoers_entry="$(whoami) ALL=(root) NOPASSWD: sha256:${yabai_sha} ${yabai_path} --load-sa"
  local sudoers_file="/private/etc/sudoers.d/yabai"

  if sudo grep -qF "$sudoers_entry" "$sudoers_file" 2>/dev/null; then
    print_success "yabai sudoers entry already up to date"
  else
    echo "$sudoers_entry" | sudo tee "$sudoers_file" >/dev/null
    print_success "yabai sudoers entry configured"
  fi
}

# ============================================================================
# Start Window Management Services (yabai + skhd)
# ============================================================================

start_window_management_services() {
  print_header "Window Management Services (yabai + skhd)"

  print_step "Starting yabai service..."
  yabai --start-service 2>/dev/null || true

  print_step "Starting skhd service..."
  skhd --start-service 2>/dev/null || true

  echo ""
  echo -e "${YELLOW}${BOLD}Action Required: Accessibility Permissions${RESET}"
  echo -e "${YELLOW}yabai and skhd need Accessibility access to manage windows and hotkeys.${RESET}"
  echo ""
  echo -e "${BLUE}Steps:${RESET}"
  echo -e "  1. Open ${BOLD}System Settings > Privacy & Security > Accessibility${RESET}"
  echo -e "  2. Enable both ${BOLD}yabai${RESET} and ${BOLD}skhd${RESET}"
  echo -e "  3. Press ${BOLD}Enter${RESET} to restart the services"
  echo ""
  read -r "?Press Enter after granting Accessibility permissions... "
  echo ""

  print_step "Restarting yabai..."
  yabai --restart-service 2>/dev/null || true

  print_step "Restarting skhd..."
  skhd --restart-service 2>/dev/null || true

  print_success "yabai and skhd services running"
}

# ============================================================================
# Install Banana Cursor
# ============================================================================

install_banana_cursor() {
  print_header "Banana Cursor Setup"

  local mousecape_app="/Applications/Mousecape.app"
  local mousecape_capes_dir="$HOME/Library/Application Support/Mousecape/capes"
  local dotfiles_capes_dir="$HOME/.config/mousescape/capes"

  if [[ -d "$mousecape_app" ]]; then
    print_success "Mousecape already installed"

    print_step "Removing quarantine attribute..."
    xattr -d com.apple.quarantine "$mousecape_app" 2>/dev/null || print_warning "Quarantine attribute already removed or not present"

    # Create the Mousecape support directory if it doesn't exist
    mkdir -p "$(dirname "$mousecape_capes_dir")"

    # Setup symlink for capes directory
    if [[ -L "$mousecape_capes_dir" ]]; then
      print_success "Mousecape capes symlink already configured"
    elif [[ -d "$mousecape_capes_dir" ]]; then
      print_warning "Mousecape capes directory exists but is not a symlink"
      print_step "Backing up existing capes directory..."
      mv "$mousecape_capes_dir" "${mousecape_capes_dir}.backup"
      print_step "Creating symlink to dotfiles capes directory..."
      ln -s "$dotfiles_capes_dir" "$mousecape_capes_dir"
      print_success "Symlink created (backup saved to ${mousecape_capes_dir}.backup)"
    else
      print_step "Creating symlink to dotfiles capes directory..."
      ln -s "$dotfiles_capes_dir" "$mousecape_capes_dir"
      print_success "Symlink created"
    fi

    add_manual_step "Configure Mousecape:
    1. Open Mousecape
    2. Open Settings > General: Install 'Mousescape Helper' and enable 'Apply Last Cape on Launch'
    3. Save settings
    4. Select the Banana cursor to apply it"
  else
    print_warning "Mousecape not installed"
    add_manual_step "Install Mousecape from: https://github.com/sdmj76/Mousecape-swiftUI/releases/latest
    Then run this script again to configure the capes symlink"
  fi
}

# ============================================================================
# Finalize Setup
# ============================================================================

finalize_setup() {
  print_header "Finalizing Setup"

  print_success "Shell configuration will be active in new terminal sessions"
}

# ============================================================================
# Main Execution
# ============================================================================

main() {
  print_header "Setup Starting..."

  install_package_manager
  install_packages
  setup_dotfiles
  apply_wallpaper
  setup_uebersicht
  create_dev_directory
  setup_nodejs
  setup_simplebar_server
  setup_yabai
  start_window_management_services
  install_banana_cursor
  finalize_setup

  # ============================================================================
  # Summary
  # ============================================================================

  print_header "Setup Complete!"

  if [[ ${#MANUAL_STEPS[@]} -gt 0 ]]; then
    echo -e "${YELLOW}${BOLD}Manual Steps Required:${RESET}\n"
    local i=1
    for step in "${MANUAL_STEPS[@]}"; do
      echo -e "${MAGENTA}${i}.${RESET} ${step}\n"
      ((i++))
    done
  else
    print_success "No manual steps required!"
    echo -e "${CYAN}${BOLD}╔════════════════════════════════════════════════════════════════╗${RESET}"
    printf "${CYAN}${BOLD}║  %-62s║${RESET}\n" "Your system is ready!"
    echo -e "${CYAN}${BOLD}╚════════════════════════════════════════════════════════════════╝${RESET}\n"
  fi
}

# Run main function
main
