#!/bin/bash

if [ -e $HOME/ghdl/bin/ghdl ]
then
	echo Using cached ghdl
else
	mkdir -p $HOME/ghdl
	wget -q https://github.com/tgingold/ghdl/releases/download/2016-05-03/ghdl-0.34dev-mcode-2016-05-03.tgz -O - | tar xvz -C $HOME/ghdl
fi

if [ -e $HOME/lib/libgnat-4.6.so.1 ]
then
	echo Using cached libgnat
else
	mkdir -p $HOME/lib
	wget -q http://mirrors.kernel.org/ubuntu/pool/universe/g/gnat-4.6/libgnat-4.6_4.6.4-0ubuntu5_amd64.deb -O /tmp/tmp.deb
	dpkg --fsys-tarfile /tmp/tmp.deb | tar xOf - ./usr/lib/x86_64-linux-gnu/libgnat-4.6.so.1 > $HOME/lib/libgnat-4.6.so.1
fi