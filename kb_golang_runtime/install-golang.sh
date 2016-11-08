#!/bin/bash

if [ $# -gt 0 ] ; then
	DIR=$1
else
	DIR=${TARGET-/kb/runtime}
fi

#
# In order to build the latest we need to install a bootstrap compiler and
# then build the real one.
#

bootstrap=https://storage.googleapis.com/golang/go1.4.3.src.tar.gz
bootstrap_tar=`basename $bootstrap`

latest=https://storage.googleapis.com/golang/go1.6.src.tar.gz
latest_tar=`basename $latest`

here=`pwd`

rm -rf go
curl -O -L $bootstrap
tar xzfp $bootstrap_tar
mv go go_bootstrap
(cd go_bootstrap/src; ./all.bash)
export GOROOT_BOOTSTRAP=$here/go_bootstrap
export GOROOT_FINAL=$DIR/go

curl -O -L $latest

tar xzfp $here/$latest_tar

cd go/src
./all.bash

cd $here
rm -rf $DIR/go
rsync -arv go $DIR

for B in `ls $DIR/go/bin`; do
	if [ -e ${DIR}/bin/$B ] ; then
		rm ${DIR}/bin/$B
	fi
	ln -s $DIR/go/bin/$B ${DIR}/bin
done

cd $here
export GOPATH=${DIR}/gopath
if [ ! -e $GOPATH ]; then
	mkdir $GOPATH
fi

for P in `cat ./golang-packages`; do
	$DIR/bin/go get -v $P
done


