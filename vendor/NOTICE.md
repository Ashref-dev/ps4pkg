# Third-party source included in this repository

`ps4pkg` bundles the code it needs so that installing it never depends on
another project staying online. Everything here belongs to its original
authors and is redistributed under its original license.

## `shadps4/`

- **Origin:** https://github.com/AzaharPlus/shadPS4Plus
- **Commit:** `9d2e76127ce32d13192f9a6ab84a96404677394a`
- **License:** GNU General Public License v2.0 (see `shadps4/LICENSE`)
- **Upstream of that project:** https://github.com/shadps4-emu/shadPS4

This is the PKG handling code that used to live inside shadPS4, together with
the standalone `extractor/main.cpp` entry point from ShadPs4Plus.

Only the files required to build the extractor are included. The rest of the
emulator is not present.

### Modifications

1. `src/common/io_file.cpp` — `IOFile::Seek` calls `fseeko64`, which exists on
   Linux but not on macOS, where `fseeko` is already 64-bit. The call is now
   selected with `#ifdef __APPLE__`. Behaviour on other platforms is unchanged.

No other source file has been altered.

## `cryptopp/`

- **Origin:** https://github.com/shadps4-emu/ext-cryptopp
- **Commit:** `effed0d0b865afc23ed67e0916f83734e4b9b3b7`
- **License:** Boost Software License 1.0 (see `cryptopp/License.txt`)

Unmodified. The `TestVectors/` and `TestData/` directories (about 15 MB of test
fixtures not needed to build the library) are omitted.

## `CMakeLists.txt`

Written for this repository to build the vendored sources on macOS. The
original ShadPs4Plus build file expected a different directory layout and a
Windows/Linux toolchain.
