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

# $0 is the function name inside functions, so resolve the script dir here
SCRIPT_DIR="${0:A:h}"

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
# Ask for the sudo password once, up front, only if a later step needs it
# ============================================================================

acquire_sudo_if_needed() {
  if command_exists brew &&
    brew bundle check --no-upgrade --file="$SCRIPT_DIR/Brewfile" &>/dev/null &&
    [[ -f "$HOME/Library/LaunchAgents/pm2.$(whoami).plist" ]] &&
    ! yabai_needs_patch &&
    yabai_sudoers_ok; then
    return
  fi

  print_step "Some steps need administrator access. Enter your password once now:"
  sudo -v
  while kill -0 $$ 2>/dev/null; do
    sudo -n true
    sleep 50
  done 2>/dev/null &
}

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

  export HOMEBREW_NO_AUTO_UPDATE=1
  export HOMEBREW_NO_ENV_HINTS=1

  if brew bundle install --no-upgrade --file="$SCRIPT_DIR/Brewfile"; then
    print_success "All packages installed"
  else
    print_warning "Some Brewfile entries failed to install"
    add_manual_step "Sign in to the App Store if you haven't (mas needs it), then rerun: brew bundle install --file=\"$SCRIPT_DIR/Brewfile\""
  fi
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
  # Without a real ~/.config, stow links the whole directory into this repo and
  # every app's credentials and state land in the working tree
  mkdir -p "$HOME/.config"
  local diff_before=$(git diff | shasum)
  stow --adopt --restow .

  if [[ "$(git diff | shasum)" != "$diff_before" ]]; then
    print_warning "Some live config files had drifted from the repo"
    add_manual_step "Review drifted config with: git -C ~/dotfiles diff
    Commit what you want to keep, then discard the rest with: git -C ~/dotfiles checkout ."
  fi

  local signing_key=$(git config --global user.signingkey)
  if ! gpg --list-secret-keys "$signing_key" &>/dev/null; then
    print_warning "GPG signing key $signing_key not found"
    add_manual_step "Import GPG key $signing_key (git commits are signed and will fail until it is): gpg --import <key file>"
  fi

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

setup_mise_tools() {
  print_step "Installing mise tools..."
  mise install
  eval "$(mise activate zsh)"
  print_success "mise tools installed"
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
# Patch yabai for macOS 27
# ============================================================================

yabai_patch_applies() {
  command_exists yabai &&
    [[ "$(sw_vers -productVersion | cut -d. -f1)" == 27 ]] &&
    [[ "$(yabai --version)" == yabai-v7.1.25 ]]
}

yabai_is_patched() {
  grep -qa "Golden Gate" "$(brew --prefix asmvik/formulae/yabai)/bin/yabai"
}

yabai_needs_patch() {
  yabai_patch_applies && ! yabai_is_patched
}

# A release supports macOS 27 once its payload accepts major version 27,
# which is the check the local patch adds
check_yabai_upstream() {
  local tag
  tag=$(curl -fsS --max-time 5 https://api.github.com/repos/asmvik/yabai/releases/latest 2>/dev/null |
    python3 -I -c 'import json, sys; print(json.load(sys.stdin)["tag_name"])' 2>/dev/null) || return 0

  if curl -fsS --max-time 5 "https://raw.githubusercontent.com/asmvik/yabai/$tag/src/osax/payload.m" 2>/dev/null |
    grep -qE 'majorVersion (==|>=) 27'; then
    print_success "yabai $tag supports macOS 27"
    add_manual_step "yabai $tag supports macOS 27, so the local patch is no longer needed:
    brew unpin asmvik/formulae/yabai && brew upgrade asmvik/formulae/yabai
    Then rerun setup.sh, and remove patches/ and the patch step from the dotfiles"
  fi
}

patch_yabai() {
  print_header "yabai macOS 27 Patch"

  if ! yabai_patch_applies; then
    print_success "No patch needed ($(yabai --version))"
    return
  fi

  check_yabai_upstream

  if ! python3 -I "$SCRIPT_DIR/patches/scan_dock.py" "$SCRIPT_DIR/patches/yabai-macos27.patch"; then
    print_warning "The yabai patch no longer matches this Mac's Dock"
    add_manual_step "A macOS update moved the Dock code the yabai patch hooks, so yabai can't switch spaces.
    Look for an updated patch: https://github.com/asmvik/yabai/issues/2832"
    return
  fi

  if yabai_is_patched; then
    print_success "yabai already patched"
    return
  fi

  local yabai_bin="$(brew --prefix asmvik/formulae/yabai)/bin/yabai"

  print_step "Building patched yabai..."
  local build_dir=$(mktemp -d)
  git clone --quiet https://github.com/asmvik/yabai.git "$build_dir"
  git -C "$build_dir" checkout --quiet dd845723416f5fe92af49fad5ebab00369e07edd
  git -C "$build_dir" apply "$SCRIPT_DIR/patches/yabai-macos27.patch"
  make -C "$build_dir" -j1 install
  codesign -fs - "$build_dir/bin/yabai"
  install -m 555 "$build_dir/bin/yabai" "$yabai_bin"
  rm -rf "$build_dir"

  brew pin asmvik/formulae/yabai
  print_success "Patched yabai installed and pinned"
  add_manual_step "yabai was rebuilt, so macOS dropped its permission to control the computer.
    In System Settings > Privacy & Security > Device Control and Data Access, remove old yabai rows and add $(realpath "$yabai_bin")"
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
  if yabai_sudoers_ok; then
    print_success "yabai sudoers entry already up to date"
    return
  fi

  print_step "Configuring yabai sudoers entry..."
  local yabai_path=$(which yabai)
  local yabai_sha=$(shasum -a 256 "$yabai_path" | cut -d " " -f 1)
  local sudoers_entry="$(whoami) ALL=(root) NOPASSWD: sha256:${yabai_sha} ${yabai_path} --load-sa"
  local sudoers_file="/private/etc/sudoers.d/yabai"
  local sudoers_tmp=$(mktemp)

  echo "$sudoers_entry" >"$sudoers_tmp"
  sudo visudo -cqf "$sudoers_tmp"
  sudo install -m 0440 -o root -g wheel "$sudoers_tmp" "$sudoers_file"
  rm "$sudoers_tmp"
  print_success "yabai sudoers entry configured"
}

# sudo -n prints this instead of prompting when no NOPASSWD rule matches.
# yabai's own exit code can't tell us, since --load-sa exits 1 on macOS 27
# even when the load works.
yabai_sudoers_ok() {
  command_exists yabai &&
    [[ "$(stat -f %Lp /private/etc/sudoers.d/yabai 2>/dev/null)" == 440 ]] &&
    ! LC_ALL=C sudo -n "$(command -v yabai)" --load-sa 2>&1 | grep -q "a password is required"
}

# ============================================================================
# Start Window Management Services (yabai + skhd)
# ============================================================================

start_window_management_services() {
  print_header "Window Management Services (yabai + skhd)"

  print_step "Starting yabai and skhd..."
  yabai --start-service 2>/dev/null || true
  skhd --start-service 2>/dev/null || true

  if wait_for_window_management; then
    print_success "yabai and skhd are running"
    return
  fi

  # Both abort at launch without this permission, so not running means not granted
  open "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
  echo ""
  echo -e "${YELLOW}${BOLD}Action Required: Device Control and Data Access${RESET}"
  echo -e "${YELLOW}yabai and skhd need this permission to manage windows and hotkeys.${RESET}"
  echo ""
  echo -e "${BLUE}Steps:${RESET}"
  echo -e "  1. In ${BOLD}System Settings > Privacy & Security > Device Control and Data Access${RESET} (now open)"
  echo -e "     enable both ${BOLD}yabai${RESET} and ${BOLD}skhd${RESET}"
  echo -e "  2. Press ${BOLD}Enter${RESET} to restart the services"
  echo ""
  read -r "?Press Enter after granting access... "
  echo ""

  yabai --restart-service 2>/dev/null || true
  skhd --restart-service 2>/dev/null || true

  if wait_for_window_management; then
    print_success "yabai and skhd are running"
  else
    print_warning "yabai or skhd still isn't running"
    add_manual_step "Check System Settings > Privacy & Security > Device Control and Data Access for yabai and skhd, then run: yabai --restart-service; skhd --restart-service"
  fi
}

wait_for_window_management() {
  local tries
  for tries in {1..5}; do
    if yabai -m query --spaces &>/dev/null && pgrep -x skhd >/dev/null; then
      return 0
    fi
    sleep 1
  done
  return 1
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

    xattr -d com.apple.quarantine "$mousecape_app" 2>/dev/null || true

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

    local cape="$dotfiles_capes_dir/local.Colin.Banana.cape"
    local mousecloak="$mousecape_app/Contents/MacOS/mousecloak"

    defaults write com.sdmj76.Mousecape applyLastCapeOnLaunch -bool true
    defaults write com.sdmj76.Mousecape lastAppliedCapeIdentifier local.Colin.Banana

    print_step "Applying Banana cursor..."
    "$mousecloak" --apply "$cape" >/dev/null
    if cape_is_applied "$mousecloak" "$cape"; then
      print_success "Banana cursor applied"
    else
      print_warning "Banana cursor did not apply"
      add_manual_step "Open Mousecape and select the Banana cursor"
    fi

    if launchctl list com.sdmj76.mousecloakhelper &>/dev/null; then
      print_success "Mousecape helper running"
    else
      add_manual_step "Open Mousecape > Settings > General and install Mousecape Helper, so the Banana cursor comes back after you log in"
    fi
  else
    print_warning "Mousecape not installed"
    add_manual_step "Install Mousecape from: https://github.com/sdmj76/Mousecape-swiftUI/releases/latest
    Then run this script again to configure the capes symlink"
  fi
}

# The dump names its cursors generically, so compare each cursor's frame count,
# hotspot, and size against the cape instead of its name
cape_is_applied() {
  local mousecloak=$1 cape=$2
  local dump_dir=$(mktemp -d)
  "$mousecloak" --dump "$dump_dir/current.cape" >/dev/null
  python3 -I - "$cape" "$dump_dir/current.cape" <<'EOF'
import plistlib, sys
def metrics(path):
    cursors = plistlib.load(open(path, "rb"))["Cursors"]
    return {name: [c.get(k) for k in ("FrameCount", "HotSpotX", "HotSpotY", "PointsWide", "PointsHigh")] for name, c in cursors.items()}
cape, live = metrics(sys.argv[1]), metrics(sys.argv[2])
sys.exit(0 if all(live.get(name) == m for name, m in cape.items()) else 1)
EOF
  local result=$?
  rm -rf "$dump_dir"
  return $result
}

# ============================================================================
# Finalize Setup
# ============================================================================

finalize_setup() {
  print_header "Finalizing Setup"

  print_success "Run exec zsh to load the new shell configuration in this terminal"
}

# ============================================================================
# Main Execution
# ============================================================================

main() {
  print_header "Setup Starting..."

  acquire_sudo_if_needed
  install_package_manager
  install_packages
  setup_dotfiles
  apply_wallpaper
  setup_uebersicht
  create_dev_directory
  setup_mise_tools
  setup_simplebar_server
  patch_yabai
  setup_yabai
  start_window_management_services
  install_banana_cursor
  finalize_setup

  # ============================================================================
  # Summary
  # ============================================================================

  print_header "Setup Complete!"

  if [[ ${#MANUAL_STEPS[@]} -gt 0 ]]; then
    echo -e "${YELLOW}${BOLD}Manual Steps:${RESET}\n"
    local i=1
    for step in "${MANUAL_STEPS[@]}"; do
      echo -e "${MAGENTA}${i}.${RESET} ${step}\n"
      ((i++))
    done
  else
    print_success "No manual steps!"
    echo -e "${CYAN}${BOLD}╔════════════════════════════════════════════════════════════════╗${RESET}"
    printf "${CYAN}${BOLD}║  %-62s║${RESET}\n" "Your system is ready!"
    echo -e "${CYAN}${BOLD}╚════════════════════════════════════════════════════════════════╝${RESET}\n"
  fi
}

# Run main function
main
