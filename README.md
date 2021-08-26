# Teardown Unofficial Modding Framework

The UMF is an unofficial extension of the modding system present in the game.

UMF is switching from a directory-based library to a package-based one.
This means you only need to copy over one file (containing all the code needed) to your mod and simply use that in `#include`.


# Installing

- Select one of the packages from the [Release Page](https://github.com/Thomasims/TeardownUMF/releases/latest)
    - `umf_complete_c.lua` is recommended during development.
- Place the package file somewhere in your mod
- Load the package with `#include` (e.g. `#include "umf_tool.lua"`)

# Building

If you wish to build your own package, for example if you need a subset of features not available on the release page, you can do so if you have a lua interpreter installed:
- Clone this repo locally
- Run `build.lua [-s] <output> <files...>`
    - `<files...>`: List of files (features) you want in your build. (e.g. `src/tool.lua`)
    - `<output>`: Location of the resulting package. (e.g. `dist/umf_tool.lua`)
    - `-s`: Optional parameter to shrink the resulting package.
