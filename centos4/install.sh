#!/bin/sh

if [ -f ./yum.conf ] ; then
	if [ -f /etc/yum.conf.default ] ; then
		echo "/etc/yum.conf.default detected"
		echo "aborting.... clean this up yourself"
		exit
	fi
	echo "moving /etc/yum.conf to /etc/yum.conf.default"
	mv /etc/yum.conf /etc/yum.conf.default
	echo "Installing cleaner yum.conf"
	cp yum.conf /etc/yum.conf
fi

if [ -d /etc/yum.repos.default ] ; then
        echo "/etc/yum.repos.default detected"
        echo "aborting.... clean this up yourself"
        exit;
fi

echo "moving /etc/yum.repos.d to /etc/yum.repos.default"
mv /etc/yum.repos.d /etc/yum.repos.default

echo "Putting version tracked yum.repos.d in place"
cp -r . /etc/yum.repos.d

echo "Now go to /etc/yum.repos.d and import any GPG keys you need"
echo "See the comments in each repo for the import command/url to GPG key"

WAIT=5
echo 
echo "***READ: Going to import GPG keys you probably need in $WAIT seconds"
echo "***READ: hit CTL-C if you don't want this to happen"

I=$WAIT
while(($I > 0)); do
        echo -n "$I "
        sleep 1
        I=$(($I-1))
done
echo 0
sleep 1

for KEYFILE in *.repo.key; do
	echo "Inserting key from $KEYFILE"
	for KEYURL in `cat $KEYFILE`; do
		echo "rpm --import $KEYURL"
		rpm --import $KEYURL
		sleep 1
	done
done

echo "installing yum-plugin-protectbase"
yum install yum-plugin-protectbase

echo 
echo "you can stay in sync w/ bishop's yum.repos.d by going to"
echo "/etc/yum.repos.d and typing: svn update"
echo
echo "Enjoy! .bishop"

