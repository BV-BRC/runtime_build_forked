#!/bin/bash

function error() {
  local parent_lineno="$1"
  local message="$2"
  local code="${3:-1}"
  if [[ -n "$message" ]] ; then
    echo "Error on or near line ${parent_lineno}: ${message}; exiting with status ${code}"
  else
    echo "Error on or near line ${parent_lineno}; exiting with status ${code}"
  fi
  exit "${code}"
}

trap 'error ${LINENO}' ERR

target=${TARGET-/kb/runtime}

if [ $# -gt 0 ] ; then
	target=$1
	shift
fi

#
# Set up for inclusion of runtime-installed dynamic libs.
#
export CFLAGS="-I$target/include"
export LDFLAGS="-I$target/lib -Wl,-rpath,$target/lib"

if [ -x $target/bin/python ] ; then
    python=$target/bin/python
else
    python=python
fi

is_mac=0
if [ -d /Library -a "$MAC_32BIT" != "" ] ; then
    export CC="gcc -m32"
    export CXX="g++ -m32"
    export CFLAGS="-I$dest/include"
    export LDFLAGS="-L$dest/lib"
    is_mac=1
fi

have_r=0
if [ -x $target/bin/R ] ; then
	have_r=1
fi

#curl -L -k http://python-distribute.org/distribute_setup.py | $python

#curl -k -L https://bitbucket.org/pypa/setuptools/raw/bootstrap/ez_setup.py | $python

# curl -k -L https://bootstrap.pypa.io/2.7/get-pip.py | $python

curl -k -L https://bootstrap.pypa.io/pip/2.7/get-pip.py | $python

if [ -x $target/bin/pip ] ; then
	pip="$target/bin/pip"
else
	pip="pip"
fi

if [ -x $target/bin/easy_install ] ; then
	easy_install="$target/bin/easy_install"
else
	easy_install="easy_install"
fi


if  mysql_config --version >/dev/null 2>/dev/null ; then
	have_mysql=1
else
	have_mysql=0
fi

# 
# Mysql build doesn't work on Centos*
#
if grep -s 'release 8' /etc/centos-release > /dev/null; then
	have_mysql=0
fi
if grep -s 'Ubuntu' /etc/lsb-release > /dev/null; then
	have_mysql=0
fi

save_cflags=$CFLAGS
save_ldflags=$LDFLAGS
for P in `cat ./python-pip-list`; do
	if [ $P = "MySQL-python" -a $have_mysql -eq 0 ] ; then
		echo "Skipping $P: no mysql available"
	elif [ $P = "mpi4py" -a $is_mac = 1 ] ; then
	    echo "Skipping $P on mac"
	elif [ $P = "rpy2" -a $have_r = 0 ] ; then
	    echo "Skipping $P - no R installed"
	else

               if [ $P = "numpy" -o $P = "scipy" ] ; then
                       unset CFLAGS
                       unset LDFLAGS
               fi

		echo "$pip installing $P"
		$pip install $P --upgrade

		export CFLAGS=$save_cflags
                export LDFLAGS=$save_ldflags


	fi
done

for P in `cat ./python-easy-list`; do
	echo "easy_installing $P"
	$easy_install $P
done

if [ -d "/usr/local/lib/python2.7/dist-packages" ] ; then
	rm -rf /usr/local/lib/python2.7/dist-packages/django_piston-0.2.3-py2.7*
fi

