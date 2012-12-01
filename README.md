Spritz
====

Spritz is a tool for managing 2D assets. Currently its only feature is to create tiled atlas texture bitmaps, or sprite sheets, for drawing many sprites from a single, packed bitmap image. It's designed to be integrated into makefiles.

Installation
------------

    gem install spritz

Installation from source
------------------------

    rake install

Dependencies
------------

* Ruby 1.8.7 or later.
* ImageMagick 6.x.
* `textiletool` from iOS SDK, if you want to generate "pvrtc" textures.

Usage
-----

This will generate a `dungeon` package:

    spritz pack sheets/dungeon dungeon/*.png

The command will generate:

* `sheets/dungeon.0.png`, `sheets/dungeon.1.png` etc. — Texture bitmaps.
* `sheets/dungeon.json.gz` — A gzipped JSON file describing the necessary vertex and texture coordinates for each image, ready to be used with drawing functions.

For texture-mapping applications, you will want to specify `--padding 1` in order to ensure that texture coordinates round evenly to pixel coordinates.

The default texture size is 2048x2048, which corresponds to the largest texture size allowed on the current generation of iOS devices.

If an image does not fit within a single texture, it will be split across multiple textures. In other words, there is no upper limit on the dimensions of any image.

Package format
--------------

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

License
-------

See accompanying `LICENSE` file.
