let
  danielgm = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKeMSnEvoZrlPC7LMnlIEeLTQ3QLpdeM6njeXhtqFYrM dgm";
in
{
  "secrets/telegram-token.age".publicKeys = [ danielgm ];
  "secrets/telegram-chat-id.age".publicKeys = [ danielgm ];
}