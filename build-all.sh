#!/usr/bin/env bash
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

set -u
# set -x

# this script should be run by ci to build all the pkgs

# this is the list of which custom pkgs to build, but the pkg still needs to be
# added to complex or simple below
custom_pkgs=(
    bfs
    cogapp
    curl  # need to use custom curl, conda's native version has ssl issues
    delta
    fd
    hyperbeam 
    jc
    litellm
    netcat
    prisma
    ridgepole
    screen
)

simple=(
    bash
    bat
    bfs
    curl
    datasette
    delta
    deno
    direnv
    docker-compose
    emacs
    exa
    fd
    ffmpeg
    fzf
    gawk
    gem
    gh
    git
    go
    hyperbeam
    jc
    jq
    jupyter
    litellm
    mosh
    ncdu
    nginx
    parallel
    pdm
    perl
    pgcli
    pipenv
    pipx
    poetry
    prisma
    progress
    pv
    python
    ridgepole
    rclone
    rsync
    ruby
    screen
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
    # # pstree  # no conda package
    # # mplayer # no conda package
    # # shfmt   # no conda package
    # # howdoi  # no conda package
    #
    # [1]: https://github.com/ContinuumIO/anaconda-issues/issues/72#issuecomment-511185603
)

# format is: complex[<cmd-to-run>]=<package-name>
declare -A complex
complex[ag]=the_silver_searcher
complex[cargo]=rust
complex[chronic]=moreutils
complex[cog]=cogapp
complex[convert]=imagemagick
complex[ctags]=universal-ctags
complex[ffprobe]=ffmpeg
complex[gtimeout]=gnu-coreutils # bin should be called timeout, but no support for that yet
complex[http]=httpie
complex[java]=openjdk
complex[mogrify]=imagemagick
complex["mosh-client"]=mosh
complex["mosh-server"]=mosh
complex[nc]=netcat
complex[node]=nodejs
complex[npm]=nodejs
complex[npx]=nodejs
complex[nvim]=neovim
complex[pee]=moreutils
complex[pg_dump]=postgresql
complex[pg_restore]=postgresql
complex[postgres]=postgresql
complex[psql]=postgresql
complex[python]=python3
complex["redis-cli"]=redis
complex[rg]=ripgrep
complex[rustc]=rust
complex[sponge]=moreutils
complex[sqlite3]=sqlite
complex[sshd]=openssh
complex[ssh]=openssh
complex[ts]=moreutils
complex[vidir]=moreutils
complex[vipe]=moreutils

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
        echo ">>> Building custom conda package for '$p'"
        conda build . && echo "OK!" || echo "Error!" || true
        echo ">>> Completed custom conda package for '$p' "
    done
    cd "$SCRIPT_DIR"
    true
}

build-simple-packages() {
    echo "Building simple 1bins"
    for i in "${simple[@]}"; do
        if [[ -e "$SCRIPT_DIR/out/$i" ]]; then
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
        if ! [[ -e "$SCRIPT_DIR/out/$cmd_name" ]]; then
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

set -x
main
