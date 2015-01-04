# Spritz

Spritz is a tool for working with raw 2D assets to generate packed ones.

Spritz can take a bunch of images and create tiled atlas texture bitmaps (also known as sprite sheets) for drawing many sprites from a single, packed bitmap image.

## Features

* Easily integrates into makefiles.
* Writes easily readable JSON.
* Supports all image formats supported by ImageMagick (ie., a lot).
* Supports outputting to PNG and iOS `pvrtc` (includ gzipped) formats.
* Can generates setup code for Moai.

## Installation

    gem install spritz

## Installation from source

    rake install

## Dependencies

* Ruby 1.8.7 or later.
* ImageMagick 6.x.
* `textiletool` from iOS SDK, if you want to generate `pvrtc` textures.

## Usage

This will generate a `dungeon` package:

    spritz pack sheets/dungeon dungeon/*.png

The command will generate:

* `sheets/dungeon.0.png`, `sheets/dungeon.1.png` etc. — the texture bitmaps.
* `sheets/dungeon.json.gz` — a gzipped JSON file describing the necessary vertex and texture coordinates for each image, ready to be used with drawing functions.

For more options:

    spritz pack --help

## Plugins

### Moai

To generate a quad deck for [Moai](http://getmoai.com), use the option:

    --moai:quad-decks myfile.lua

## Tips

For texture-mapping applications, you will want to specify `--padding 1` in order to ensure that texture coordinates round evenly to pixel coordinates.

The default texture size is 2048x2048, which corresponds to the largest texture size allowed on the current generation of iOS devices.

If an image does not fit within a single texture, it will be split across multiple textures. In other words, there is no upper limit on the dimensions of any image.

## Package format

The format of the package JSON file is:

* `version`: File format version. Currently 1.
* `textures`: A hash of textures, indexed by a numeric key.
* `images`: A hash of image slices for each file. (An image will have multiple slices if its dimensions exceed the maximum texture dimensions.)

Each texture hash has the following format:

* `file`: File name, relative to the JSON file.
* `format`: The format, eg. `png`.

Each image hash has the following format:

* `i`: The index of the texture, which can be looked up in the `textures` key.
* `v`: The vertex coordinates for this slice.
* `t`: The texture coordinates for this slice.
* `w`: The width of the slice.
* `h`: The haight of the slice.
* `r`: Will be `true` if rotated -90 degrees.

## Credits

The "MaxRects" algorithm was ported from C++ code originally by Jukka Jylänki.

## License

See accompanying `LICENSE` file.
