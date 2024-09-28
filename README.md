# AIO devcontainer feature

Install basic devtools and tmux/neovim/zsh with basic configure.

Currently support alpine/debian based image.

## Example Usage

```bash
npm install -g @devcontainers/cli
```

`.devcontainer.json` default value:

```json
{
  "features": {
    "https://github.com/zqqqqz2000/devcontainer-features/releases/latest/download/devcontainer-feature-allinone.tgz": {
      "enable_neovim": true,
      "enable_zsh": true,
      "enable_tmux": true,
      "github_auth_token": "",
      "create_user": "dev", // if you don't want to create a new user, set it to "ignore"
      "user_uid": "1000", // if you don't want to set uid, set it to "automatic"
      "user_gid": "1000" // if you don't want to set uid, set it to "automatic"
    }
  }
}
```

```bash
devpod-cli up [--recreate] --ide none .
devpod-cli ssh .
```
