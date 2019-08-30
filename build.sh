#!/bin/bash

case $1 in
   release)
      gprclean -P hunter.gpr
      gprbuild -P hunter.gpr -XMode=release
      mkdir -p usr/share/docs
      mkdir -p usr/share/locale
      cp -r bin usr/
      cp CHANGELOG.md usr/share/docs/
      cp COPYING usr/share/docs/
      cp README.md usr/share/docs
      for directory in $(find po/* -maxdepth 0 -type d)
      do
         cp -r $directory usr/share/locale/
         rm usr/share/locale/${directory:3}/hunter.po
      done
      gprclean -P hunter.gpr
      ;;
   debug)
      gprclean -P hunter.gpr
      gprbuild -P hunter.gpr
      ;;
   createtests)
      gnattest -P hunter.gpr
      ;;
   tests)
      gprbuild -P tests/driver/test_driver.gpr
      ;;
   docs)
      ./generatedocs.py
      ;;
   help)
      echo "release       - Build the game in release mode"
      echo "debug         - Build the game in debug mode"
      echo "createtests   - Regenerate unit tests"
      echo "tests         - Build unit tests"
      echo "docs          - Generate code documentation"
      echo "help          - This screen"
      ;;
   *)
      echo "Unknown command, possible options are: release, debug, createtests, tests, docs, help"
      ;;
esac
