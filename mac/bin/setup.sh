#!/usr/bin/env zsh

DOT_FOLDER=~/.dotfiles

cd ~

git clone --sparse https://github.com/HannesT117/dotfiles $DOT_FOLDER
cd $DOT_FOLDER
git sparse-checkout set mac shared .githooks
git config --local core.hooksPath .githooks/

sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
# plugins: git aws azure docker fzf jira gpg-agent keychain poetry thefuck tldr

sh -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
cd $DOT_FOLDER/mac
brew bundle

cd $DOT_FOLDER
sudo stow -t ~ shared mac
cd ~

# Enable Touch ID for sudo
sed "s/^#auth/auth/" /etc/pam.d/sudo_local.template | sudo tee /etc/pam.d/sudo_local

# Start mail sync
launchctl load Library/LaunchAgents/dev.trepesch.mailsync.plist
