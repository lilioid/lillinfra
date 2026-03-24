# Backup

I am backing up mostly to [rsync.net](https://rsync.net)

## Onboarding a new Host

1. Generating an SSH Key

   ```
   ssh-keygen -t ecdsa -f id_ecdsa -C <hostname>
   ```

2. Add the SSH public key to rsync.net

   ```
   cat ./id_ecdsa.pub | ssh rsync.net 'dd of=.ssh/authorized_keys oflag=append conv=notrunc' 
   ```

3. Add the private key from `id_ecdsa` to `nix/data/host-secrets/<hostname>.yml` as

   ```
   backup:
     repoPass:
     ntfyToken:
     sshKey:
   ```

