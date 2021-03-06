Hunter is a graphical file manager for Linux, inspired by [Ranger](https://ranger.github.io/).
At this moment, Hunter is under development and have all basic features
of a file manager. To open files, the program uses default applications
from [XDG MIME Application Specification](https://specifications.freedesktop.org/mime-apps-spec/mime-apps-spec-latest.html).

**Note:** This version of README.md is about development version of the
program. Some things may be different in released version of Hunter.

## Features

- Two column mode default or one column mode: One column always show files
  and directories, second column is used to preview files and directories
  or select destination location for move or copy files. In one column
  mode, second column appear only when copying or moving files or directories.
- Everything in one window.
- Preview of text files (with syntax highlighting) and images.
- Standard file manager features: copy, delete, move files and directories,
  change their permissions, change application associated with them.
- Written in GTK and Ada. Should nicely integrate with selected desktop theme.
- Available in English and Polish language

## Build the program from sources

To build you need:

* compiler - GCC with enabled Ada support or (best option) GNAT from:

  https://www.adacore.com/download/

  It is recommended to use GNAT GPL 2019 to compile the program.
  The program does not work with old compilers (like GCC 4.9) since it
  lacks full support for Ada 2012.

* GtkAda library which should be available in most Linux distributions. Best
  option is to use (with GNAT GPL) AdaCore version of GtkAda from:

  https://www.adacore.com/download/more

  At this moment tested version of GtkAda is 2019 and the program require GTK
  library in version 3.14 (may not works with other versions).

* File command (libmagic) development files. It can have different names in
  every Linux distribution: in Fedora it is *file-devel* on Debian/Ubuntu/Mint
  *file-dev*.

If you have all the required packages, navigate to the main directory(where
this file is) to compile:

* Easiest way to compile the program is use Gnat Programming Studio included
  in GNAT. Just run GPS, select *hunter.gpr* as a project file and select
  option `Build All`.

* If you prefer using console: in main source code directory type
  `gprbuild -P hunter.gpr` for debug mode build or for release mode:
  `gprbuild -P hunter.gpr -XMode=release`. If you have installed
  [Bob](https://github.com/thindil/bob) you can type `bob debug` for build in
  debug mode or `bob release` to prepare release for the program.


## Running Hunter

If you use downloaded AppImage version, you don't need any additional
libraries. Just run it as any AppImage file. More informations about AppImage
files usage, you can find at:

https://docs.appimage.org/user-guide/run-appimages.html

When you trying to run build by yourself version of the program, use script
`hunter.sh`. The program will not works if you try to start it by binary file
`hunter` from `bin` directory. To work the program needs scripts *xdg-open*
and *xdg-mime*. In most Linux distributions they are in *xdg-utils* package.
Additionally, to coloring syntax in text files preview, the program needs
other program: *highlight* which should be available in most Linux
distributions. If you don't have that program installed, coloring syntax
option will be disabled.

### Starting parameter

You can set directory to view when starting the program by adding it full path
to the starting command. For example, to view root directory `/` run the
program with `hunter.sh /`

### Wrong theme used by the program

Hunter uses GTK library in version 3.14. Your selected theme probably don't
support this version of GTK or don't have compiled support for it. In this
second situation, please check documentation of selected theme to find how to
recompile it. If your theme completely don't support GTK in version 3.14 you
can still use default GTK theme by adding environment variable `GTK_THEME`.
For example: `GTK_THEME=Adwaita ./hunter-x86-64.AppImage`.

### Testing versions

Here are available also testing versions of the program. You can find them
in [Releases](https://github.com/thindil/hunter/releases/tag/travis-dev-build).
To use them, first you must download normal release. Then, inside directory
where the program is, type `./hunter-x86_64.AppImage --appimage-extract` to
extract whole program to directory *squashfs-root*. And then just move files
from the archive to proper locations. To run that version, just enter
*squashfs-root* directory and type in console `./AppRun`.

## Generating code documentation

To generate (or regenerate) code documentation, you need [ROBODoc](https://rfsber.home.xs4all.nl/Robo/)
If you have it, in main program directory (where this file is) enter terminal
command: `others/generatedocs.py`. For more information about this script,
please look [here](https://github.com/thindil/roboada#generatedocspy). This
version of script have set all default settings for Hunter code. If you have
[Bob](https://github.com/thindil/bob) installed, you can type `bob docs`.

## Contributing to the project
For detailed informations about contributing to the project (bugs reporting,
ideas propositions, code conduct, etc), see [CONTRIBUTING.md](CONTRIBUTING.md)

## Licenses
Hunter is available under [GPLv3](COPYING) license.

xdg-mime and xdg-open scripts distributed with the program are part of the
xdg-utils project and released under MIT license:

https://github.com/freedesktop/xdg-utils

GtkAda library distributed with the program are under GPLv3 license.

https://github.com/AdaCore/gtkada

Gtk library distributed with the program is under LGPLv2.1 license:

https://www.gtk.org/

Highlight program distributed with the program is under GPLv3 license.

http://www.andre-simon.de/doku/highlight/en/highlight.php

----

That's all for now, and again, probably I forgot about something important ;)

Bartek thindil Jasicki
