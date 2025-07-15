# Claude Hooks 🪝

A collection of security-focused hooks for Claude Code using Nix, featuring Telegram notifications, secret scanning, and command filtering.

## Features

- **🔔 Telegram Notifications** - Get notified when Claude tasks complete, errors occur, or await input
- **🛡️ Security Hooks** - Block access to sensitive files and dangerous commands
- **🔍 Secret Scanner** - Detect hardcoded secrets before git push
- **🔐 Encrypted Secrets** - Secure credential management with age encryption
- **📦 Nix Integration** - Reproducible builds and easy deployment across machines

## Quick Start

### Remote Usage (No Clone Required)

Set your Telegram credentials and use any hook directly:

```bash
# Set your credentials
export CLAUDE_TELEGRAM_BOT_TOKEN="your_bot_token"
export CLAUDE_TELEGRAM_CHAT_ID="your_chat_id"

# Test notification
echo '{"hook_event_name": "Stop", "session_id": "test123"}' | nix run --refresh github:CaptainKranch/Claude-Hooks#notification

# Scan for secrets in current directory
nix run --refresh github:CaptainKranch/Claude-Hooks#secret-scanner -- .

# Install git hooks for secret scanning
nix run --refresh github:CaptainKranch/Claude-Hooks#setup-git-hooks -- install

# Use other hooks
nix run --refresh github:CaptainKranch/Claude-Hooks#dangerous-commands
nix run --refresh github:CaptainKranch/Claude-Hooks#git-hook
```

### Local Development with Encrypted Secrets

```bash
# Clone with encrypted secrets (requires access to private submodule)
git clone --recursive git@github.com:CaptainKranch/Claude-Hooks.git
cd Claude-Hooks
nix develop

# Test notification (automatically decrypts secrets)
echo '{"hook_event_name": "Stop", "session_id": "test"}' | nix run .#notification
```

### Local Development without Secrets

```bash
# Clone public repository only
git clone https://github.com/CaptainKranch/Claude-Hooks
cd Claude-Hooks
nix develop

# Use with environment variables
export CLAUDE_TELEGRAM_BOT_TOKEN="your_token"
export CLAUDE_TELEGRAM_CHAT_ID="your_chat_id"
nix run .#notification
```

## Configuration

### Telegram Setup

#### Option 1: Environment Variables (Recommended for Public Use)
```bash
export CLAUDE_TELEGRAM_BOT_TOKEN="your_bot_token"
export CLAUDE_TELEGRAM_CHAT_ID="your_chat_id"
```

#### Option 2: Local .env File
Create a `.env` file (use `.env.sample` as template):
```bash
CLAUDE_TELEGRAM_BOT_TOKEN=your_bot_token
CLAUDE_TELEGRAM_CHAT_ID=your_chat_id
```

#### Option 3: Encrypted Secrets (For Repository Owners)
Secrets are automatically decrypted when cloning with submodules:
```bash
git clone --recursive git@github.com:CaptainKranch/Claude-Hooks.git
```

### Claude Code Integration

Add this to your Claude Code configuration:

```json
{
  "hooks": {
    "Notification": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "nix run --refresh github:CaptainKranch/Claude-Hooks#notification"
          }
        ]
      }
    ]
  }
}
```

### Available Hooks

- `notification` - Telegram/Slack notifications for Claude events
- `dangerous-commands` - Blocks risky commands and file access
- `secret-scanner` - Detects hardcoded secrets before git push
- `setup-git-hooks` - Installs git hooks for secret scanning
- `create-telegram-secrets` - Interactive tool to create encrypted credentials
- `git-hook` - Git workflow automation
- `test` - Testing utilities

### Secret Scanner

The secret scanner detects common secrets like:
- AWS Access Keys & Secret Keys
- GitHub Personal Access Tokens  
- Telegram Bot Tokens
- OpenAI & Anthropic API Keys
- Database Connection Strings
- Private Keys (RSA, SSH, PGP)
- JWT Tokens
- And more...

## Security Features

### Encrypted Secrets
- Credentials are encrypted using age with SSH keys
- Secrets are stored in a private git submodule
- Only authorized SSH keys can decrypt secrets
- Safe to store encrypted secrets in version control

### Secret Scanning
- Pre-push git hooks prevent secret leaks
- Detects 15+ types of common secrets and API keys
- Smart filtering to reduce false positives
- Can be run manually or automatically

### Command Filtering
- Blocks dangerous commands that could expose sensitive data
- Prevents access to files containing credentials
- Configurable security policies

## Architecture

```
Claude-Hooks/ (Public Repository)
├── flake.nix              # Nix flake with all packages
├── scripts/               # Hook implementation scripts
│   ├── notifications.py   # Telegram/Slack notifications
│   ├── secret_scanner.py  # Secret detection engine
│   └── dangerous_commands.py # Command filtering
├── secrets/               # Private submodule (Silencer)
│   ├── telegram-token.age # Encrypted bot token
│   └── telegram-chat-id.age # Encrypted chat ID
└── README.md
```

## Requirements

- **Nix** (with flakes enabled) - For reproducible builds
- **SSH Key** - For secret decryption (if using encrypted secrets)
- **Telegram Bot** - For notifications (optional)

## Contributing

This repository uses encrypted secrets via git submodules. To contribute:

1. Fork the repository
2. Use environment variables for your credentials
3. Test your changes locally
4. Submit a pull request

## License

MIT