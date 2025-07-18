# Architecture: Claude-Hooks with Integrated Secrets

## Repository Structure

**Claude-Hooks** now contains:
- Python hook scripts for Claude Code
- Encrypted secrets using agenix (in `secrets/encrypted/`)
- Public key configuration (`secrets.nix`)

## How It Works

### For Team Members (with SSH keys in secrets.nix)
```bash
# Just works - no setup needed!
nix run github:CaptainKranch/Claude-Hooks#notification
```
- Nix fetches the repository including encrypted secrets
- Automatically decrypts using your SSH key
- No environment variables or submodules needed

### For Public Users (without SSH access)
```bash
export CLAUDE_TELEGRAM_BOT_TOKEN="your_token"
export CLAUDE_TELEGRAM_CHAT_ID="your_chat_id"
nix run github:CaptainKranch/Claude-Hooks#notification
```
- Decryption fails gracefully
- Falls back to environment variables

## Security Model

1. **Encrypted Secrets**: Stored in the public repo but encrypted with age
2. **SSH Key Authentication**: Only listed SSH keys can decrypt
3. **Graceful Fallback**: Non-team members can still use env vars
4. **Version Control**: Secrets are versioned alongside code

## Benefits

- ✅ **Zero Configuration**: Team members just run the command
- ✅ **Works Remotely**: `nix run github:...` includes everything
- ✅ **No Submodules**: Simpler repository structure
- ✅ **Easy Onboarding**: Just add SSH keys to `secrets.nix`

## Trade-offs

- ⚠️ Encrypted secrets visible in public repo (but secure with proper key management)
- ⚠️ Requires re-encryption when team changes
- ⚠️ SSH key compromise requires immediate action

This approach prioritizes convenience for your team while maintaining security through encryption.