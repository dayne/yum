#!/bin/bash
# written for Centos 5.5 x86_64
# Script to automate various system configurations on new builds


# set the timezone
echo "setting timezone to Alaskan start ntpd"
mv /etc/localtime /etc/localtime-default
cp /usr/share/zoneinfo/America/Anchorage /etc/localtime

echo 'ZONE="America/Anchorage"' > /etc/sysconfig/clock
echo 'UTC=false' >> /etc/sysconfig/clock
echo 'ARC=false' >> /etc/sysconfig/clock

#set the time first so weird stuff doesn't happen
yum -y install ntp
chkconfig ntpd on
ntpdate ntp.alaska.edu
/etc/init.d/ntpd start
###############################################################

sleep 2

#install Yum repos
pushd .
svn co http://svn.github.com/dayne/yum
cd yum/centos5/
./install.sh
yum -y update
popd

echo "install and configure denyhosts"
yum -y install denyhosts
ln -s /usr/share/doc/denyhosts-2.6/daemon-control-dist /etc/init.d/denyhosts
/usr/share/doc/denyhosts-2.6/denyhosts.py -c /usr/share/doc/denyhosts-2.6/denyhosts.cfg-dist
cp /usr/share/doc/denyhosts-2.6/denyhosts.cfg-dist /usr/share/denyhosts/denyhosts.cfg
wget -O /usr/share/denyhosts/denyhosts.cfg http://ks.gina.alaska.edu/denyhosts.cfg 

echo "ALL: 137.229.19.0/255.255.255.0" >> /etc/hosts.allow

/etc/init.d/denyhosts start
chkconfig denyhosts on

echo "setup root mail forwarding"
wget -O /etc/mail/sendmail.mc http://ks.gina.alaska.edu/sendmail.mc

yum -y install sendmail-cf
make -C /etc/mail

echo "root: root@gina.alaska.edu" >> /etc/aliases
newaliases
chkconfig sendmail on
service sendmail start
echo "sendmail test from `ifconfig eth0 | grep 'inet addr' | awk '{print $2}'`" \
 | mail -s "test from `hostname`" root@gina.alaska.edu

sleep 1
echo "automatic yum updates"
wget -O /etc/yum/yum-updatesd.conf http://ks.gina.alaska.edu/yum-updatesd.conf

service yum-updatesd start
chkconfig yum-updatesd on

# install Ruby and Gems
 #wget http://ks.gina.alaska.edu/ruby.sh
# sh ruby.sh /usr/local 1

#wget http://ks.gina.alaska.edu/rubygems-1.3.5.tgz
#tar zxfv rubygems-1.3.5.tgz
#cd rubygems-1.3.5
#ruby setup.rb

#gem install open4 rails mongrel cheat facets net-ssh net-ping crypt-fog daemons net-sftp highline GeoRuby xmpp4r-simple RingyDingy vim-ruby hpricot postgres-pr

yum install -y git

echo "set up DNS"
# TODO: perhaps revamp this and figure out if this is appropriate
# for the network being installed to
echo "search gina.alaska.edu" > /etc/resolv.conf
echo "nameserver 137.229.31.16" >> /etc/resolv.conf
echo "nameserver 137.229.10.39" >> /etc/resolv.conf
echo "nameserver 137.229.30.33" >> /etc/resolv.conf

# ------------ Configure NRPE (Nagios Plugin) ------------ #
echo "setting up NRPE..."

yum -y install nagios-nrpe nagios-plugins xinetd yum nagios-plugins-users nagios-plugins-procs nagios-plugins-disk nagios-plugins-http nagios-plugins-load

wget -O /etc/xinetd.d/nrpe http://ks.gina.alaska.edu/nrpe
wget -O /etc/nagios/nrpe.cfg http://ks.gina.alaska.edu/nrpe.cfg
echo " nrpe               5666/tcp           # NRPE" >> /etc/services
chkconfig xinetd on
chkconfig nrpe on
/etc/init.d/xinetd start
service nrpe start

echo ""

echo "add this to /etc/mdadm.conf...  MAILADDR alert@gina.alaska.edu"
echo "and add this to iptables:"
echo "-A RH-Firewall-1-INPUT -p tcp -m tcp --dport 5666 -j ACCEPT"
