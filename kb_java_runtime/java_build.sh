#!/bin/sh

# usage: 
#   build_java.sh
#   build_java.sh /kb/runtime
#   build_java.sh -u /kb/runtime
#
# general form:
#  build_java.sh -u <target>
#
# -u 		is optional, it will over-ride java restricted
# <target> 	is optional, it will default to /kb/runtime
restricted="restricted"
while getopts u opt; do
  case $opt in
    u)
      echo "-u was triggered, overridding restricted"
      shift
      restricted="unrestricted"
      ;;
    \?)
      echo "invalid option: -$OPTARG"
      ;;
  esac
done


target=${TARGET-/kb/runtime}
if [ $# -ne 0 ] ; then
	target=$1
	shift
fi
echo "using $target as runtime"

mkdir -p $target/lib

#
# We don't install this version on the mac; we use the one that
# came with the system.
#
if [ -d /Library/Java/Home ] ; then
    echo "Not installing java (Mac)"
elif [ -x /usr/libexec/java_home ] ; then
    echo "Not installing java (found in /usr/libexec/java_home)"
elif [ -x /usr/bin/java ] ; then
    echo "System java found"
else
	echo "Install JDK, restricted set to $restricted"
	if [ "$restricted" = unrestricted ] ;
	then
	  #cleanup old
	  rm -rf $target/jdk1.6*
	  rm -rf $target/jdk1.7*
	  rm -rf $target/jdk1.8*
	  rm $target/java
	  find /$target/bin -xtype l -delete
	  #install new 
	  tar zxvf jdk-8u66-linux-x64.tar.gz -C $target
	  ln -s $target/jdk1.8.0_66 $target/java
	  ln -s $target/jdk1.8.0_66/bin/* $target/bin/
	else
	  echo "This component is restricted, please download the tarball from the rights holder."
	fi
	export JAVA_HOME=$target/java
fi


