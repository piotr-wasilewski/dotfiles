DOTFILES_WERE_UPDATED=1

if [[ DOTFILES_WERE_UPDATED -eq 1 ]]; then
    echo "Updating configuration"
    (cd ~/dotfiles && git pull && git submodule update --init --recursive)
fi

source ~/dotfiles/zsh/zshrc.sh
