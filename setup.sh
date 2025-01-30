#! /usr/bin/env bash

# setup python venv for lsp bridge
lsp_bridge_pyenv_path=~/.emacs.d/lsp.bridge.pyenv
python -m venv ${lsp_bridge_pyenv_path}
source ${lsp_bridge_pyenv_path}/bin/activate
pip install --upgrade pip
pip install epc orjson sexpdata six setuptools paramiko rapidfuzz watchdog packaging
