# DHLabel AppImage

Build an AppImage from the latest [DHLabel](https://github.com/manfred-mueller/DHLabel) Windows release:

```sh
make
```

The result is `dist/DHLabel-<version>-x86_64.AppImage`. Run it with:

```sh
./dist/DHLabel-<version>-x86_64.AppImage
```

The builder downloads the latest DHLabel setup executable and a portable x86-64 Wine build, installs DHLabel into a temporary Wine prefix, and packages the application with Wine and its runtime data. User settings and the Wine prefix persist under `~/.local/share/DHLabel/wineprefix`.

Requirements on the build host:
- Linux x86-64
- `curl`
- `python3`
- `tar`
