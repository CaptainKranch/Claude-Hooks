# Admin Guide: Using Claude-Hooks with Silencer Submodule

## The Solution

You CAN use the Silencer submodule with remote `nix run` commands! The key is the `?submodules=1` parameter.

## For Admins (with Silencer access)

### Remote Execution with Submodules
```bash
# This WILL include and decrypt the Silencer submodule!
nix run "github:CaptainKranch/Claude-Hooks?submodules=1#notification"

# You need SSH access to the Silencer repo for this to work
# Make sure your SSH agent has the right keys loaded
ssh-add ~/.ssh/id_ed25519  # Or whichever key has Silencer access
```

### Claude Code Configuration
Add to your `~/.claude/settings.json`:
```json
{
  "hooks": {
    "Notification": [{
      "hooks": [{
        "type": "command",
        "command": "nix run 'github:CaptainKranch/Claude-Hooks?submodules=1#notification'"
      }]
    }]
  }
}
```

## How It Works

1. The `?submodules=1` parameter tells Nix to clone submodules
2. Nix will use your SSH keys to authenticate with the private Silencer repo
3. The flake input `source-with-submodules` provides access to the submodule contents
4. The notification script checks this location and decrypts the secrets

## Requirements

- SSH access to both Claude-Hooks AND Silencer repositories
- SSH agent running with appropriate keys loaded
- Git configured to use SSH for GitHub

## Troubleshooting

If it's not working:

1. **Check SSH agent**:
   ```bash
   ssh-add -l  # List loaded keys
   ssh -T git@github.com  # Test GitHub access
   ```

2. **Test submodule access**:
   ```bash
   git clone --recursive git@github.com:CaptainKranch/Claude-Hooks.git test-clone
   ```

3. **Debug Nix command**:
   ```bash
   nix run --debug "github:CaptainKranch/Claude-Hooks?submodules=1#notification"
   ```

## For Non-Admin Users

Users without Silencer access will see an error when using `?submodules=1`. They should use environment variables instead:
```bash
export CLAUDE_TELEGRAM_BOT_TOKEN="token"
export CLAUDE_TELEGRAM_CHAT_ID="chat_id"
nix run github:CaptainKranch/Claude-Hooks#notification
```

## Best Practice

Consider having two Claude Code configurations:
- `~/.claude/settings.json` - For admins with `?submodules=1`
- `~/.claude/settings.public.json` - For testing without submodules