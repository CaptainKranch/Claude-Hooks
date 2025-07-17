# Architecture: Claude-Hooks + Silencer

## Repository Structure

- **Claude-Hooks** (Public): Contains Python hook scripts for Claude Code
- **Silencer** (Private): Contains encrypted credentials using agenix, added as git submodule

## The Nix Limitation

When running `nix run github:CaptainKranch/Claude-Hooks#notification`, Nix:
1. Clones the repository
2. **Does NOT initialize git submodules**
3. Cannot access private repositories

This is by design for security and reproducibility.

## Solution: Dual-Mode Operation

### Public Users (via `nix run github:...`)
```bash
export CLAUDE_TELEGRAM_BOT_TOKEN="your_token"
export CLAUDE_TELEGRAM_CHAT_ID="your_chat_id"
nix run github:CaptainKranch/Claude-Hooks#notification
```
- Must provide credentials via environment variables
- Submodule is never accessed

### Your Team (with Silencer access)
```bash
git clone --recursive git@github.com:CaptainKranch/Claude-Hooks.git
cd Claude-Hooks
nix run .#notification
```
- Silencer submodule provides encrypted credentials
- No environment variables needed
- Automatic decryption with your SSH keys

## Why This Works

1. **Security**: Credentials stay in private Silencer repo
2. **Simplicity**: Public users just set env vars
3. **Convenience**: Your team gets automatic credential handling
4. **Open Source**: Public repo remains credential-free

This is the standard pattern for open source projects with private credentials.