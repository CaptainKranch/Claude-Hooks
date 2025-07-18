# Setting Up Secrets in Claude-Hooks

This guide explains how to set up encrypted secrets directly in the Claude-Hooks repository using agenix.

## Initial Setup

### 1. Add Your SSH Public Key

Edit `secrets.nix` and add your SSH public key:

```nix
users = {
  alice = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAI... alice@example.com";
  bob = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAI... bob@example.com";
};
```

Get your public key with:
```bash
cat ~/.ssh/id_ed25519.pub
```

### 2. Create Encrypted Secrets

```bash
# Enter development shell
nix develop

# Create telegram bot token
nix run .#secrets create telegram-token
# Enter your bot token when the editor opens

# Create telegram chat ID
nix run .#secrets create telegram-chat-id
# Enter your chat ID when the editor opens
```

### 3. Commit the Encrypted Secrets

```bash
git add secrets/encrypted/*.age secrets.nix
git commit -m "Add encrypted secrets"
git push
```

## How It Works

1. **Secrets are encrypted** using age with the SSH keys listed in `secrets.nix`
2. **Only authorized users** can decrypt (those whose keys are in `secrets.nix`)
3. **Encrypted files are safe to commit** - they're just encrypted blobs
4. **Remote execution works**: `nix run github:CaptainKranch/Claude-Hooks#notification`

## For Your Team

### Adding a New Team Member

1. Get their SSH public key
2. Add it to `secrets.nix`
3. Re-encrypt all secrets:
   ```bash
   nix develop
   nix run .#secrets rekey
   ```
4. Commit and push the updated secrets

### Using the Secrets

Once set up, team members can simply run:
```bash
nix run github:CaptainKranch/Claude-Hooks#notification
```

The secrets will be automatically decrypted using their SSH key!

## Security Considerations

### Pros:
- ✅ No environment variables needed
- ✅ Works with remote `nix run` commands
- ✅ Team members only need their SSH key
- ✅ Secrets are version controlled
- ✅ Easy to rotate secrets

### Cons:
- ⚠️ Encrypted secrets are visible in the public repo
- ⚠️ If someone's key is compromised, re-encryption is needed
- ⚠️ Age encryption security depends on SSH key security

### Recommendation:
This approach is suitable for non-critical secrets (like notification tokens). For highly sensitive data, consider keeping a private repository or using a dedicated secrets management system.

## Migrating from Silencer Submodule

If you have existing secrets in the Silencer submodule:

```bash
# Decrypt old secrets
age -d -i ~/.ssh/id_ed25519 secrets/telegram-token.age > /tmp/token
age -d -i ~/.ssh/id_ed25519 secrets/telegram-chat-id.age > /tmp/chat

# Create new encrypted secrets
nix run .#secrets create telegram-token
# Paste the token from /tmp/token

nix run .#secrets create telegram-chat-id  
# Paste the chat ID from /tmp/chat

# Clean up
rm /tmp/token /tmp/chat
```

## Testing

Test that everything works:
```bash
echo '{"hook_event_name": "Stop", "session_id": "test"}' | \
  nix run github:CaptainKranch/Claude-Hooks#notification
```

You should receive a Telegram notification!