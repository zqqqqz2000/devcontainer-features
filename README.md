# AIO devcontainer feature

Install basic devtools and tmux/neovim/zsh with basic configure.

Currently support alpine/debian based image.

## Example Usage

```bash
npm install -g @devcontainers/cli
```

All default value is true, `.devcontainer/devcontainer.json`:

```json
{
  "features": {
    "https://github.com/zqqqqz2000/devcontainer-features/releases/download/1.0.1/devcontainer-feature-allinone.tgz": {
      "enable_neovim": false,
      "enable_zsh": false,
      "enable_tmux": false
    }
  }
}
```

```bash
devcontainer up --workspace-folder .
devcontainer exec --workspace-folder . zsh
```
