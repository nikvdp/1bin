# Setup
- install conda
- install conda-pack `conda install conda-pack`
- install warp-packer from nikvdp fork: https://github.com/nikvdp/warp/releases


# Usage
`./build.sh <some-conda-package-with-an-executable>`
 eg. `./build.sh jq`
will put a jq exec in the ./out folder

# TODO:
- allow for package and executable binary to have different names
