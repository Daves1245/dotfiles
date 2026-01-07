#!/bin/bash

# Setup error handling
set -e
trap 'echo "Error at $BASH_SOURCE on line $LINENO!"' ERR

ALWAYS_YES=
if [[ "$1" == "-y" ]]; then
  ALWAYS_YES="y"
fi

maybe_read () {
  if [[ ! -z "$ALWAYS_YES" ]]; then
    echo "$1 y"
    export REPLY="y"
  else
    read -p "$1" -r
    echo
  fi
}

# Prompt user about this script
echo
maybe_read "This script is only prepared to run on Ubuntu or Mac OSX. Do you want to continue? (y/n) "
if [[ ! "$REPLY" =~ ^[Yy](es)?$ ]]; then
  echo "Feel free to edit this script file as desired to make it work on your OS/distro. If you rewrite it for your own operating system / distro and it works, do let me know so I can add your script to this repository. Thanks!"
  echo
  exit
fi

# Check for existant ~/.vim or ~/.vimrc
if [[ -d ~/.vim || -f ~/.vimrc || -d ~/.tmux || -f ~/.tmux.conf ]]; then
  maybe_read "An existant ~/.vim, ~/.vimrc, ~/.tmux, or ~/.tmux.conf has been found. Overwrite all contents? (y/n) "
  if [[ "$REPLY" =~ ^[Yy](es)?$ ]]; then
    rm -rf ~/.vim
    rm -f ~/.vimrc
    rm -rf ~/.tmux
    rm -f ~/.tmux.conf
  else
    echo "Cannot continue unless ~/.vim, ~/.vimrc, ~/.tmux, and ~/.tmux.conf no longer exist"
    echo
    exit 1
  fi
fi

# Install dependencies
if [[ "$OSTYPE" =~ ^darwin ]]; then
  brew install ccls node clang-format vim ripgrep fd tmux zsh
else
  # Install any Apt Pre-requisites
  sudo apt-get update -y
  pkgs='curl ccls clang-format vim-gtk3 ripgrep fd-find tmux zsh x11-xkb-utils'
  if ! dpkg -s $pkgs >/dev/null 2>&1; then
    sudo apt-get install $pkgs -y
  fi
  # Install NVM
  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.4/install.sh | bash
  source ~/.nvm/nvm.sh
  # Install NodeJS and NPM (latest LTS version)
  nvm install --lts
  nvm use --lts
fi

# Setup tmux plugins
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
cp tmux.conf ~/.tmux.conf
~/.tmux/plugins/tpm/bin/install_plugins

# Setup Vim Plugins
git clone https://github.com/VundleVim/Vundle.vim.git ~/.vim/bundle/Vundle.vim
cp .vimrc ~/.vimrc
# Install fzf via plugin instead of package manager, because apt's version is too old
echo "\n" | vim +PluginInstall +':call fzf#install()' +qall

# Copy coc-settings.json
cp coc-settings.json ~/.vim

# Checkout release version of coc
cd ~/.vim/bundle/coc.nvim
git config remote.origin.fetch "+refs/heads/*:refs/remotes/origin/*"
git fetch --depth=1 origin release
git checkout release
cd -

# Setup Zsh and Oh My Zsh
# Initialize git submodules for oh-my-zsh and custom plugins/themes
git submodule update --init --recursive

# Copy oh-my-zsh to home directory
if [ -d ~/.oh-my-zsh ]; then
  echo "oh-my-zsh already exists at ~/.oh-my-zsh, removing..."
  rm -rf ~/.oh-my-zsh
fi
cp -r .oh-my-zsh ~/.oh-my-zsh

# Clone powerlevel10k to home directory (as expected by .zshrc)
if [ -d ~/powerlevel10k ]; then
  echo "powerlevel10k already exists at ~/powerlevel10k, removing..."
  rm -rf ~/powerlevel10k
fi
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ~/powerlevel10k

# Copy zsh config files
cp .zshrc ~/.zshrc
cp .p10k.zsh ~/.p10k.zsh
cp .zsh_alias ~/.zsh_alias

# Copy custom zsh directory (plugins and themes)
if [ -d ~/.zsh_custom ]; then
  echo "Custom zsh directory already exists at ~/.zsh_custom, removing..."
  rm -rf ~/.zsh_custom
fi
cp -r .zsh_custom ~/.zsh_custom

# Setup Konsole terminal configuration
if [ -f .config/konsolerc ]; then
  echo "Setting up Konsole configuration..."
  cp .config/konsolerc ~/.config/
  mkdir -p ~/.local/share/konsole
  cp .config/konsole/"Profile 1.profile" ~/.local/share/konsole/
  echo "Konsole configured with zsh as default shell"
fi

if [[ ! "$OSTYPE" =~ ^darwin ]]; then
  # Prompt for caps lock to ctrl remap
  echo
  maybe_read "Do you want to remap CAPS LOCK to CTRL? (y/n) "
  if [[ "$REPLY" =~ ^[Yy](es)?$ ]]; then
    if ! which setxkbmap; then
      echo "Note: Could not find command \"setxkbmap\", will not remap CAPS LOCK to CTRL."
    else
      echo Executing \"setxkbmap -option ctrl:nocaps ...\"
      setxkbmap -option ctrl:nocaps
      echo Adding \"setxkbmap -option ctrl:nocaps\" to ~/.profile ...
      if ! cat ~/.profile | grep "Remap CAPS LOCK to CTRL" > /dev/null; then
        echo >> ~/.profile
        echo '# Remap CAPS LOCK to CTRL' >> ~/.profile
        echo 'setxkbmap -option ctrl:nocaps' >> ~/.profile
        echo >> ~/.profile
      fi
    fi
  else
    echo In the future, you can do this with \"setxkbmap -option ctrl:nocaps\"
    echo This command can be added to your \"~/.profile\" to execute on login
  fi
  echo
  echo Deactivating can be done by typing \"setxkbmap -option\"
  echo Deactivating can be done permanently by editing \"~/.profile\"
  echo

  echo
  ROOT_HOME=/root
  if [[ "$HOME" -ef "$ROOT_HOME" ]]; then
    echo "Installed this vimrc into root!"
  else
    maybe_read "Do you want to install this vimrc into the root user as well? (y/n) "
    if [[ "$REPLY" =~ ^[Yy](es)?$ ]]; then
      sudo rm -rf "$ROOT_HOME/.vim"
      sudo rm -f "$ROOT_HOME/.vimrc"
      sudo cp -r "$HOME/.vim" "$ROOT_HOME/.vim"
      sudo cp "$HOME/.vimrc" "$ROOT_HOME/.vimrc"
    fi
  fi
fi

echo ""
echo "Done!"
echo "To use zsh as your default shell, run: chsh -s \$(which zsh)"
echo "Then restart your terminal or run 'exec zsh'"
