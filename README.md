# Claude Hooks 🪝

A collection of security-focused hooks for Claude Code using Nix, featuring Telegram notifications and command filtering.

## Features

- **🔔 Telegram Notifications** - Get notified when Claude tasks complete, errors occur, or await input
- **🛡️ Security Hooks** - Block access to sensitive files like `.env` and dangerous commands
- **📦 Nix Integration** - Reproducible builds and easy deployment across machines

## Quick Start

### Remote Usage (No Clone Required)

```bash
# Test notification
echo '{"hook_event_name": "Stop", "session_id": "test123"}' | nix run --refresh github:CaptainKranch/Claude-Hooks#notification

# Use other hooks
nix run --refresh github:CaptainKranch/Claude-Hooks#dangerous-commands
nix run --refresh github:CaptainKranch/Claude-Hooks#git-hook
```

### Local Development

```bash
git clone https://github.com/CaptainKranch/Claude-Hooks
cd Claude-Hooks
nix develop
```

## Configuration

### Telegram Setup

1. Create a `.env` file (use `.env.sample` as template):
```bash
CLAUDE_TELEGRAM_BOT_TOKEN=your_bot_token
CLAUDE_TELEGRAM_CHAT_ID=your_chat_id
```

2. Test your setup:
```bash
echo '{"hook_event_name": "Stop", "session_id": "test"}' | nix run .#notification
```

### Available Hooks

- `notification` - Telegram/Slack notifications for Claude events
- `dangerous-commands` - Blocks risky commands and file access
- `git-hook` - Git workflow automation
- `test` - Testing utilities

## Requirements

- Nix (with flakes enabled)
- Telegram bot token and chat ID for notifications

## License

MIT