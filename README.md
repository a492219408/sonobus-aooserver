This is the standalone connection server for use with SonoBus which uses AOO.

SonoBus can be found on github at https://github.com/essej/sonobus, or its
main website at https://sonobus.net .

# BUILD

All platforms use CMake (3.15+). Run all commands from the **repository root**.

## Linux

Requires `libcurl` development headers (`apt install libcurl4-openssl-dev` on
Debian/Ubuntu).

    cmake -B build -DCMAKE_BUILD_TYPE=Release
    cmake --build build

The resulting binary is `build/aooserver`. You can install it system-wide with:

    sudo cmake --install build

or copy it manually to a location of your choice (e.g. `/usr/local/bin`).

## macOS

    cmake -B build -DCMAKE_BUILD_TYPE=Release
    cmake --build build

The resulting binary is `build/aooserver`.

## Windows

Requires [MinGW-w64](https://www.mingw-w64.org/) (UCRT, posix, seh variant)
and [Ninja](https://ninja-build.org/).  On Debian/Ubuntu you can cross-compile
from Linux by installing the `mingw-w64` package (`apt install mingw-w64`).

    cmake -B build -G Ninja -DCMAKE_TOOLCHAIN_FILE=toolchain-mingw-ucrt-x86_64.cmake \
          -DCMAKE_BUILD_TYPE=Release
    cmake --build build

The resulting binary is `build/aooserver.exe`.

# DOCKER

A `Dockerfile` and a `compose.yaml` are provided for running the server inside
a container.

## Build and run with Docker Compose

```sh
docker compose up -d
```

This builds the image from source and starts the container in the background,
mapping port **10998** (UDP and TCP) to the host.  The container restarts
automatically unless it is explicitly stopped.

To stop and remove the container:

```sh
docker compose down
```

## Build and run with plain Docker

```sh
# Build the image
docker build -t sonobus_aooserver .

# Run the container
docker run -d \
  --name sonobus_aooserver \
  --restart unless-stopped \
  -p 10998:10998/udp \
  -p 10998:10998/tcp \
  sonobus_aooserver
```

## Customising the port

Pass extra `aooserver` flags as the `command` override in `compose.yaml`, or
append them after the image name in `docker run`:

```sh
docker run ... sonobus_aooserver -p 12000
```

Or in `compose.yaml`:

```yaml
    command: ["-p", "12000"]
```

Remember to update the `ports` mapping accordingly.

## Environment variables

The container entrypoint reads the following environment variables to
automatically assemble CLI arguments, avoiding the need to pass raw flags.

| Variable | Default | Description |
|---|---|---|
| `AOO_LOG_MODE` | `stdout` | Controls logging destination (see below) |
| `AOO_ENABLE_BLOCKLIST` | `false` | Set to `true` to load `/config/blocklist.txt` |

### `AOO_LOG_MODE`

| Value | Behaviour |
|---|---|
| `stdout` (default) | Logs appear only in the container log stream (`docker logs`) |
| `both` | Logs appear in the container log stream **and** in `/logs` |
| `file` | Logs are written only to `/logs` (container log stream is suppressed) |

When `both` or `file` is set, the entrypoint checks that `/logs` is an actual
mount point.  If it is not mounted, a warning is printed and file logging is
skipped to avoid silently storing logs inside the ephemeral container layer.

### `AOO_ENABLE_BLOCKLIST`

When set to `true`, the entrypoint passes `--blocklist /config/blocklist.txt`
to the server.  If the file does not exist (i.e. the volume is not mounted), a
warning is printed and the server starts without IP blocking.

## Volume mounts

| Mount | Purpose |
|---|---|
| `./logs:/logs` | Required when `AOO_LOG_MODE=both` or `AOO_LOG_MODE=file` |
| `./blocklist.txt:/config/blocklist.txt` | Required when `AOO_ENABLE_BLOCKLIST=true` |

Example `compose.yaml` with file logging and blocklist enabled:

```yaml
services:
  sonobus-aooserver:
    image: sonobus_aooserver
    restart: unless-stopped
    ports:
      - "10998:10998/udp"
      - "10998:10998/tcp"
    environment:
      AOO_LOG_MODE: both
      AOO_ENABLE_BLOCKLIST: "true"
    volumes:
      - ./logs:/logs
      - ./blocklist.txt:/config/blocklist.txt
```


# USAGE

`aooserver -h` will give you the usage info, which is very basic:

    aooserver -h|--help                 Prints the list of commands
    aooserver -l|--logdir logdirectory  Enables logging to file (also keeps stderr/stdout logging)
    aooserver --logfile-only            Suppress stderr/stdout when --logdir is active (log file only)
    aooserver -p|--port <server_port>   Specify the server port (default 10998)
    aooserver -b|--blocklist filename   File containing IP addresses to block

Logging behavior:
- No `--logdir`: logs appear only in the normal process log stream (stderr/stdout).
- `--logdir <dir>`: logs appear in both the normal process log stream **and** the log file.
- `--logdir <dir> --logfile-only`: logs are written only to the log file; the normal process log stream is suppressed.

You can specify a different port than the default that the server uses (this
is for both TCP and UDP). You can specify if timestamped log files should be
created in a particular directory. The blocklist lets you specify a file containing IP addresses
that the server should block from being allowed to be used. If a line has an IP address
followed by a comma and the word public (`1.2.3.4,public` for example), then it will allow 
the IP to be used for private groups, but not present any of the public groups to that user.

# SOURCE NOTES

The deps/aoo library dependency is a git subrepo (https://github.com/ingydotnet/git-subrepo), 
so all dependencies are alread included in this repository. 

JUCE is used here mostly as a hedge against future development, when
this server might have some additional audio processing capabilities. All
the JUCE source code necessary to build it is included in JuceLibraryCode,
as installed by ProJucer when using the aooserver.jucer as source. If you
want to contribute to further development or build for other platforms, you'll need to have 
JUCE 7 installed elsewhere.
