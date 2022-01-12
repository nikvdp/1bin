#!/usr/bin/env bash
set -eu
set -x

# this script should be run by ci to build all the pkgs

./build.sh tree
./build.sh pv
./build.sh wget
./build.sh pandoc
./build.sh nvim
./build.sh rsync
./build.sh rg
./build.sh curl
./build.sh tmux
./build.sh bat
./build.sh direnv
./build.sh docker-compose
./build.sh jc
./build.sh jq
./build.sh fzf
./build.sh git
CMD_TO_RUN=nvim ./build.sh neovim
CMD_TO_RUN=rg ./build.sh ripgrep

