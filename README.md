# Setup
- install conda
- install conda-pack `conda install conda-pack`
- install warp-packer from nikvdp fork: https://github.com/nikvdp/warp/releases
- if on an m1 mac, make sure you have an **intel** version of conda installed
- for `build-all.sh` make sure you have a recent version of bash on path (for
  assoc arrays)


# Usage
`./build.sh <some-conda-package-with-an-executable>`
 eg. `./build.sh jq`
will put a jq exec in the ./out folder

# TODO:
- [✔️] allow for package and executable  names to be different
    - e.g. to package neovim, do:
      ```
      export CMD_TO_RUN="nvim"
      ./build.sh neovim
      ```

