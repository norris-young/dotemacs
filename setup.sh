#! /usr/bin/env bash

# set -o xtrace

arch_setup() {
    sudo pacman -S --needed \
         ctags global \
         python python-pygments \
         ttf-ubuntu-mono-nerd wqy-microhei ttf-hanazono \
         clang pyright ruff

    # setup python venv for lsp bridge
    lsp_bridge_pyenv_path=~/.emacs.d/lsp.bridge.pyenv
    if [[ -d ${lsp_bridge_pyenv_path} ]]; then
        return
    fi
    python -m venv ${lsp_bridge_pyenv_path}
    source ${lsp_bridge_pyenv_path}/bin/activate
    python -m pip install --upgrade pip
    pip install epc orjson sexpdata six setuptools paramiko rapidfuzz watchdog packaging
}

msys_setup() {
    pacman -S --needed \
           ucrt64/mingw-w64-ucrt-x86_64-ctags \
           ucrt64/mingw-w64-ucrt-x86_64-global \
           ucrt64/mingw-w64-ucrt-x86_64-ttf-ubuntu-mono-nerd \
           ucrt64/mingw-w64-ucrt-x86_64-clang \
           ucrt64/mingw-w64-ucrt-x86_64-python \
           ucrt64/mingw-w64-ucrt-x86_64-python-pygments \
           ucrt64/mingw-w64-ucrt-x86_64-python-ruff-lsp \
           ucrt64/mingw-w64-ucrt-x86_64-python-six \
           ucrt64/mingw-w64-ucrt-x86_64-python-setuptools \
           ucrt64/mingw-w64-ucrt-x86_64-python-paramiko \
           ucrt64/mingw-w64-ucrt-x86_64-python-rapidfuzz \
           ucrt64/mingw-w64-ucrt-x86_64-python-watchdog \
           ucrt64/mingw-w64-ucrt-x86_64-python-packaging

    # setup python venv for lsp bridge
    lsp_bridge_pyenv_path=~/.emacs.d/lsp.bridge.pyenv
    if [[ -d ${lsp_bridge_pyenv_path} ]]; then
        return
    fi
    python -m venv --system-site-packages ${lsp_bridge_pyenv_path}
    source ${lsp_bridge_pyenv_path}/bin/activate
    python -m pip install --upgrade pip
    pip install epc orjson sexpdata
}

echo "Install dependencys(we may need sudo rights)..."
# install dependencys
os=$(cat /etc/os-release | grep '^NAME=')
if [[ "${os}" == "NAME=\"Arch Linux\"" ]]; then
    arch_setup
elif [[ "${os}" == "NAME=MSYS2" ]]; then
    msys_setup
else
    echo "${os} is not supported currently."
    exit 1
fi
echo "Done!"

echo "Install 3rd-party fonts..."
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
echo "Done!"
