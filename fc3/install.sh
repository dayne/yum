#!/bin/sh

echo "moving /etc/yum.conf to /etc/yum.conf.default"
mv /etc/yum.conf /etc/yum.conf.default
echo "moving /etc/yum.repos.d to /etc/yum.repos.default"
mv /etc/yum.repos.d /etc/yum.repos.default
echo "Installing cleaner yum.conf"
cp yum.conf /etc/yum.conf
echo "Putting version tracked yum.repos.d in place"
cp -r . /etc/yum.repos.d

echo "Now go to /etc/yum.repos.d and import any GPG keys you need"
echo "See the comments in each repo for the import command/url to GPG key"

WAIT=10
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

echo "Installing fedora-updates GPG key"
rpm --import http://download.fedora.redhat.com/pub/fedora/linux/core/3/i386/os/RPM-GPG-KEY-fedora
echo "Installing dag.repo GPG key"
rpm --import http://dag.wieers.com/packages/RPM-GPG-KEY.dag.txt
echo "Installing freshrpms.repo GPG key"
rpm --import http://freshrpms.net/packages/RPM-GPG-KEY.txt
echo "Installing livna.repo GPG key"
rpm --import http://rpm.livna.org/RPM-LIVNA-GPG-KEY


echo 
echo "you can stay in sync w/ bishop's yum.repos.d by going to"
echo "/etc/yum.repos.d and typing: svn update"
echo
echo "Enjoy! .bishop"

