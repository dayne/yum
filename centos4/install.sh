#!/bin/sh

mv /etc/yum.conf /etc/yum.conf.default
mv /etc/yum.repos.d /etc/yum.repos.default
cp yum.conf /etc/yum.conf
cp -r . /etc/yum.repos.d

echo "Now go to /etc/yum.repos.d and import any GPG keys you need"
echo "See the comments in each repo for the import command/url to GPG key"
