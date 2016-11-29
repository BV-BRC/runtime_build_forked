#!/bin/bash

target=${TARGET-/kb/runtime}

if [ $# -gt 0 ] ; then
        target=$1
        shift
fi




wget http://www.openssl.org/source/openssl-1.0.2f.tar.gz
tar -zxf openssl-1.0.2f.tar.gz
pushd openssl-1.0.2f
./config --prefix=$target
make
make install
popd

wget ftp://ftp.csx.cam.ac.uk/pub/software/programming/pcre/pcre-8.39.tar.gz
tar -zxf pcre-8.39.tar.gz

wget http://zlib.net/zlib-1.2.8.tar.gz
tar -zxf zlib-1.2.8.tar.gz

wget http://nginx.org/download/nginx-1.11.6.tar.gz
tar zxf nginx-1.11.6.tar.gz

pushd nginx-1.11.6

./configure		\
	--prefix=$target/nginx		\
	--with-pcre=../pcre-8.39	\
	--with-zlib=../zlib-1.2.8	\
	--with-http_ssl_module		\
	--with-ld-opt="-L $target/lib"	\
	--with-stream			\
	--with-mail=dynamic

make
make install

popd
