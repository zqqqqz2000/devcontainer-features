#!/bin/sh
set -e

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

# Detect os
. ./detectos.sh

username=$USER

check_command sudo sudo sudo sudo
check_command bash bash bash bash

# Create or update a non-root user to match UID/GID.
if [ "${CREATE_USER}" != "ignore" ]; then
  if [ "${ADJUSTED_ID}" = "alpine" ]; then
    apk add shadow
  fi
  groupname="${CREATE_USER}"
  username="${CREATE_USER}"
  echo "Creating or updating user '$username' with GID '$USER_GID' and UID '$USER_UID'..."
  if id -u ${username} >/dev/null 2>&1; then
    # User exists, update if needed
    echo "User exists, updating..."
    if [ "${USER_GID}" != "automatic" ] && [ "$USER_GID" != "$(id -g $username)" ]; then
      groupname="$(id -gn $username)"
      groupmod --gid $USER_GID ${groupname}
      usermod --gid $USER_GID $username
    fi
    if [ "${USER_UID}" != "automatic" ] && [ "$USER_UID" != "$(id -u $username)" ]; then
      usermod --uid $USER_UID $username
    fi
  else
    # Create user
    echo "User does not exist, creating..."
    if [ "${USER_GID}" = "automatic" ]; then
      groupadd $username
    else
      groupadd --gid $USER_GID $username
    fi
    if [ "${USER_UID}" = "automatic" ]; then
      useradd -s /bin/bash --gid $username -m $username
    else
      useradd -s /bin/bash --uid $USER_UID --gid $username -m $username
    fi
  fi
  # Add add sudo support for non-root user
  echo $username ALL=\(root\) NOPASSWD:ALL >/etc/sudoers.d/$username
  chmod 0440 /etc/sudoers.d/$username
fi

cp -r dotfile/. ~/
rm -r ~/.git
cp -r dotfile /tmp/

# Copy dotfile to home
su -l $username -c '
  cp -r /tmp/dotfile/. ~/
  rm -r ~/.git
'

install_gh() {
  GH_REPO="https://cli.github.com/packages/rpm/gh-cli.repo"
  if type dnf >/dev/null 2>&1; then
    dnf config-manager --add-repo $GH_REPO
  elif type yum >/dev/null 2>&1; then
    yum-config-manager --add-repo $GH_REPO
  fi
  check_command gh gh "github-cli" gh
}

install_lazygit() {
  LAZYGIT_VERSION="0.44.1"
  curl -Lo lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/download/v${LAZYGIT_VERSION}/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz"
  tar xf lazygit.tar.gz lazygit
  rm lazygit.tar.gz
  install lazygit /usr/local/bin
}

echo "installing utils"
check_command gcc gcc "build-base" "devtoolset-8-gcc"
check_command unzip unzip unzip unzip
check_command bat bat bat bat
check_command curl "curl ca-certificates" "curl ca-certificates" "curl ca-certificates"
check_command wget wget wget wget
check_command nc netcat-openbsd netcat-openbsd nc
check_command socat socat socat socat
check_command htop htop htop htop
check_command xargs findutils findutils findutils
check_command git git git git
check_command xz xz-utils xz xz
check_command chsh chsh shadow util-linux-user
check_command bash bash bash bash
check_command xclip xclip xclip xclip

if [ "${ADJUSTED_ID}" = "alpine" ]; then
  # for the reason alpine grep/tar is from busybox
  apk add tar
  # not support -P option
  apk add grep
fi

install_gh

# check token if set
if [ -n "${GITHUB_AUTH_TOKEN}" ]; then
  echo config github cli with copilot
  su -l $username -c "
    echo ${GITHUB_AUTH_TOKEN} | gh auth login --with-token
    gh extension install github/gh-copilot
  "
fi

if [ "${ENABLE_ZSH}" = "true" ]; then
  echo "configuring zsh"
  check_command zsh zsh zsh zsh

  # this will failure on alpine
  chsh -s $(which zsh) ${username} || true
  su -l $username -c '
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
    cp /tmp/dotfile/.zshrc ~/.zshrc
    zsh -c "git clone https://github.com/jeffreytse/zsh-vi-mode ~/.oh-my-zsh/custom/plugins/zsh-vi-mode"
  '
fi

if [ "${ENABLE_TMUX}" = "true" ]; then
  echo "configuring tmux"
  check_command tmux tmux tmux tmux
  check_command rg ripgrep ripgrep ripgrep

  su -l $username -c "
    git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
    # start a server but don't attach to it
    tmux start-server
    # create a new session but don't attach to it either
    tmux new-session -d
    # install the plugins
    ~/.tmux/plugins/tpm/scripts/install_plugins.sh
    # killing the server is not required, I guess
    tmux kill-server
  "
fi

if [ "${ENABLE_NEOVIM}" = "true" ]; then
  echo "configuring neovim"
  install_lazygit
  curl -LO https://github.com/neovim/neovim/releases/download/v0.10.1/nvim-linux64.tar.gz
  rm -rf /opt/nvim
  tar -C /opt -xzf nvim-linux64.tar.gz
  rm nvim*.tar.gz

  if [ "${USER}" = "${username}" ]; then
    echo 'export PATH="$PATH:/opt/nvim-linux64/bin"' >>~/.zshrc
    echo 'export PATH="$PATH:/opt/nvim-linux64/bin"' >>~/.bashrc
  else
    echo 'export PATH="$PATH:/opt/nvim-linux64/bin"' >>/home/${username}/.zshrc
    echo 'export PATH="$PATH:/opt/nvim-linux64/bin"' >>/home/${username}/.bashrc
  fi

  # Retry to ensure veovim install all plugins success
  su -l $username -c "
    /opt/nvim-linux64/bin/nvim --headless -c 'lua require("lazy").install({ wait = true, show = false, concurrency = 20 })' +qa &&
      /opt/nvim-linux64/bin/nvim --headless -c 'lua require("lazy").update({ wait = true, show = false, concurrency = 20 })' +qa &&
      /opt/nvim-linux64/bin/nvim --headless -c 'lua require("lazy").update({ wait = true, show = false, concurrency = 20 })' +qa &&
      /opt/nvim-linux64/bin/nvim --headless -c 'lua require("lazy").update({ wait = true, show = false, concurrency = 20 })' +qa &&
      /opt/nvim-linux64/bin/nvim --headless -c 'lua require("lazy").update({ wait = true, show = false, concurrency = 20 })' +qa
  "
fi
