# Setup of Dev Container Host Machine for Contributing

The supplied Devcontainer should be sufficient to execute the code.
If you would like to develop and contribute to the code base, you will need to configure your host operating system.

## Windows

If you use the Microsoft maintained Dev Container as your base, it will pick up your ssh keys in your default WSL Linux distribution.
It will also pick up your GPG keys, but it will require more [work](https://code.visualstudio.com/remote/advancedcontainers/sharing-git-credentials).

### Requirements

* Windows Subsystem for Linux
* Ubuntu
* GPG4Win

1. Install GPG4Win . The version of GPG available through WinGet is out-of-date.
2. Install the version of Ubuntu for WSL specified by the `FROM ....` in `.devcontainer/Dockerfile`.

```Powershell
wsl --install Ubuntu-24.04
wsl --set-default Ubuntu-24.04
```
3. [Generate ssh key pair](https://docs.github.com/en/authentication/connecting-to-github-with-ssh/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent) and [add it to your GitHub profile](https://docs.github.com/en/authentication/connecting-to-github-with-ssh/adding-a-new-ssh-key-to-your-github-account).
4. [Generate a GPG key pair and add the public key to your GitHub profile](https://docs.github.com/en/authentication/managing-commit-signature-verification/generating-a-new-gpg-key).
5. Modify `gpg-agent` to use the Windows host's installation of the GPG4Win GUI pin entry program to unlock your GPG private key to sign your commits.
6. [TBD] Persisting the DevContainer's `/home/vscode/.local/share/powershell/PSReadLine/ConsoleHost_history.txt` by creating a container volume mount in `devcontainer.json` to `/home/<username>/.local/share/powershell/PSReadLine/ConsoleHost_history`.
This will require installing PowerShell Core into the WSL Ubuntu.

```Bash
echo pinentry-program /mnt/c/Program\ Files\ \(x86\)/Gpg4win/bin/pinentry.exe > ~/.gnupg/gpg-agent.conf
gpg-connect-agent reloadagent /bye
```


## OS X

[TBD]

## Linux

[TBD]