#!/usr/bin/env bash

SCRIPT_LIB_DIR="$(dirname "${BASH_SOURCE[0]}")"

export TERM=xterm-256color
export K9S_EDITOR=code 
BLUE=$'\e[34m'
NC=$'\e[0m' # No Color

export SOURCED="yes"

export PATH=bin:$PATH 

#PACKAGES="$(cat packages/brew.txt | sed 's/#.*$//' | grep -v 'tektoncd-cli\|kubectx\|stern\|watch')"
PACKAGES=(k3d k9s k6)
for pkg in  ${PACKAGES[@]}; do 
    echo -e "${BLUE}Applying zsh completion for $pkg${NC}" 
    source <($pkg completion zsh)
done 

if [[ -d $HOME/.istioctl ]];then
    export PATH=$HOME/.istioctl/bin:$PATH 
    if [ ! "$(command -v istioctl >/dev/null)" ];then 
        echo -e "${BLUE}Applying zsh completion for istioctl${NC}" 
        source <(istioctl completion zsh)
    fi 
fi

