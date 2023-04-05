# mach/gamemode - leverage Linux gamemode from Zig

`mach/gamemode` allows Linux games written in Zig to _request gamemode be enabled_ if the user's machine already has it installed/present. Otherwise, it simply does nothing (there are no dependencies and your game will still run on all Linux machines that do not have gamemode installed.)

This is preferred as it means your game will automatically invoke gamemode for the user when running, rather than them having to manually enable it.

This repository is a separate copy of the same library in the [main Mach repository](https://github.com/hexops/mach), and is automatically kept in sync, so that anyone can use this library in their own project if they like!

## What is Linux GameMode?

Used by titles such as DiRT 4, and many Tomb Raider and Total War games, [GameMode](https://github.com/FeralInteractive/gamemode) is a daemon/lib combo for Linux that allows games to request a set of optimisations be temporarily applied to the host OS and/or a game process, including:

>     CPU governor
>     I/O priority
>     Process niceness
>     Kernel scheduler (SCHED_ISO)
>     Screensaver inhibiting
>     GPU performance mode (NVIDIA and AMD), GPU overclocking (NVIDIA)
>     Custom scripts

GameMode packages are available for Ubuntu, Debian, Solus, Arch, Gentoo, Fedora, OpenSUSE, Mageia and possibly more.

## Join the community

Join the Mach community [on Discord](https://discord.gg/XNG3NZgCqp) to discuss this project, ask questions, get help, etc.

## Issues

Issues are tracked in the [main Mach repository](https://github.com/hexops/mach/issues?q=is%3Aissue+is%3Aopen+label%3Agamemode).

## Contributing

Contributions are very welcome. Pull requests must be sent to [the main repository](https://github.com/hexops/mach/tree/main/libs/gamemode) to avoid some complex merge conflicts we'd get by accepting contributions in both repositories. Once the changes are merged there, they'll get sync'd to this repository automatically.
