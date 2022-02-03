#!/usr/bin/env bash
set -eu
# set -x

# this script should be run by ci to build all the pkgs

simple=(
    bat
    direnv
    docker-compose
    fzf
    git
    jq
    pv
    rsync
    socat
    tmate
    tmux
    tree
    wget
    yarn
    # to test
    tldr
    shfmt
    mplayer
    ncdu
    gh
    fd
    ffmpeg
    # packages below don't work for various reasons
    # # curl  # builds, but gives ssl errors. probably a dep issue
    # # jc    # builds, but needs to use my formula
    # # yq    # ? not sure
    # # pstree # no conda package
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

check_status() {
    local i="$1"
    if [[ "$?" == "0" ]]; then
        echo "OK!"
    else
        echo "ERROR!"
        sed <"$i.log" 's/^/>> /'
    fi
}

echo "Building simple packages"
for i in "${simple[@]}"; do
    if [[ -e "out/$i" ]]; then
        echo "Skipping $i"
    else
        printf "Building $i... "
        ./build.sh "$i" &>"$i".log
        check_status "$i"
    fi
done

echo "Finished building simple packages!"

echo "Building complex packages (where pkg name and executable name differ)"
for cmd_name in "${!complex[@]}"; do
    if ! [[ -e "out/$cmd_name" ]]; then
        PACKAGE_NAME="${complex[$cmd_name]}"
        printf "Building $cmd_name (package: $PACKAGE_NAME)... "

        export CMD_TO_RUN="$cmd_name"
        ./build.sh "$PACKAGE_NAME" &>"$cmd_name".log
        check_status "$cmd_name"
    else
        echo "Skipping $cmd_name"
    fi
done
echo "Finished building complex packages!"
