#!/bin/bash

set -ex

# Enter temporary directory.
pushd /tmp

# Install DFINITY SDK.
wget --output-document install-dfx.sh "https://internetcomputer.org/install.sh"
DFX_VERSION=${DFX_VERSION:=0.25.0} bash install-dfx.sh < <(yes Y)
rm install-dfx.sh
dfx cache install

# Install ic-repl
version=0.3.10
curl --location --output ic-repl "https://github.com/chenyan2002/ic-repl/releases/download/$version/ic-repl-linux64"
mv ./ic-repl /usr/local/bin/ic-repl
chmod a+x /usr/local/bin/ic-repl

# Install matchers
matchers_version=1.2.0
curl -fsSLO "https://github.com/kritzcreek/motoko-matchers/archive/refs/tags/v${matchers_version}.tar.gz"
tar -xzf "v${matchers_version}.tar.gz" --directory "$(dfx cache show)"
rm "v${matchers_version}.tar.gz"
mv "$(dfx cache show)/motoko-matchers-${matchers_version}" "$(dfx cache show)/motoko-matchers"

# Install wasmtime
wasmtime_version=8.0.0
curl -fsSLO "https://github.com/bytecodealliance/wasmtime/releases/download/v${wasmtime_version}/wasmtime-v${wasmtime_version}-x86_64-linux.tar.xz"
mkdir -p "${HOME}/bin"
tar -xf "wasmtime-v${wasmtime_version}-x86_64-linux.tar.xz" --directory "${HOME}/bin/"
mv "${HOME}/bin/wasmtime-v${wasmtime_version}-x86_64-linux/wasmtime" "${HOME}/bin/wasmtime"
rm "wasmtime-v${wasmtime_version}-x86_64-linux.tar.xz"

# Set environment variables.
echo "$HOME/bin" >> $GITHUB_PATH
echo "$HOME/.cargo/bin" >> $GITHUB_PATH

# Exit temporary directory.
popd
