#!/bin/bash

if [ ! -d $HOME/ghdl ]
then
	mkdir $HOME/ghdl
	wget https://github.com/tgingold/ghdl/releases/download/2016-05-03/ghdl-0.34dev-mcode-2016-05-03.tgz -O - | tar xz -C $HOME/ghdl
fi

if [ ! -e $HOME/lib/libgnat-4.6.so.1 ]
then
	mkdir -p $HOME/lib
	wget http://mirrors.kernel.org/ubuntu/pool/universe/g/gnat-4.6/libgnat-4.6_4.6.4-0ubuntu5_amd64.deb -O /tmp/tmp.deb
	dpkg --fsys-tarfile /tmp/tmp.deb | tar xOf - ./usr/lib/x86_64-linux-gnu/libgnat-4.6.so.1 > $HOME/lib/libgnat-4.6.so.1
fi
export LD_LIBRARY_PATH=$HOME/lib:$LD_LIBRARY_PATH
