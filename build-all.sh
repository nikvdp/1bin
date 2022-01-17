#!/usr/bin/env bash
# set -eu
# set -x

# this script should be run by ci to build all the pkgs

simple=(
    curl
    wget
    tree
    bat
    pv
    pandoc
    fzf
    jq
    rsync
    direnv
    docker-compose
    git
    openssl
    # jc
    yarn
    tmux
    tmate
    socat
    # yq
    # pstree # no conda package
)

declare -A complex
complex[ag]=the_silver_searcher
complex[rg]=ripgrep
complex[node]=nodejs
complex[npm]=nodejs
complex[nvim]=neovim
complex[ssh]=openssh
complex[sshd]=openssh
complex[java]=openjdk

for cmd_name in "${!complex[@]}"; do
    if ! [[ -e "out/$cmd_name" ]]; then
        export CMD_TO_RUN="$cmd_name"
        PACKAGE_NAME="${complex[$cmd_name]}"
        echo "Building $cmd_name (package: $PACKAGE_NAME)"

        ./build.sh "$PACKAGE_NAME" &>"$cmd_name".log
    else
        echo "Skipping $cmd_name"
    fi
done

for i in "${simple[@]}"; do
    if [[ -e "out/$i" ]]; then
        echo "Skipping $i"
    else
        echo "Building $i..."
        ./build.sh "$i" &>"$i".log
    fi
done
