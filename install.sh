#!/bin/bash
set -e
FEATURE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "${FEATURE_DIR}"

# Default options
ENABLE_NEOVIM="${NEOVIM:-"true"}"
ENABLE_ZSH="${ZSH:-"true"}"
ENABLE_TMUX="${TMUX:-"true"}"

if [ "$(id -u)" -ne 0 ]; then
  echo -e 'Script must be run as root. Use sudo, su, or add "USER root" to your Dockerfile before running this script.'
  exit 1
fi

# Import common utils
. ./utils.sh

# Copy dotfile to home
cp -r dotfile/* ~/
rm -r ~/.git

apt_get_update_if_exists

echo "installing utils"
check_command unzip unzip unzip unzip
check_command bat bat bat bat
check_command curl "curl ca-certificates" "curl ca-certificates" "curl ca-certificates"
check_command wget wget wget wget
check_command netcat netcat netcat netcat
check_command socat socat socat socat
check_command htop htop htop htop
check_command xargs findutils findutils findutils
check_command git git git git
check_command xz xz-utils xz xz

if [ "${ENABLE_NEOVIM}" == "true" ]; then
  echo "configuring neovim"
  check_command neovim
  # Retry to ensure veovim install all plugins success
  nvim --headless -c 'lua require("lazy").install({ wait = true, show = false, concurrency = 20 })' +qa &&
    nvim --headless -c 'lua require("lazy").update({ wait = true, show = false, concurrency = 20 })' +qa &&
    nvim --headless -c 'lua require("lazy").update({ wait = true, show = false, concurrency = 20 })' +qa &&
    nvim --headless -c 'lua require("lazy").update({ wait = true, show = false, concurrency = 20 })' +qa &&
    nvim --headless -c 'lua require("lazy").update({ wait = true, show = false, concurrency = 20 })' +qa
fi

if [ "${ENABLE_ZSH}" == "true" ]; then
  echo "configuring zsh"
  check_command zsh zsh zsh zsh
  chsh -s $(which zsh)
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi

if [ "${ENABLE_TMUX}" == "true" ]; then
  echo "configuring tmux"
  check_command tmux tmux tmux tmux
  git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
  ~/.tmux/plugins/tpm/tpm
  tmux source ~/.tmux.conf
fi
