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

echo "not importing any keys since fc4 seems to have a better way"
echo "of dealing with it"
sleep 1

echo "installing the handy bash-completion"
yum install -y bash-completion

echo 
echo "you can stay in sync w/ bishop's yum.repos.d by going to"
echo "/etc/yum.repos.d and typing: svn update"
echo
echo "Enjoy! .bishop"
