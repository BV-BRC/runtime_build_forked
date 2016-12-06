#!/bin/sh
set -x

target=${TARGET-/kb/runtime}

if [[ $# -gt 0 ]] ; then
        target=$1
        shift
fi


wget http://ftp.gnu.org/gnu/bison/bison-2.5.1.tar.gz
tar xvf bison-2.5.1.tar.gz
cd bison-2.5.1
./configure --prefix=$target
make
make install
cd ..
