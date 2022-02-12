#!/usr/bin/env bash
set -eu
# set -x

# this script should be run by ci to build all the pkgs

simple=(
    bash
    go
    deno
    youtube-dl
    yt-dlp
    emacs
    vim
    bat
    datasette
    direnv
    docker-compose
    exa
    ffmpeg
    fzf
    gawk
    gh
    git
    jq
    ncdu
    perl
    pv
    rclone
    rsync
    s3cmd
    tldr
    tree
    wget
    yarn
    yq
    zsh
    xonsh
    poetry
    pipenv
    # packages below don't work for various reasons
    # # tmux    # builds, but doesn't start (message about term not supporting clear)
    # # tmate   # builds, but binaries have issues (terminfo + dydl stuff on mac)
    # # socat   # builds, lin works but binary gives a dyld link error on mac
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
complex[ag]=the_silver_searcher
complex[cargo]=rust
complex[convert]=imagemagick
complex[ffprobe]=ffmpeg
complex[gtimeout]=gnu-coreutils # bin should be called timeout, but no support for that yet
complex[http]=httpie
complex[java]=openjdk
complex[mogrify]=imagemagick
complex[node]=nodejs
complex[npm]=nodejs
complex[npx]=nodejs
complex[nvim]=neovim
complex[python]=python3
complex["redis-cli"]=redis
complex[rg]=ripgrep
complex[rustc]=rust
complex[sqlite3]=sqlite
complex[ssh]=openssh
complex[sshd]=openssh
# complex[nc]=netcat  # there's no netcat package??

check_status() {
    local i="$1"
    if [[ "$?" == "0" ]]; then
        echo "OK!"
    else
        echo "ERROR!"
        sed <"$i.log" 's/^/>> /' || true # using a `|| true` so we don't exit the script if one pkg fails
    fi
}

echo "Building simple packages"
for i in "${simple[@]}"; do
    if [[ -e "out/$i" ]]; then
        echo "Skipping $i"
    else
        printf "Building $i... "
        ./build.sh "$i" &>"$i".log || true
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
        ./build.sh "$PACKAGE_NAME" &>"$cmd_name".log || true
        check_status "$cmd_name"
    else
        echo "Skipping $cmd_name"
    fi
done
echo "Finished building complex packages!"
