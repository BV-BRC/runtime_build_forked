#!/usr/bin/env bash

# set up for freebayes 

# build script for bamtools

target=${TARGET-/usr/local}

if [[ $# -ne 0 ]] ; then
        target=$1
        shift
fi

if [[ -x "/usr/bin/apt-get" ]] ; then
apt-get update
apt-get install -y build-essential
apt-get install -y git
apt-get install -y cmake
apt-get install -y libncurses5-dev
apt-get install -y libncurses5
apt-get install -y dh-autoreconf
apt-get install -y pkg-config
fi


rm -rf freebayes
#
# Use the PATRIC for since it fixes paths in freebayes-parallel
#
git clone --recursive https://github.com/PATRIC3/freebayes.git

pushd freebayes
make
# make install
mkdir -p $target/bin
cp bin/freebayes bin/bamleftalign $target/bin/

#
# Copy some other scripts out as well.
#
cp scripts/freebayes-parallel $target/bin/freebayes-parallel
chmod +x $target/bin/freebayes-parallel
cp scripts/fasta_generate_regions.py $target/bin/fasta_generate_regions.py
chmod +x $target/bin/fasta_generate_regions.py
cp vcflib/scripts/vcffirstheader $target/bin/vcffirstheader
chmod +x $target/bin/vcffirstheader

popd
