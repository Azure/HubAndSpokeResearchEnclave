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

1. Install [GPG4Win](https://gpg4win.org/) . The version of GPG available through WinGet is out-of-date.
2. Install the version of Ubuntu for WSL specified by the `FROM ....` in `.devcontainer/Dockerfile`.

```Powershell
wsl --install Ubuntu-24.04
wsl --set-default Ubuntu-24.04
```
3. [Generate ssh key pair](https://docs.github.com/en/authentication/connecting-to-github-with-ssh/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent) and [add it to your GitHub profile](https://docs.github.com/en/authentication/connecting-to-github-with-ssh/adding-a-new-ssh-key-to-your-github-account).
4. [Generate a GPG key pair and add the public key to your GitHub profile](https://docs.github.com/en/authentication/managing-commit-signature-verification/generating-a-new-gpg-key).
5. Add the following to `~/.bash_profile`:
```bash
tee -a ${HOME}/.bash_profile<<'_EOF'
if [ -z "$SSH_AUTH_SOCK" ]; then
   # Check for a currently running instance of the agent
   RUNNING_AGENT="`ps -ax | grep 'ssh-agent -s' | grep -v grep | wc -l | tr -d '[:space:]'`"
   if [ "$RUNNING_AGENT" = "0" ]; then
        # Launch a new instance of the agent
        ssh-agent -s &> $HOME/.ssh/ssh-agent
   fi
   eval `cat $HOME/.ssh/ssh-agent` > /dev/null
   ssh-add 2> /dev/null
fi
_EOF
```

6. Modify `gpg-agent` in the WSL Ubuntu guest to use the Windows host's installation of the GPG4Win GUI pin entry program to unlock your GPG private key to sign your commits.

```Bash
echo pinentry-program /mnt/c/Program\ Files\ \(x86\)/Gpg4win/bin/pinentry.exe > ~/.gnupg/gpg-agent.conf
gpg-connect-agent reloadagent /bye
```

7. Install PowerShell in your WSL Ubuntu guest.

```Bash
wget "https://github.com/PowerShell/PowerShell/releases/download/v${PWSH_VER}/powershell_${PWSH_VER}-1.deb_amd64.deb" \
sudo apt-get update && export DEBIAN_FRONTEND=noninteractive \
sudo apt-get -y install unzip \
sudo dpkg -i "powershell_${PWSH_VER}-1.deb_amd64.deb" \
sudo apt-get install -f \
rm "powershell_${PWSH_VER}-1.deb_amd64.deb" 
```
The next steps will be user specific, before proceeding you should create a new branch specific to your user.
Add a new entry in  `.gitignore`:  `"`n`ndevcontainer.json" | Add-Content -Path .gitignore`

8. Persist the DevContainer's `/home/vscode/.local/share/powershell/PSReadLine/ConsoleHost_history.txt` by uncommenting lines `12-18` in `.devcontainer/.devcontainer.json` and replace `<username>` with the user in WSL.
NB, you may create additional bind mounts in this fashion to persist other settings like those for `oh-my-posh`. 


## OS X

[TBD]

## Linux

[TBD]