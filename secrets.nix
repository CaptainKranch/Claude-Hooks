# Agenix secrets configuration
# This file defines who can decrypt which secrets

let
  # Add the SSH public keys of users who should be able to decrypt secrets
  # You can get your public key with: cat ~/.ssh/id_ed25519.pub
  users = {
    dgm = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKeMSnEvoZrlPC7LMnlIEeLTQ3QLpdeM6njeXhtqFYrM dgm";
    # Add your team members here
  };

  # Systems that need to decrypt secrets (optional, for NixOS deployments)
  systems = {
    # Example: server1 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAI... root@server1";
  };

  # Combine all keys that should have access
  allUsers = builtins.attrValues users;
  allSystems = builtins.attrValues systems;
  allKeys = allUsers ++ allSystems;
in
{
  # Define which keys can decrypt which secrets
  "secrets/encrypted/telegram-token.age".publicKeys = allKeys;
  "secrets/encrypted/telegram-chat-id.age".publicKeys = allKeys;
  
  # Add more secrets as needed
  # "secrets/encrypted/slack-webhook.age".publicKeys = allKeys;
}