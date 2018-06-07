# first importing aliases in order to use gvar
source ~/dotfiles/zsh/aliases.sh

# update dotfiles once a day
CURRENT_DATE=$(date "+%Y-%m-%d")
if [[ $(gvar DOTFILES_WERE_UPDATED_AT) -ne $CURRENT_DATE ]]; then
    echo "Updating configuration"
    (cd ~/dotfiles && git pull && git submodule update --init --recursive)
    gvar DOTFILES_WERE_UPDATED_AT=$CURRENT_DATE
fi

source ~/dotfiles/zsh/zshrc.sh
