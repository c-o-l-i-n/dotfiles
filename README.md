<p align="center">
  <img src="https://dotfiles.github.io/images/dotfiles-logo.png" height="72" />
</p>

<p align="center">
  <i>My personal configuration files for macOS.</i>
</p>

## Quick Start

Clone this repository and run the setup script:

```sh
git clone https://github.com/c-o-l-i-n/dotfiles ~/dotfiles
cd ~/dotfiles
./setup.sh
```

## What It Does

The setup script automatically:

- Installs Homebrew
- Installs essential packages and tools
- Links dotfiles using GNU Stow
- Sets up Node.js via mise
- Installs the Banana cursor theme
- Configures Übersicht and simple-bar
- Sets up yabai window manager
- Configures Mousecape for custom cursors
- Applies desktop wallpaper

The script is safe to run multiple times. It will skip steps that are already completed and only perform necessary configuration.

## Manual Steps

Some features require manual configuration after running the script. The script will display a list of any required manual steps at the end.
