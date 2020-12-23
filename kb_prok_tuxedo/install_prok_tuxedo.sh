#!/bin/bash

target=${TARGET-/kb/runtime}

if [ $# -gt 0 ] ; then
	target=$1
fi

#wget --no-check-certificate -P ${target}/bin https://github.com/aswarren/Prok-tuxedo/raw/master/prok_tuxedo.py
rm -rf Prok-tuxedo
git clone https://github.com/olsonanl/Prok-tuxedo.git
#git clone https://github.com/aswarren/Prok-tuxedo.git
cd Prok-tuxedo
#git checkout contrasts
cp prok_tuxedo.py ${target}/bin/
cp cuffdiff_to_genematrix.py ${target}/bin/

chmod a+x ${target}/bin/prok_tuxedo.py
chmod a+x ${target}/bin/cuffdiff_to_genematrix.py
