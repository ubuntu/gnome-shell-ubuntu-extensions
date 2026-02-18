# GNOME Shell Ubuntu Extensions

This repository aggregates a set of GNOME Shell extensions used in ubuntu,
and manages them via Meson subprojects.

All extensions are enabled by default.

Included extensions:
- [AppIndicators](https://github.com/ubuntu/gnome-shell-extension-appindicator)
- [Desktop Icons NG](https://gitlab.com/rastersoft/desktop-icons-ng)
- [Dash to Dock](https://github.com/micheleg/dash-to-dock)
- [Tiling Assistant](https://github.com/Leleat/Tiling-Assistant)
- [Web Search Provider](https://gitlab.gnome.org/Community/Ubuntu/gnome-shell-web-search-provider)
- [Snapd Search Provider](https://gitlab.gnome.org/Community/Ubuntu/gnome-shell-snapd-search-provider)

## Quick start

```sh
meson setup _build
meson compile -C _build
sudo meson install -C _build
```

## Managing extensions

Extensions must be added using meson subprojects, via
[wrap files](https://mesonbuild.com/Wrap-dependency-system-manual.html).

Wrap files live under `subprojects/*.wrap`.

They must updated them to point to different releases.

## Packaging

This project is intended to integrate to be used with `git-buildpackage` tool
in order to update the subprojects and build debian packages.

    # Build a source package
    gbp buildpackage -S

    # Build the binary package
    gbp buildpackage -b # [ ... further builder options ]

Further package-related documentation in [`debian/README.source`](debian/README.source).
