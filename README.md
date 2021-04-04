# MacOSX SDKs

Mac OSx SDKs used for cross compiling. The SDKs were generated from Command Line Tools, which can be obtained
from https://developer.apple.com/download/more/.

## Generating a SDK package from macOS

1. Make sure you have the Command Line Tools installed. Usually running commands like `gcc` or `make` will attempt to
   install the Command line tools.
2. Run `./scripts/gen_sdk_package.sh`

## Generating a SDK package from a .dmg file

1. Create the docker image: `docker build -t mac-sdk-packager .`
2. Run the container with the volume containing the `.dmg` file: `docker run --rm -v "<volume-path>:/sdk" mac-sdk-packager`