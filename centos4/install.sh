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

echo 
echo "you can stay in sync w/ bishop's yum.repos.d by going to"
echo "/etc/yum.repos.d and typing: svn update"
echo
echo "Enjoy! .bishop"

