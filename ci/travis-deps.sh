#!/bin/bash
if uname | grep Linux > /dev/null
then
	if ! [ -e "$HOME"/ghdl/bin/ghdl ]
	then
		mkdir -p "$HOME"/ghdl
		wget -q https://github.com/tgingold/ghdl/releases/download/2016-05-03/ghdl-0.34dev-mcode-2016-05-03.tgz -O - | tar xz -C "$HOME"/ghdl || exit 1
	fi

	if ! [ -e "$HOME"/lib/libgnat-4.6.so.1 ]
	then
		mkdir -p "$HOME"/lib
		wget -q http://mirrors.kernel.org/ubuntu/pool/universe/g/gnat-4.6/libgnat-4.6_4.6.4-0ubuntu5_amd64.deb -O /tmp/tmp.deb || exit 1
		dpkg --fsys-tarfile /tmp/tmp.deb | tar xOf - ./usr/lib/x86_64-linux-gnu/libgnat-4.6.so.1 > "$HOME"/lib/libgnat-4.6.so.1 || exit 1
	fi
elif uname | grep CYGWIN > /dev/null
then
	if ! unzip -v >/dev/null 2>&1
	then
		echo unzip is requiered, please install it.
		exit 1
	fi

	if ! wget --version >/dev/null 2>&1
	then
		echo wget is requiered, please install it.
		exit 1
	fi

	if ! [ -e "$HOME"/ghdl/bin/ghdl ]
	then
		mkdir -p "$HOME"
		pushd "$HOME"
		rm -rf ghdl
		wget -q https://github.com/tgingold/ghdl/releases/download/v0.33/ghdl-0.33-win32.zip
		unzip ghdl-0.33-win32.zip >/dev/null 2>&1
		mv ghdl-0.33 ghdl/
		chmod +x ghdl/bin/ghdl
		popd
	fi
else
	echo unsupported OS
fi
