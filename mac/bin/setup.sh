#!/usr/bin/env zsh

cd ~

sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
# plugins: git aws azure docker fzf jira gpg-agent keychain poetry thefuck tldr

sh -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
brew bundle

git clone https://github.com/HannesT117/dotfiles
cd dotfiles
sudo stow -t ~ mac
cd -

# Enable Touch ID for sudo
sed "s/^#auth/auth/" /etc/pam.d/sudo_local.template | sudo tee /etc/pam.d/sudo_local

# Start mail sync
launchctl load Library/LaunchAgents/dev.trepesch.mailsync.plist
