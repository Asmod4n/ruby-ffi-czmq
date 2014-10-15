#!/bin/sh
set -ex
LIBSODIUM_RELEASE="1.0.0"
gpg --keyserver hkp://keys.gnupg.net --recv-keys 1CDEA439
curl -O https://download.libsodium.org/libsodium/releases/libsodium-$LIBSODIUM_RELEASE.tar.gz
curl -O https://download.libsodium.org/libsodium/releases/libsodium-$LIBSODIUM_RELEASE.tar.gz.sig
gpg --verify libsodium-$LIBSODIUM_RELEASE.tar.gz.sig
tar xzf libsodium-$LIBSODIUM_RELEASE.tar.gz
cd libsodium-$LIBSODIUM_RELEASE/
./configure
make check
sudo make install
sudo ldconfig
