#!/usr/bin/env zsh

set -e

# ============================================================================
# Cross-Platform Dotfiles Setup Script
# ============================================================================
# This script automates system configuration for macOS, Ubuntu, and Arch
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

# Detect OS
detect_os() {
  if [[ "$OSTYPE" == "darwin"* ]]; then
    OS="macos"
  elif [[ -f /etc/os-release ]]; then
    . /etc/os-release
    case "$ID" in
    ubuntu | debian)
      OS="ubuntu"
      ;;
    arch | manjaro)
      OS="arch"
      ;;
    *)
      echo "Unsupported Linux distribution: $ID"
      exit 1
      ;;
    esac
  else
    echo "Unable to detect operating system"
    exit 1
  fi
}

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
# Detect Operating System
# ============================================================================

detect_os
print_header "Detected OS: ${OS:u}"

# ============================================================================
# Package Manager Setup
# ============================================================================

install_package_manager() {
  case "$OS" in
  macos)
    print_header "Homebrew Installation"
    if command_exists brew; then
      print_success "Homebrew already installed"
    else
      print_step "Installing Homebrew..."
      /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
      eval "$(/opt/homebrew/bin/brew shellenv)"
      print_success "Homebrew installed successfully"
    fi
    ;;
  ubuntu)
    print_header "Package Manager Setup"

    # Install zsh if not present
    if ! command_exists zsh; then
      print_step "Installing zsh..."
      sudo apt update
      sudo apt install -y zsh
      print_success "zsh installed"
    else
      print_success "zsh already installed"
    fi

    # Set zsh as default shell if not already
    if [[ "$SHELL" != *"zsh"* ]]; then
      print_step "Setting zsh as default shell..."
      chsh -s $(which zsh)
      print_warning "Default shell changed to zsh. Please log out and log back in for this to take effect."
      add_manual_step "Log out and log back in to use zsh as your default shell"
    fi

    print_step "Updating apt repositories..."
    sudo apt update
    print_success "Package manager updated"
    ;;
  arch)
    print_header "Package Manager Setup"

    # Install zsh if not present
    if ! command_exists zsh; then
      print_step "Installing zsh..."
      sudo pacman -Sy --noconfirm zsh
      print_success "zsh installed"
    else
      print_success "zsh already installed"
    fi

    # Set zsh as default shell if not already
    if [[ "$SHELL" != *"zsh"* ]]; then
      print_step "Setting zsh as default shell..."
      chsh -s $(which zsh)
      print_warning "Default shell changed to zsh. Please log out and log back in for this to take effect."
      add_manual_step "Log out and log back in to use zsh as your default shell"
    fi

    print_step "Updating pacman repositories..."
    sudo pacman -Sy
    print_success "Package manager updated"
    ;;
  esac
}

# ============================================================================
# Install Packages
# ============================================================================

install_packages() {
  print_header "Installing Packages"

  case "$OS" in
  macos)
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
      skhd
      starship
      stow
      yabai
      zoxide
    )

    local brew_casks=(
      font-caskaydia-cove-nerd-font
      font-sf-pro
      ghostty
      localsend
    )

    print_step "Installing Homebrew packages..."
    for package in "${brew_packages[@]}"; do
      if brew list "$package" &>/dev/null; then
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
    ;;

  ubuntu)
    local apt_packages=(
      btop
      cmatrix
      cowsay
      eza
      fastfetch
      fd-find
      ffmpeg
      fzf
      gh
      git
      gnupg
      imagemagick
      neovim
      ripgrep
      shfmt
      stow
      zoxide
    )

    print_step "Installing apt packages..."
    sudo apt install -y "${apt_packages[@]}"

    # Install mise (not in standard repos)
    if ! command_exists mise; then
      print_step "Installing mise..."
      curl https://mise.run | sh
      echo 'eval "$(~/.local/bin/mise activate zsh)"' >>~/.zshrc
    fi

    # Install starship (not in standard repos)
    if ! command_exists starship; then
      print_step "Installing starship..."
      curl -sS https://starship.rs/install.sh | sh -s -- -y
    fi

    # Install lazygit (not in standard repos)
    if ! command_exists lazygit; then
      print_step "Installing lazygit..."
      LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": "v\K[^"]*')
      curl -Lo /tmp/lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz"
      tar xf /tmp/lazygit.tar.gz -C /tmp lazygit
      sudo install /tmp/lazygit /usr/local/bin
    fi
    ;;

  arch)
    local pacman_packages=(
      btop
      cmatrix
      cowsay
      eza
      fastfetch
      fd
      ffmpeg
      fzf
      github-cli
      git
      gnupg
      imagemagick
      lazygit
      neovim
      ripgrep
      shfmt
      starship
      stow
      zoxide
    )

    print_step "Installing pacman packages..."
    sudo pacman -S --needed --noconfirm "${pacman_packages[@]}"

    # Install mise from AUR if available
    if ! command_exists mise; then
      if command_exists yay; then
        print_step "Installing mise from AUR..."
        yay -S --noconfirm mise-bin
      elif command_exists paru; then
        print_step "Installing mise from AUR..."
        paru -S --noconfirm mise-bin
      else
        print_step "Installing mise..."
        curl https://mise.run | sh
        echo 'eval "$(~/.local/bin/mise activate zsh)"' >>~/.zshrc
      fi
    fi
    ;;
  esac

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

  print_step "Loading shell configuration..."
  (source ~/.zshrc) 2>/dev/null || print_warning "Some shell config couldn't be loaded in script context"

  print_success "Dotfiles configured"
}

# ============================================================================
# Apply Wallpaper (macOS only)
# ============================================================================

apply_wallpaper() {
  if [[ "$OS" != "macos" ]]; then
    return
  fi

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
# Install Übersicht and simple-bar (macOS only)
# ============================================================================

setup_uebersicht() {
  if [[ "$OS" != "macos" ]]; then
    return
  fi

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

  local dev_dir="$HOME/dev"

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
# Install simple-bar-server (macOS only)
# ============================================================================

setup_simplebar_server() {
  if [[ "$OS" != "macos" ]]; then
    return
  fi

  print_step "Setting up simple-bar-server..."

  local server_dir="$HOME/dev/simple-bar-server"

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

  if [[ -f "$pm2_plist" ]]; then
    print_success "pm2 startup already configured"
  else
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
  fi

  cd ~
}

# ============================================================================
# Yabai Configuration (macOS only)
# ============================================================================

setup_yabai() {
  if [[ "$OS" != "macos" ]]; then
    return
  fi

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
}

# ============================================================================
# Install Banana Cursor
# ============================================================================

install_banana_cursor() {
  print_header "Banana Cursor Setup"

  case "$OS" in
  macos)
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
    ;;

  ubuntu | arch)
    local cursor_installed=false

    if [[ -d "/usr/share/icons/Banana" ]]; then
      print_success "Banana cursor already installed"
      cursor_installed=true
    else
      print_step "Downloading Banana cursor..."
      local tmp_dir=$(mktemp -d)
      cd "$tmp_dir"
      wget -q https://github.com/ful1e5/banana-cursor/releases/download/v2.0.0/Banana.tar.xz

      print_step "Extracting cursor files..."
      tar -xf Banana.tar.xz

      print_step "Installing cursor..."
      sudo mv Banana /usr/share/icons/

      cd ~
      rm -rf "$tmp_dir"
      print_success "Banana cursor installed"
    fi

    # Install gnome-tweaks for cursor configuration
    if [[ "$OS" == "ubuntu" ]]; then
      if ! command_exists gnome-tweaks; then
        print_step "Installing GNOME Tweaks..."
        sudo apt update
        sudo apt install -y gnome-tweaks
        print_success "GNOME Tweaks installed"
      else
        print_success "GNOME Tweaks already installed"
      fi

      add_manual_step "Configure Banana cursor:
    1. Open GNOME Tweaks: gnome-tweaks
    2. Go to: Appearance > Cursor > Select 'Banana'
    3. (Optional) In Settings app: Accessibility > Cursor Size > Large for a bigger banana"
    elif [[ "$OS" == "arch" ]]; then
      if ! command_exists gnome-tweaks; then
        print_step "Installing GNOME Tweaks..."
        sudo pacman -S --needed --noconfirm gnome-tweaks
        print_success "GNOME Tweaks installed"
      else
        print_success "GNOME Tweaks already installed"
      fi

      add_manual_step "Configure Banana cursor:
    1. Open GNOME Tweaks: gnome-tweaks
    2. Go to: Appearance > Cursor > Select 'Banana'
    3. (Optional) In Settings app: Accessibility > Cursor Size > Large for a bigger banana"
    fi
    ;;
  esac
}

# ============================================================================
# Finalize Setup
# ============================================================================

finalize_setup() {
  print_header "Finalizing Setup"

  print_step "Reloading shell configuration..."
  (source ~/.zshrc) 2>/dev/null || print_warning "Some shell config couldn't be loaded in script context"

  print_success "Shell configuration updated and loaded"
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
  fi
}

# Run main function
main
