# aqua-unix

AQUA on Unix-like systems.

## Prerequisites

While not all of these packages are strictly necessary for all devices on all device branches, here they all are per OS if you want to install them for peace of mind.

### aquaBSD/FreeBSD

```console
pkg install git-lite icu libcjson librsvg2-rust libxcb mesa-libs pango pkgconf xcb xcb-util xcb-util-image xcb-util-wm
```

### Ubuntu

```console
sudo apt install libegl1-mesa-dev libpango1.0-dev libpng-dev librsvg2-dev libx11-xcb-dev libxcb-composite0-dev libxcb-ewmh-dev libxcb-icccm4-dev libxcb-image0-dev libxcb-randr0-dev libxcb-util-dev libxcb-xfixes0-dev libxcb-xinput-dev
```

### Steam Deck (Arch Linux)

```console
sudo steamos-readonly disable
sudo pacman-key --init
sudo pacman-key --populate archlinux
sudo pacman -Syu glibc linux-api-headers # reinstall, because some random files were removed by Valve
sudo pacman -Sy cairo cjson icu libglvnd libpng librsvg libxcb pango xcb-util xcb-util-image xcb-util-wm
sudo pacman -Sy gdk-pixbuf2 glib2 harfbuzz xorgproto # for some more missing headers
```

## Building

With [Bob the Builder](https://github.com/inobulles/bob) installed:

```console
bob test install
```

If you'd like to install a different device set (e.g. `aquabsd.alps`), run:

```console
DEVSET=aquabsd.alps bob test install
```

## Running

This will install the [KOS](https://github.com/inobulles/aqua-kos), [devices](https://github.com/inobulles/aqua-devices), and other AQUA dependencies automatically.
Read their respective instruction pages for more information.
