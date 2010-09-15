#!/bin/bash
# written for Centos 5.5 x86_64
# Script to automate various system configurations on new builds
function boom(){ echo ${1}; exit 1; }
function yak(){ 
	echo "###########################################################################"
	echo ${1}; 
	echo "= = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = ="
	sleep 1; 
}

function yum_install_command(){
	which $1 2> /dev/null
	if [ $? -eq 1 ]; then 
		echo "missing command $1 - trying a yum install for it"
		yum install -y $1
		return 1
	else
		echo "have command $1"
		return 0
	fi
}

function yum_install_rpm() {
	rpm -q $1 
	if [ $? -eq 1 ]; then
		echo "missing RPM $1 - installing"
		yum install -y $1
	fi
}

yum_install_rpm wget
yum_install_rpm curl

# set the timezone
if [ -f /etc/localtime-default ]; then
	yak "timezone already set.... skipping"
else
	yak "setting timezone to Alaskan start ntpd"
	mv /etc/localtime /etc/localtime-default
	cp /usr/share/zoneinfo/America/Anchorage /etc/localtime

	echo 'ZONE="America/Anchorage"' > /etc/sysconfig/clock
	echo 'UTC=false' >> /etc/sysconfig/clock
	echo 'ARC=false' >> /etc/sysconfig/clock

	#set the time first so weird stuff doesn't happen
	yak "installing NTP and syncing with ntp.alaska.edu"
	yum_install_rpm ntp
	chkconfig ntpd on
	ntpdate ntp.alaska.edu
	/etc/init.d/ntpd start
fi

###############################################################

#install Yum repos
if [ -d /etc/yum.repos.default ]; then
	yak "Dayne's repos probably installed already... skipping"
else
	yak "installing Dayne's yum confs via svn"
	pushd .
	cd /tmp
	if [ ! -d dayne-yum* ]; then
		curl -L http://github.com/dayne/yum/tarball/master | tar xvzf -
		cd dayne-yum*/centos5
	fi
	cd dayne-yum*/centos5/
	if [ -f install.sh ]; then
		./install.sh
		yum -y update
	else 
		boom "didn't find install.sh for dayne repo in: `pwd`"
	fi
	popd
	yum_install_command git
fi


if [ -f /etc/init.d/denyhosts ]; then
	yak "denyhosts already appears to be setup...  skipping"
else
	yak "install and configure denyhosts"
	yum_install_rpm denyhosts
	ln -s /usr/share/doc/denyhosts-2.6/daemon-control-dist /etc/init.d/denyhosts
	/usr/share/doc/denyhosts-2.6/denyhosts.py -c /usr/share/doc/denyhosts-2.6/denyhosts.cfg-dist
	cp /usr/share/doc/denyhosts-2.6/denyhosts.cfg-dist /usr/share/denyhosts/denyhosts.cfg
	wget -O /usr/share/denyhosts/denyhosts.cfg http://ks.gina.alaska.edu/denyhosts.cfg 

	echo "ALL: 137.229.19.0/255.255.255.0" >> /etc/hosts.allow

	/etc/init.d/denyhosts start
	chkconfig denyhosts on
fi



if [ -f /etc/mail/sendmail.mc.default ]; then
	yak "sendmail config done already... skipping"
else
	yak "setup root mail forwarding"
	if [ -f /etc/mail/sendmail.mc ]; then
		mv /etc/mail/sendmail.mc /etc/mail/sendmail.mc.default
	fi
	wget -O /etc/mail/sendmail.mc http://ks.gina.alaska.edu/sendmail.mc

	yum_install_rpm sendmail-cf
	make -C /etc/mail

	echo "root: root@gina.alaska.edu" >> /etc/aliases
	newaliases
	chkconfig sendmail on
	service sendmail start
	echo "sendmail test from `ifconfig eth0 | grep 'inet addr' | awk '{print $2}'`" \
 	| mail -s "test from `hostname`" root@gina.alaska.edu
fi


if [ -f /etc/yum/yum-updatesd.conf.default ]; then
	yak "automatic yum updates already applied...  skipping"
else
	yak "enabling automatic yum updates"
	mv /etc/yum/yum-updatesd.conf /etc/yum/yum-updatesd.conf.default
	wget -O /etc/yum/yum-updatesd.conf http://ks.gina.alaska.edu/yum-updatesd.conf

	service yum-updatesd start
	chkconfig yum-updatesd on
fi

# install Ruby and Gems
#wget http://ks.gina.alaska.edu/ruby.sh
#sh ruby.sh /usr/local 1
#
#wget http://ks.gina.alaska.edu/rubygems-1.3.5.tgz
#tar zxfv rubygems-1.3.5.tgz
#cd rubygems-1.3.5
#ruby setup.rb
#
#gem install open4 rails mongrel cheat facets net-ssh net-ping crypt-fog daemons net-sftp highline GeoRuby xmpp4r-simple RingyDingy vim-ruby hpricot postgres-pr
#

grep "search gina.alaska.edu" /etc/resolv.conf
if [ $? -eq 1 ]; then
	yak "setting up DNS"
	# TODO: perhaps revamp this and figure out if this is appropriate
	# for the network being installed to
	echo "search gina.alaska.edu" > /etc/resolv.conf
	echo "nameserver 137.229.31.16" >> /etc/resolv.conf
	echo "nameserver 137.229.10.39" >> /etc/resolv.conf
	echo "nameserver 137.229.30.33" >> /etc/resolv.conf
fi

# ------------ Configure NRPE (Nagios Plugin) ------------ #

if [ -f /etc/xinetd.d/nrpe ]; then
	yak "NRPE (Nagios) already setup... skipping"
else
	yak "NRPE (Nagios) for GINA being set up"
	yum -y install nagios-nrpe nagios-plugins xinetd yum nagios-plugins-users nagios-plugins-procs nagios-plugins-disk nagios-plugins-http nagios-plugins-load

	wget -O /etc/xinetd.d/nrpe http://ks.gina.alaska.edu/nrpe
	wget -O /etc/nagios/nrpe.cfg http://ks.gina.alaska.edu/nrpe.cfg
	echo " nrpe               5666/tcp           # NRPE" >> /etc/services
	chkconfig xinetd on
	chkconfig nrpe on
	/etc/init.d/xinetd start
	service nrpe start
	yak "you will need to add a firewall exception on port 5666 for Nagios"
fi

yak "All done - read the stuff coming up though!"

if [ -f /etc/mdadm.conf ]; then
  grep "MAILADDR alert@gina.alaska.edu" /etc/mdadm.conf
  if [ $? -eq 1 ]; then
    yak "adding alert@gina.alaska.edu for software raid failure notices"
    if [ -f /etc/mdadm.conf.default ]; then
      boom "Holy cow batman - your mdadm.conf does NOT have MAILADDR alert@gina.alaska.edu"
    fi
    mv /etc/mdadm.conf /etc/mdadm.conf.default
    grep -v MAILADDR /etc/mdadm.conf.default > /etc/mdadm.conf
    echo "MAILADDR alert@gina.alaska.edu" >> /etc/mdadm.conf
  fi
else
  yak "no software raid configured, MAILADDR not needed?  skipping"
fi

yak "#########   add this to /etc/sysconfig/iptables: ################"
echo "# nagios firewall exception:"
echo "-A RH-Firewall-1-INPUT -p tcp -m tcp -s 137.229.19.0/24 --dport 5666 -j ACCEPT"
echo "# then run service iptables restart"
