[![CI](https://github.com/equalitie/ouisync-app/actions/workflows/ci.yml/badge.svg)](https://github.com/equalitie/ouisync-app/actions/workflows/ci.yml)
[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)
![Android](https://img.shields.io/badge/Android-3DDC84?style=flat-squarte&logo=android&logoColor=white)
![Windows](https://img.shields.io/badge/Windows-0078D6?style=flat-squarte&logo=windows&logoColor=white)

# Ouisync Flutter app

**Secure file-sharing and real-time sync, with or without internet.**

**Ouisync** is a free and open source tool enabling peer-to-peer file syncing between devices. For more information, please visit the project's home page at https://ouisync.net.

This repository implements the GUI for the **[Ouisync library](https://github.com/equalitie/ouisync)**.

Currently supported operating systems are Android, Windows and Linux.

## Git clone

This repository uses git submodules. As such, use the following commands to clone it locally:

```bash
git clone https://github.com/equalitie/ouisync-app 
git submodule update --init --recursive
```

## Compilation

You'll need [Flutter](https://docs.flutter.dev/get-started/install), [Rust](https://www.rust-lang.org/tools/install) and other dependencies corresponding to the target platform:

* Windows: [Dokan](https://github.com/dokan-dev/dokany/releases) (User mode file system)
* Android: [SDK](https://developer.android.com/) and [NDK](https://developer.android.com/studio/projects/install-ndk)
* Linux: `sudo apt-get install pkg-config libfuse-dev appindicator3-0.1 libsecret-1-dev`

Then to build the app:

```bash
flutter pub get
flutter <build|run> -d <windows|android|linux>
```

## Docker

We have *Dockerfiles* for
[**Linux**](https://github.com/equalitie/ouisync-app/blob/master/docker/dev/linux/Dockerfile)
and
[**Windows**](https://github.com/equalitie/ouisync-app/blob/master/docker/dev/windows/Dockerfile)
which contain the development environment although at time of writing they are
somewhat outdated (TODO). 

   - If your development platform is Linux, you can use the Dockerfile to
     create the Linux desktop or the Android app.
   
   - Similarly, you can use the Windows Dockerfile to create the Windows
     desktop or the Android app. 

## Sentry (optional)

**Ouisync** integrates **Sentry**, via the `sentry_flutter` plugin. 

For initialization, you need to get a client key, called **DSN**, from a **Sentry** instance, making it available via an `.env` file, or as a environment variable using `export`, and then using [envied](https://github.com/petercinibulk/envied)

Please follow the instructions in the package repository for [envied in GitHub](https://github.com/petercinibulk/envied#table-of-contents) to add a key called `DSN`, that contains the client key.

## Troubleshooting

### Specify paths to sub-commands: **`rustc`** and **`cargo`**

The **[Ouisync Flutter plugin](https://github.com/equalitie/ouisync-plugin)**, that provides the API for using the **[Ouisync library](https://github.com/equalitie/ouisync)** that is written in **`Rust`**, uses **`Cargo`** for building it.

If building the app in your computer you encounter this error:

```
FAILURE: Build failed with an exception.

* What went wrong:
Execution failed for task ':ouisync_plugin:cargoBuildArm'.
> A problem occurred starting process 'command 'rustc''

* Try:
Run with --stacktrace option to get the stack trace. Run with --info or --debug option to get more log output. Run with --scan to get full insights.

* Get more help at https://help.gradle.org

BUILD FAILED in 2s
```

It means that **`Gradle`** can't find **`rustc`** when trying to run the command to build the plugin.

To fix this, add the following to the `local.properties` file located in the `android` folder of the app project (`~/android/local.properties`):

```
rust.rustcCommand=<path-to-user-folder>/.cargo/bin/rustc
rust.cargoCommand=<path-to-user-folder>/.cargo/bin/cargo
```

Don't forget to replace `<path-to-user-folder>` with the path to your user folder.

<br />

## How to add localized strings

We use the package **intl_utils** for handling the localization of the strings used in the app.

To add a new localized string, modify the [English `.arb` file](lib/l10n/intl_en.arb), and run:

```bash
dart run intl_utils:generate
```

Then use it as such:

```
import '../../../generated/l10n.dart';

...
...
...

Text(S.current.hello);
```


**NOTE:** For translations to any other language, please create a new issue in this repository, so we can take care of it.
