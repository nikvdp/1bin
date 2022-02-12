# 1bin - easily build “static” binaries of any CLI tool

1bin lets you easily build “static” binaries of pretty much any command line program. 

It's website, [1bin.org](https://1bin.org) contains `curl`/`wget`-able friendly links that you can use like so: `wget 1bin.org/$(uname)/<some-program>`. These links are updated on each push to master to reflect any new tools or deletions. Pull requests to add new tools welcome.

Using the scripts here you can build pretty much anything that can be packaged with [conda](https://www.anaconda.com/), which is... pretty much everything. 

*Current status: working POC. It does what it’s supposed to, but is held together with virtual duct tape — use at your own risk*

## Usage

If you just want to run programs without having to do any installation, head over to [1bin.org](https://1bin.org), find the program you’re after, and then paste the code snippet into a terminal on your machine to run it instantly (or at least as instantly as your ISP allows), no fuss no muss. 

All binaries are also available on this project's [Github Releases](https://github.com/nikvdp/1bin/releases) page for direct download if you prefer.

## What is this?

An unholy agglomeration of some hairy bash scripting, github actions, [conda](https://www.anaconda.com/), [conda-pack](https://conda.github.io/conda-pack/) and [warp](https://github.com/nikvdp/warp) to convert most anything that can be packaged with conda into a self-extracting and relocatable “static” binary (static in scare-quotes, because it’s actually a self-extractor not a true static binary)

Some potential use cases: 

- easily use popular command-line tools from inside restricted environments such as docker containers or CI environments on both Mac and Linux
- easily install command-line tools for one off use-cases on someone else’s machine
- make more portable shell scripts that can download any needed third party tools on the fly, regardless of what package managers the OS has provided
- (relatively) easily create self-contained and easily deployable packages of your own software for distributing to your end users.

## How does it work?

Conda is mostly known as a python package manager built to help install python packages with complicated native dependencies (a common use case when using python for machine learning and data science work) without having to recompile them yourself. However, a lesser known fact about conda is that in the process of solving this problem, they built an entire generic package management system that’s actually closer in spirit to tools like [`brew`](https://brew.sh/) or `apt-get` than it is to other python env managers like [poetry](https://python-poetry.org/) or [pipenv](https://pipenv.pypa.io/en/latest/).

Conda is able to create virtualenvs in the same way as most python env managers, but unlike other python env management tools, conda environments are self-contained and can easily include other binary tools. Most binary packages rely on hardcoded absolute paths, and can therefore not be easily relocated to run on another user’s machine. However, conda does a bunch of unixy black magic with `patchelf` and [rpath](https://en.wikipedia.org/wiki/Rpathhttps://en.wikipedia.org/wiki/Rpath) manipulation that converts these hardcoded absolute paths into relative paths that can easily be transported to different machines, and because they are complete self-contained environments can be built in a way that doesn’t depend on anything from the host machine (except for glibc).

They also released the wonderful [conda-pack](https://conda.github.io/conda-pack/), which can convert an installed conda environment into a tarball. By combining these with the excellent [warp](https://github.com/fintermobilityas/warp), (a rust program to package a directory into a single executable) it’s possible to build fully self-contained binaries that can be run anywhere. 

Under the hood, when you run a 1bin app, it uses [my fork of warp](https://github.com/nikvdp/warp) to extract a `conda-pack`-ed environment into a local cache directory, and then runs the specified executable from there as a subprocess, passing any unix signals and path information down to the called subprocess.

1bin takes care of automating this process so that any package that is available on [conda-forge](https://conda-forge.org/) (there are a lot of them!) can be converted into a single self-extracting binary for macOS or Linux. For now it’s `x86_64` only, but this approach could relatively easily be extended to build arm or mac M1 self-extracting executables in the same way, and with some work even support building Windows packages this way!

## Contributing

PRs are very welcome! Adding new packages that already exist on [conda-forge](https://conda-forge.org/) should be as easy as adding them to the list in [build-all.sh](https://github.com/nikvdp/1bin/blob/master/build-all.sh#L7-L27). If the package name on conda-forge differs from the executable name, add them as a ‘complex’ package.

Once they’ve been added there and I’ve verified that the built binary works correctly on both macOS and Linux I’ll merge the PR and rebuild [1bin.org](https://1bin.org) and they should be available for all to download.

There’s some nascent support for [custom conda recipes](https://github.com/nikvdp/1bin/tree/master/custom-recipes) as well, so if you have a tool that you’d like to have packed up as a 1bin but isn’t yet in conda-forge feel free to send in PRs with new conda-recipes and I’ll see that they get built.

## Development / making your own packages for personal use

### Install prereqs

Make sure you have the prerequisites installed:

- install [conda](https://www.anaconda.com/)
- tell conda to use [conda-forge](https://conda-forge.org/) (pasting this shell snippet should do the trick):
    
    ```bash
    cat >$HOME/.condarc <<EOF
    always_yes: true
    channels:
        - conda-forge
        - defaults
    EOF
    ```
    
- install conda-pack: `conda install conda-pack`
- install my fork of [warp-packer](https://github.com/nikvdp/warp): (you can download it from [https://github.com/nikvdp/warp/releases](https://github.com/nikvdp/warp/releases))
- if you are using an M1 mac, make sure you have the **intel** version of conda installed, this approach doesn’t yet support M1 natively
- make sure you have a recent (> 5.0) version of bash installed (**NOTE: the version of bash provided by default on macOS is too old!**) because `build-all.sh` uses associative arrays which are not supported on older versions of bash. (You can of course install a recent version of bash simply by doing `wget 1bin.org/$(uname)/bash && chmod +x bash` , and putting the new `bash` binary somewhere on your `PATH` 🙂)

### Build your own executable locally

To build a package that’s available in conda-forge or the standard anaconda repos just do:

```bash
./build.sh <some-conda-package-with-an-executable>
```

 eg. `./build.sh jq` will put a jq executable in the `./out` folder.

In some cases the package name may be different from the executable name. In this situation you need to pass the package name as the argument to `build.sh` and tell it which command to call from inside the package via the `CMD_TO_RUN` environment variable. 

As an example, [ripgrep](https://github.com/BurntSushi/ripgrep) is available under the package name `ripgrep`, but the executable name for `ripgrep` is `rg`. If you wanted to build a 1bin of ripgrep, you would run `./build.sh` like so:

```bash
CMD_TO_RUN=rg ./build.sh ripgrep
```

This would leave an `rg` executable in the `out/` folder.

### Building private packages

If you are familiar with conda, it’s also possible to use 1bin to build binaries from private conda repositories or private source code. More detail to come on this, but the tl;dr: 

- you first need to make a valid conda recipe for your package. Take a look at the [conda-build documentation](https://docs.conda.io/projects/conda-build/en/latest/), or the [custom-recipes](https://github.com/nikvdp/1bin/tree/master/custom-recipes) folder for some examples
- because `build.sh` uses the `--use-local` flag when building, once you’ve built and installed your own conda package, you can use it with `build.sh` as normal eg `build.sh <some-package-you-built>`

## FAQs

- Sometimes nothing happens or it takes a while for my CLI tool to run, what gives?
    
    This can happen the first time you run a particular 1bin on a new machine. Since under the hood 1bin is extracting a compressed copy of all the dependencies used for that particular CLI tool, the initial run can take a few seconds while it extracts (see “Where do the extracted files go?” below). 
    
    Subsequent runs will be much snappier as it will then run the already extracted cache instead. 
    
    In some cases (eg if you hit ctrl-c during the extraction process) [warp](https://github.com/nikvdp/warp) may get confused and try to run the partially extracted version, leading to very strange errors. If this happens, try going to the `warp/packages` directory (see “Where do the extracted files go?” below) and deleting the partially extracted version so that it’ll be (fully) extracted next time you run the 1bin.
    
    (I’ll be updating warp in the future to be smarter about this kind of thing so that this doesn’t happen)
    
- Where do the extracted files go?
    
    [warp](https://github.com/nikvdp/warp) caches them under `~/Library/Application Support/warp/packages` on macOS and `~/.local/share/warp/packages` on Linux. If you delete any of the folders under there they will be recreated the next time you run a 1bin.
    
- Is this safe?
    
    Depends on your definitions of safe. You can check the code, this repo is just a way to repackage the great work done by the wonderful community over at [conda-forge](https://conda-forge.org/) into convenient to use binaries, but you are definitely trusting both me and the conda-forge communities to not do anything untoward. If you are concerned about this I’d recommend using another tool
    
- Is it just me or are these binaries pretty huge??
    
    It’s not just you, they’re pretty big. [Warp](https://github.com/nikvdp/warp) does compress the input, but for each of these programs the binary has to contain both the program itself and a full copy of every dependency required for it to run, and no attempts have (yet) been made to optimize this. 
    
    For example, the `docker-compose` 1bin contains a full Python interpreter and every library that docker-compose itself uses inside that file, and so comes in at around 55mb for the Linux version. Given that disks are cheap and networks are fast these days, seems like a good trade to me, ymmv.
