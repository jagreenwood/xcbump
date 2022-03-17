# xcbump

`xcbump` is a small cli utility which will bump the build number of an Xcode project. It can optionally explicitly set version, build, and tag HEAD.

### 🌱 Mint (recommended)

`mint install jagreenwood/xcbump`

### ⚙️ Manual

Clone this repo and build the executable:

`swift build -c release xcbump`

Copy the resulting binary at `.build/release/xcbump` to a location where it can be executed like `/usr/local/bin` 

### Usage

```
OPTIONS:
  --path <path>           Path of the project file
  --version <version>     Specific version to use
  --build <build>         Specific build to use
  --tag                   Specifies whether version bump should be commited and tagged
  -h, --help              Show help information.
```

Issuing the command `xcbump` from the command line will attempt to find a `.xcodeproj` file at the current path. If the Xcode project is not at the current path, use the `--path` option.

By default, only the build number is bumped. For example if build is currently 5, it will be 6 after running `xcbump`. Build number can be explicitly set with `--build` option.

Use the `--tag` option to tag HEAD with version and build number for example "2.0.1(6)". The structure of the tag is currently hardcoded as <version>(<build>). 
