# Roadmap

The package is intended to become a small archive toolkit for NSIS installers.

Planned command surface:

- `extract` - extract a whole archive. Implemented.
- `extractFile` - extract one file or directory path from an archive.
- `create` - create an archive from a directory, for example to back up
  `htdocs` before repair or update flows.
- `add` - add one or more files to an existing archive.

Design goals:

- keep operations cancellable from the installer UI;
- keep the NSIS stack contract simple and explicit;
- support Polish and English installer text supplied by the caller;
- use proven archive tooling instead of reimplementing archive formats;
- keep the Unicode NSIS ABI as the primary supported variant.
