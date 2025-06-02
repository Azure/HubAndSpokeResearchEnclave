ARG PWSH_VER="7.5.1"
ARG BICEP_VER="0.36.1"
ARG TERRAFORM_VER="1.12.1"
ARG AZ_ACCOUNTS_MODULE_VER="4.0.2"
ARG AZ_RESOURCES_MODULE_VER="7.5.0"

FROM mcr.microsoft.com/devcontainers/base:1.2.4-ubuntu22.04
ARG PWSH_VER
ARG BICEP_VER
ARG TERRAFORM_VER
ARG AZ_RESOURCES_MODULE_VER
ARG AZ_ACCOUNTS_MODULE_VER


USER root
RUN wget "https://github.com/PowerShell/PowerShell/releases/download/v${PWSH_VER}/powershell_${PWSH_VER}-1.deb_amd64.deb" \
    && apt-get update && export DEBIAN_FRONTEND=noninteractive \
    && apt-get -y install unzip \
    && dpkg -i "powershell_${PWSH_VER}-1.deb_amd64.deb" \
    && apt-get install -f \
    && rm "powershell_${PWSH_VER}-1.deb_amd64.deb" \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && pwsh -Command "Set-PSRepository -Name PSGallery -InstallationPolicy Trusted" \
    && pwsh -Command "Install-Module -Name posh-git -Scope AllUsers -Repository PSGallery -Verbose -Force" \
    && pwsh -Command "Import-Module -Name posh-git" \
    && pwsh -Command "Install-Module -Name Az.Resources -MaximumVersion ${AZ_RESOURCES_MODULE_VER} -Scope AllUsers -Repository PSGallery  -Verbose -Force" \
    && pwsh -Command "Import-Module -Name Az.Resources" \
    && pwsh -Command "Install-Module -Name Az.Accounts -MaximumVersion ${AZ_ACCOUNTS_MODULE_VER} -Scope AllUsers -Repository PSGallery  -Verbose -Force" \
    && pwsh -Command "Import-Module -Name Az.Accounts" \
    && pwsh -Command "Install-Module -Name Pester -Scope AllUsers -Repository PSGallery  -Verbose -Force" \
    && pwsh -Command "Import-Module -Name Pester" \
    && pwsh -Command "Install-Module -Name PSReadLine -Scope AllUsers -Repository PSGallery  -Verbose -Force" \
    && pwsh -Command "Import-Module -Name PSReadLine" \
    && pwsh -Command "Set-PSRepository -Name PSGallery -InstallationPolicy Untrusted"


RUN wget -Obicep "https://github.com/Azure/bicep/releases/download/v${BICEP_VER}/bicep-linux-x64" \
    && mv ./bicep /usr/local/bin/bicep \
    && chmod 755 /usr/local/bin/bicep


RUN  wget -O"terraform_${TERRAFORM_VER}_linux_amd64.zip" "https://releases.hashicorp.com/terraform/${TERRAFORM_VER}/terraform_${TERRAFORM_VER}_linux_amd64.zip" \
    && unzip "terraform_${TERRAFORM_VER}_linux_amd64.zip" terraform \
    && mv ./terraform /usr/local/bin/terraform \
    && chmod 755 /usr/local/bin/terraform \
    && rm -f "terraform_${TERRAFORM_VER}_linux_amd64.zip"


USER vscode
RUN curl -s https://ohmyposh.dev/install.sh | bash -s \
    && pwsh -Command 'New-Item -Path $PROFILE -ItemType File -Force' \
    && pwsh -Command "'New-Alias \"tf\" \"terraform\"' | Out-File -FilePath \$PROFILE" \
    && pwsh -Command "'Import-Module -Name posh-git' | Out-File -Append -FilePath \$PROFILE" \
    && pwsh -Command "'oh-my-posh init pwsh | Invoke-Expression' | Out-File -Append -FilePath \$PROFILE"


CMD [ "pwsh" ]