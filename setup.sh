#! /usr/bin/env bash

# install dependencys
os=$(cat /etc/os-release | grep '^NAME=')
if [[ ${os} != "NAME=\"Arch Linux\"" ]]; then
    echo "we only support Arch linux currently."
    exit 1
fi

sudo pacman -S --needed \
     git \
     ctags global \
     python python-pygments \
     ttf-ubuntu-mono-nerd wqy-microhei ttf-hanazono \
     clang pyright ruff

# install sarasaTermSCNerd
fc-list | grep -i "Sarasa Term SC Nerd"
if [[ $? -ne 0 ]]; then
    font_path=~/.local/share/fonts/
    if [[ ! -d ${font_path} ]]; then
        mkdir -p ${font_path}
    fi

    wget https://github.com/laishulu/Sarasa-Term-SC-Nerd/releases/download/v2.3.1/SarasaTermSCNerd.ttc.tar.gz
    tar xf ./SarasaTermSCNerd.ttc.tar.gz -C ${font_path}
    sudo fc-cache
    rm ./SarasaTermSCNerd.ttc.tar.gz
fi

# setup python venv for lsp bridge
lsp_bridge_pyenv_path=~/.emacs.d/lsp.bridge.pyenv
if [[ -d ${lsp_bridge_pyenv_path} ]]; then
    exit 0
fi
python -m venv ${lsp_bridge_pyenv_path}
source ${lsp_bridge_pyenv_path}/bin/activate
python -m pip install --upgrade pip
pip install epc orjson sexpdata six setuptools paramiko rapidfuzz watchdog packaging
