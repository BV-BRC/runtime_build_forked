#!/bin/sh

# usage: 
#   java_package_build [/runtime-dir]
#
# <target> 	is optional, it will default to /kb/runtime

target=${TARGET-/kb/runtime}
if [ $# -ne 0 ] ; then
	target=$1
	shift
fi
echo "using $target as runtime"

mkdir -p $target/lib

echo "Install Ant"
v=1.9.7
curl -O http://apache.cs.utah.edu//ant/binaries/apache-ant-$v-bin.tar.gz

rm -rf $target/apache-ant*
rm $target/ant
tar zxvf apache-ant-$v-bin.tar.gz -C $target
if [ $? -ne 0 ] ; then
	echo "Failed to unpack ant" 1>&2
	exit 1
fi
ln -s $target/apache-ant-$v $target/ant
ln -s $target/ant/bin/ant $target/bin/ant

echo "Install Ivy"
curl -O http://apache.cs.utah.edu//ant/ivy/2.4.0/apache-ivy-2.4.0-bin.tar.gz
rm -rf $target/apache-ivy*
tar zxvf apache-ivy-2.4.0-bin.tar.gz -C $target
if [ $? -ne 0 ] ; then
	echo "Failed to unpack ivy" 1>&2
	exit 1
fi
ln -s $target/apache-ivy-2.4.0/ivy-2.4.0.jar $target/ant/lib/.

echo "Install Maven"
curl -f -O http://apache.cs.utah.edu/maven/maven-3/3.3.9/binaries/apache-maven-3.3.9-bin.tar.gz
# curl -O http://apache.mirrorcatalogs.com/maven/maven-3/3.3.9/binaries/apache-maven-3.3.9-bin.tar.gz
rm -rf $target/apache-maven*
tar zxvf apache-maven-3.3.9-bin.tar.gz -C $target
if [ $? -ne 0 ] ; then
	echo "Failed to unpack maven" 1>&2
	exit 1
fi
ln -s $target/apache-maven-3.3.9/bin/mvn $target/bin/mvn

echo "Install tomcat"
v=7.0.73
curl -f -O "ftp://apache.cs.utah.edu/apache.org/tomcat/tomcat-7/v$v/bin/apache-tomcat-$v.tar.gz"
rm -rf $target/tomcat*
tar zxvf apache-tomcat-$v.tar.gz -C $target
if [ $? -ne 0 ] ; then
	echo "Failed to unpack tomcat" 1>&2
	exit 1
fi
ln -s $target/apache-tomcat-$v $target/tomcat

#
# Standard java libraries.
#

echo "Install glassfish"
curl -O http://download.java.net/glassfish/3.1.2.2/release/glassfish-3.1.2.2-ml.zip
rm -rf $target/glassfish*
unzip -d $target/ glassfish-3.1.2.2-ml.zip 
if [ $? -ne 0 ] ; then
	echo "Failed to unpack glassfish" 1>&2
	exit 1
fi

jackson=jackson-all-1.9.11.jar

echo "Install jackson"
rm -rf $target/lib/jackson-all*
curl -O -L http://java2s.com/Code/JarDownload/jackson-all/$jackson.zip
unzip $jackson.zip
mv $jackson $target/lib/$jackson
ln -s $target/lib/$jackson $target/lib/jackson-all.jar

#curl -o $target/lib/$jackson http://jackson.codehaus.org/1.9.11/$jackson
#ln -s $target/lib/$jackson $target/lib/jackson-all.jar
#
mkdir -p $target/env

echo '
if [ -d /Library/Java/Home ] ; then
	export JAVA_HOME=/Library/Java/Home
elif [ -x /usr/libexec/java_home ] ; then
	export JAVA_HOME=`/usr/libexec/java_home`
elif [ -L /usr/bin/java ] ; then
	export JAVA_HOME=$(readlink -f /usr/bin/java | sed "s:bin/java::")
fi' > $target/env/java-build-runtime.env

echo "
export ANT_HOME=$target/ant
export THRIFT_HOME=$target/thrift
export CATALINA_HOME=$target/tomcat
export GLASSFISH_HOME=$target/glassfish3
export PATH=\${JAVA_HOME}/bin:\${ANT_HOME}/bin:$target/bin:\${THRIFT_HOME}/bin:\${CATALINA_HOME}/bin:\${PATH}" >> $target/env/java-build-runtime.env

