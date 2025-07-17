# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Common Commands

### Development Environment
```bash
# Enter development environment with all dependencies
nix develop

# Run individual hooks locally
nix run .#notification
nix run .#dangerous-commands
nix run .#git-hook

# Run hooks remotely without cloning
nix run --refresh github:CaptainKranch/Claude-Hooks#notification
```

### Testing & Validation
```bash
# Test notification system with JSON input
echo '{"hook_event_name": "Stop", "session_id": "test123"}' | nix run .#notification

# Test dangerous commands hook
echo '{"hook_event_name": "PreToolUse", "args": {"tool": "Bash", "command": "rm -rf /"}}' | nix run .#dangerous-commands

# Run Python scripts directly (in nix develop shell)
python scripts/notifications.py
python scripts/dangerous_commands.py
python scripts/git_hook.py
```

### Configuration
```bash
# Set up Telegram credentials (option 1: environment variables)
export CLAUDE_TELEGRAM_BOT_TOKEN="your_bot_token"
export CLAUDE_TELEGRAM_CHAT_ID="your_chat_id"

# Create encrypted secrets (option 2: for repository owners)
nix run .#create-telegram-secrets
```

## High-Level Architecture

### Security-First Hook System
This codebase implements a security-focused hooks system for Claude Code that intercepts events to:
- **Notify**: Send real-time notifications to Telegram/Slack when Claude completes tasks, encounters errors, or awaits input
- **Protect**: Block dangerous commands (rm -rf patterns) and prevent access to sensitive files (.env)
- **Audit**: Log all tool usage and notification events for security monitoring

### Nix-Based Architecture
The entire system is built on Nix flakes, providing:
- **Reproducible builds** across all machines without manual dependency management
- **Remote execution** capability - users can run hooks directly from GitHub without cloning
- **Encrypted secrets management** via age encryption with SSH keys

### Event Processing Flow
1. Claude Code emits JSON events to stdin (hook_event_name, session_id, args)
2. Hook scripts parse events and apply security policies or send notifications
3. Dangerous operations return exit code 2 to block execution
4. All events are logged to `logs/` directory for auditing

### Key Design Decisions
- **Stateless hooks**: Each invocation is independent, relying only on environment configuration
- **Multi-platform notifications**: Supports both Telegram and Slack with automatic fallback
- **Flexible configuration**: Supports env vars, .env files, or encrypted secrets
- **Non-blocking by default**: Most hooks provide guidance without preventing operations (except security hooks)

### Integration with Claude Code
Hooks are configured in Claude Code settings JSON and receive events via stdin. The notification hook monitors task lifecycle events while the dangerous-commands hook intercepts tool usage for security filtering.