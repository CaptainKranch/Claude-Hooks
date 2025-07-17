# Team Setup Guide

## For Your Team (with Silencer access)

### Initial Setup
```bash
# Clone with submodules
git clone --recursive git@github.com:CaptainKranch/Claude-Hooks.git
cd Claude-Hooks

# Test it works
echo '{"hook_event_name": "Stop", "session_id": "test"}' | nix run .#notification
```

### Daily Use
When working locally, the Silencer submodule automatically provides credentials:
```bash
cd Claude-Hooks
nix run .#notification  # Just works!
```

## For Claude Code Integration

Unfortunately, you **cannot** use the Silencer submodule with remote `nix run` commands. You have two options:

### Option 1: Team-wide Environment Variables
Add to your shell profile (`.bashrc` or `.zshrc`):
```bash
export CLAUDE_TELEGRAM_BOT_TOKEN="your_shared_token"
export CLAUDE_TELEGRAM_CHAT_ID="your_shared_chat_id"
```

Then in Claude Code settings:
```json
{
  "hooks": {
    "Notification": [{
      "hooks": [{
        "type": "command",
        "command": "nix run github:CaptainKranch/Claude-Hooks#notification"
      }]
    }]
  }
}
```

### Option 2: Local Repository Path
Clone the repo once and use local path:
```json
{
  "hooks": {
    "Notification": [{
      "hooks": [{
        "type": "command",
        "command": "nix run /path/to/Claude-Hooks#notification"
      }]
    }]
  }
}
```

## Why This Limitation Exists

- Nix cannot initialize private git submodules during remote execution
- The Silencer repo requires authentication that Nix doesn't have
- This is a fundamental security feature of Nix, not a bug

## Future Corporate Solution

When you're ready to deploy company-wide without manual env vars, we can:
1. Use NixOS + agenix to deploy secrets to `/run/agenix/`
2. Update the flake to check these standard locations
3. Everyone gets zero-configuration `nix run` that just works

But for now, environment variables are the simplest solution.