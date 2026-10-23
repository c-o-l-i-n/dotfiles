# vp setup re-appends its own line unless it finds this exact one in this file
if [[ -f "$HOME/.config/vite-plus/env" ]]; then
  . "$HOME/.config/vite-plus/env"
fi
