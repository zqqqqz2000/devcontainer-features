#!/bin/bash
set -e
FEATURE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "${FEATURE_DIR}"

# Default options
ENABLE_NEOVIM="${ENABLE_NEOVIM:-"true"}"
ENABLE_ZSH="${ENABLE_ZSH:-"true"}"
ENABLE_TMUX="${ENABLE_TMUX:-"true"}"

if [ "$(id -u)" -ne 0 ]; then
  echo -e 'Script must be run as root. Use sudo, su, or add "USER root" to your Dockerfile before running this script.'
  exit 1
fi

# Import common utils
. ./utils.sh

# Copy dotfile to home
cp -r dotfile/. ~/
rm -r ~/.git

apt_get_update_if_exists

echo "installing utils"
check_command gcc "build-base" gcc "devtoolset-8-gcc"
check_command unzip unzip unzip unzip
check_command bat bat bat bat
check_command curl "curl ca-certificates" "curl ca-certificates" "curl ca-certificates"
check_command wget wget wget wget
check_command netcat-openbsd netcat-openbsd netcat netcat
check_command socat socat socat socat
check_command htop htop htop htop
check_command xargs findutils findutils findutils
check_command git git git git
check_command xz xz-utils xz xz

if [ "${ENABLE_ZSH}" == "true" ]; then
  echo "configuring zsh"
  check_command zsh zsh zsh zsh
  chsh -s $(which zsh)
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
  cp dotfile/.zshrc ~/.zshrc
  zsh -c 'git clone https://github.com/jeffreytse/zsh-vi-mode ~/.oh-my-zsh/custom/plugins/zsh-vi-mode'
fi

if [ "${ENABLE_TMUX}" == "true" ]; then
  echo "configuring tmux"
  check_command tmux tmux tmux tmux
  git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
  # start a server but don't attach to it
  tmux start-server
  # create a new session but don't attach to it either
  tmux new-session -d
  # install the plugins
  ~/.tmux/plugins/tpm/scripts/install_plugins.sh
  # killing the server is not required, I guess
  tmux kill-server
fi

if [ "${ENABLE_NEOVIM}" == "true" ]; then
  echo "configuring neovim"
  curl -LO https://github.com/neovim/neovim/releases/download/v0.10.1/nvim-linux64.tar.gz
  rm -rf /opt/nvim
  tar -C /opt -xzf nvim-linux64.tar.gz
  rm nvim*.tar.gz
  if [ "${ENABLE_ZSH}" == "true" ]; then
    echo 'export PATH="$PATH:/opt/nvim-linux64/bin"' >>~/.zshrc
  else
    echo 'export PATH="$PATH:/opt/nvim-linux64/bin"' >>~/.bashrc
  fi
  export PATH="$PATH:/opt/nvim-linux64/bin"
  # Retry to ensure veovim install all plugins success
  nvim --headless -c 'lua require("lazy").install({ wait = true, show = false, concurrency = 20 })' +qa &&
    nvim --headless -c 'lua require("lazy").update({ wait = true, show = false, concurrency = 20 })' +qa &&
    nvim --headless -c 'lua require("lazy").update({ wait = true, show = false, concurrency = 20 })' +qa &&
    nvim --headless -c 'lua require("lazy").update({ wait = true, show = false, concurrency = 20 })' +qa &&
    nvim --headless -c 'lua require("lazy").update({ wait = true, show = false, concurrency = 20 })' +qa
fi
