#!/bin/bash
# written for Centos 5.4 x86_64
# Script to automate various system configurations on new builds


# set the timezone
# TODO FIXME this does not work yet
echo "setting timezone to Alaskan start ntpd"
mv /etc/localtime /etc/localtime-default
ln -s /usr/share/zoneinfo/America/Anchorage /etc/localtime

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

# useful libraries that Dan suggested
#yum -y install GraphicsMagick-perl\
#   gdal-perl\
#   perl-Class-Accessor\
#   perl-DBD-Pg\
#   perl-IPC-Run3\
#   perl-Inline\
#   perl-LockFile-Simple\
#   perl-Mail-Sendmail\
#   perl-Math-MatrixReal\
#   perl-Math-VectorReal\
#   perl-Parse-RecDescent\
#   perl-Template-Toolkit\
#   perl-XML-Writer perl-YAML-Syck

echo "install and configure denyhosts"
yum -y install denyhosts
ln -s /usr/share/doc/denyhosts-2.6/daemon-control-dist /etc/init.d/denyhosts
/usr/share/doc/denyhosts-2.6/denyhosts.py -c /usr/share/doc/denyhosts-2.6/denyhosts.cfg-dist
cp /usr/share/doc/denyhosts-2.6/denyhosts.cfg-dist /usr/share/denyhosts/denyhosts.cfg
wget -O /usr/share/denyhosts/denyhosts.cfg http://nori.gina.alaska.edu/sysconfig/denyhosts.cfg 

echo "ALL: 137.229.19.0/255.255.255.0" >> /etc/hosts.allow

/etc/init.d/denyhosts start
chkconfig denyhosts on


echo "setup root mail forwarding"
wget -O /etc/mail/sendmail.mc http://nori.gina.alaska.edu/sysconfig/sendmail.mc

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
wget -O /etc/yum/yum-updatesd.conf http://nori.gina.alaska.edu/sysconfig/yum-updatesd.conf

service yum-updatesd start
chkconfig yum-updatesd on

# install Ruby and Gems
# wget http://tofu.gina.alaska.edu/ruby.sh
# sh ruby.sh /usr/local 1

#wget http://nori.gina.alaska.edu/sysconfig/rubygems-1.3.5.tgz
#tar zxfv rubygems-1.3.5.tgz
#cd rubygems-1.3.5
#ruby setup.rb

#gem install open4 rails mongrel cheat facets net-ssh net-ping crypt-fog daemons net-sftp highline GeoRuby xmpp4r-simple RingyDingy vim-ruby hpricot postgres-pr

#get git!
#cd
#wget http://nori.gina.alaska.edu/sysconfig/git-1.6.3.2.tar.gz
#tar zxfv git-1.6.3.2.tar.gz
#cd git-1.6.3.2/
#./configure
#make
#make install
yum install -y git

#install memtest
# memtest not needed for VM's
if [ "" == "`grep -i qemu /proc/cpuinfo`" ]; then
  yum -y install memtest86+
  memtest-setup
fi

echo "set up DNS"
# TODO: perhaps revamp this and figure out if this is appropriate
# for the network being installed to
echo "search gina.alaska.edu" > /etc/resolv.conf
echo "nameserver 137.229.31.16" >> /etc/resolv.conf
echo "nameserver 137.229.10.39" >> /etc/resolv.conf
echo "nameserver 137.229.30.33" >> /etc/resolv.conf


echo  "stop unnecessary services"
chkconfig bluetooth off
chkconfig cups off
chkconfig ip6tables off
chkconfig pcscd off
chkconfig avahi-daemon off
sleep 1

# set up hosts
#wget http://nori.gina.alaska.edu/sysconfig/hosts
#cat ./hosts >> /etc/hosts

# ------------ Configure NRPE (Nagios Plugin) ------------ #
echo "setting up NRPE..."

yum -y install nagios-nrpe nagios-plugins-all xinetd
wget -O /etc/xinetd.d/nrpe http://nori.gina.alaska.edu/sysconfig/nrpe
echo " nrpe               5666/tcp           # NRPE" >> /etc/services
chkconfig xinetd on
chkconfig nrpe on
/etc/init.d/xinetd start
service nrpe start

echo "Completed NRPE setup."
echo "Add the following rule to iptables and restart the service:"
echo "# Allow nagios nrpe"
echo "-A RH-Firewall-1-INPUT -p tcp -m tcp --dport 5666 -j ACCEPT"

echo ""

echo "add this to /etc/mdadm.conf...  MAILADDR alert@gina.alaska.edu"
