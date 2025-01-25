# Raspberry Pi Pico SDK for Nim

This library provides the library and build system necessary to write
programs for RP2040-based devices (such as the Raspberry Pi Pico) in the
[Nim](https://nim-lang.org/) programming language.

The libary provides a complete wrapper for the [Raspberry Pi Pico
SDK](https://github.com/raspberrypi/pico-sdk) v2.1.0. Here are some of the feature highlights:

* Project generator and building using the `piconim` tool
* Setup, build and upload your project using Nimble, automatically runs CMake
  (use piconim for advanced building)
* Standard SDK library features such as GPIO, time, ADC, PWM and many more
* Wrapper for Pico SDK functions but with Nim flavour, with strict types for safety
* Wireless support for Pico W (Wifi, Bluetooth, HTTPS)

Blink example (works on Pico W too!)

```nim
import picostdlib

DefaultLedPin.init()
DefaultLedPin.setDir(Out)

while true:
  DefaultLedPin.put(High)
  sleepMs(250)
  DefaultLedPin.put(Low)
  sleepMs(250)
```

See the [examples](examples) folder for more examples on how to use the SDK using Nim.


## Setup

**The following steps will install piconim and create a new project**

1. First, you will need to have the Nim compiler installed. If you don't already
have it, consider using [choosenim](https://github.com/dom96/choosenim).

2. Since this is just a wrapper for the original
[pico-sdk](https://github.com/raspberrypi/pico-sdk), you will need to install the C
library [dependencies](https://github.com/raspberrypi/pico-sdk#quick-start-your-own-project)
(Step 1 in the quick start section).

3. Some parts of this library uses [Futhark](https://github.com/PMunch/futhark) to
wrap some C libraries, which depends on libclang.
See its installation guide [here](https://github.com/PMunch/futhark#installation).

4. From the terminal, run `nimble install https://github.com/EmbeddedNim/picostdlib`.

5. Run `piconim init <project-name>` to create a new project directory from a
template. This will create a new folder, so make sure you are in the parent folder.
When it asks for what project type, choose `>binary<` or `>hybrid<`. If you choose
`>library<` there will be nothing to build.
You can also provide the following options to the subcommand:
    - (--sdk, -s) -> specify the path to a locally installed `pico-sdk` repository,
      ex.  `--sdk:/home/user/pico-sdk`.
    - (--board, -b) -> specify the board type (`pico` or `pico_w` are accepted),
      choosing pico_w includes a pico_w blink example
    - (--overwrite, -O) -> a flag to specify overwriting an exisiting directory
      with the `<project-name>` already created. Be careful with this.
      ex. `piconim myProject --overwrite` will replace a folder named `myProject`

6. Change directory to the new project and run `nimble configure`. This will initialize
the Pico SDK using CMake. If you provided a path to the SDK in the previous step, it will
use that, otherwise it will download the SDK from GitHub, or if you have the Pico SDK installed
already, it will use environment variable `PICO_SDK_PATH`.

You are now ready to start developing and building your project.


## Building

When you are ready to build the `.uf2` file (which will be copied to the Raspberry Pi Pico),
you can use the `build` command of Nimble:

`nimble build`

The generated `.uf2` file is placed in `build/<project>/<program>.uf2`

Modify `CMakeLists.txt` to suit your project's needs.

## Usage

```bash
# Initialize a new project
piconim init [--sdk <sdk-path>] [--board <pico-board>] [--overwrite] <project-name>

# Run the following commands from the project root.
# If you don't specify a program name, it will use all
# binaries specified in your Nimble file. You can specify multiple.

# Run CMake configure, download Pico SDK from Github (if needed)
nimble configure [program]

# Builds C/C++ files with Nim, runs CMake build/make
nimble build [program]

# Run the CMake clean target, and cleans nimcache
nimble fastclean [program]

# Clean build directories, and cleans nimcache
nimble distclean [program]

# Runs clean and then builds.
nimble buildclean [program]

# Upload using picotool (installed separately)
# Pass --build to run build task first. Add --clean to clean before building.
nimble upload [program] [--build] [--clean]

# Monitors the tty port using minicom (/dev/ttyACM0)
nimble monitor

# Runs CMake configure without Nimble.
piconim configure [--project <project-name>] [--source <source-dir>] [--sdk <sdk-path>]
  [--board <pico-board>]

# Build a program without Nimble.
piconim build [--project <project-name>] [--target <target>] [--compileOnly] [--upload] <program>

```


## Contributing

Please contribute.
