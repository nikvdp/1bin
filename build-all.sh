#!/usr/bin/env bash
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

set -u
# set -x

# this script should be run by ci to build all the pkgs

custom_pkgs=(
    bfs
    jc
    netcat
)

simple=(
    bash
    bat
    bfs
    datasette
    deno
    direnv
    docker-compose
    emacs
    exa
    ffmpeg
    fzf
    gawk
    gh
    git
    go
    jq
    mosh
    ncdu
    netcat
    nginx
    perl
    pipenv
    poetry
    pv
    rclone
    rsync
    s3cmd
    socat
    tldr
    tree
    vim
    wget
    xonsh
    yarn
    youtube-dl
    yq
    yt-dlp
    zsh
    # packages below don't work for various reasons
    # # tmux    # builds, but doesn't start (message about term not supporting clear)
    # # tmate   # builds, but binaries have issues (terminfo + dydl stuff on mac)
    # # curl    # builds, but gives ssl errors. probably a dep issue
    # # jc      # builds, but needs to use my formula
    # # fd      # there's a package, but it doesn't seem to install a usable bin
    # # pstree  # no conda package
    # # mplayer # no conda package
    # # shfmt   # no conda package
    # # howdoi  # no conda package
)

# format is: complex[<cmd-to-run>]=<package-name>
declare -A complex
complex["mosh-client"]=mosh
complex["mosh-server"]=mosh
complex["redis-cli"]=redis
complex[ag]=the_silver_searcher
complex[cargo]=rust
complex[convert]=imagemagick
complex[ffprobe]=ffmpeg
complex[gtimeout]=gnu-coreutils # bin should be called timeout, but no support for that yet
complex[http]=httpie
complex[java]=openjdk
complex[mogrify]=imagemagick
complex[nc]=netcat
complex[node]=nodejs
complex[npm]=nodejs
complex[npx]=nodejs
complex[nvim]=neovim
complex[python]=python3
complex[rg]=ripgrep
complex[rustc]=rust
complex[sqlite3]=sqlite
complex[ssh]=openssh
complex[sshd]=openssh

check_status() {
    local i="$1"
    if [[ "$?" == "0" ]]; then
        echo "OK!"
    else
        echo "ERROR!"
        sed <"$i.log" 's/^/>> /' || true # using a `|| true` so we don't exit the script if one pkg fails
    fi
}

build-custom-packages() {
    for p in "${custom_pkgs[@]}"; do
        cd "$SCRIPT_DIR/custom-recipes/$p"
        printf "Building custom conda package for '$p'..."
        conda build . && echo "OK!" || echo "Error!" || true
    done
    cd "$SCRIPT_DIR"
    true
}

build-simple-packages() {
    echo "Building simple 1bins"
    for i in "${simple[@]}"; do
        if [[ -e "out/$i" ]]; then
            echo "Skipping $i"
        else
            printf "Building $i... "
            ./build.sh "$i" &>"$i".log || true
            check_status "$i"
        fi
    done
    echo "Finished building simple 1bins!"
}

build-complex-packages() {
    echo "Building complex 1bins (where pkg name and executable name differ)"
    for cmd_name in "${!complex[@]}"; do
        if ! [[ -e "out/$cmd_name" ]]; then
            PACKAGE_NAME="${complex[$cmd_name]}"
            printf "Building $cmd_name (package: $PACKAGE_NAME)... "

            export CMD_TO_RUN="$cmd_name"
            ./build.sh "$PACKAGE_NAME" &>"$cmd_name".log || true
            check_status "$cmd_name"
        else
            echo "Skipping $cmd_name"
        fi
    done
    echo "Finished building complex 1bins!"
}

main() {
    build-custom-packages
    build-simple-packages
    build-complex-packages
}

main
