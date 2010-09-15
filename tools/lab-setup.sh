#!/bin/bash
# lab config stuff
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
    return $?
  else
    echo "have command $1"
    return 0
  fi
}

function yum_install_rpm() {
  rpm -q $1 > /dev/null
  if [ $? -eq 1 ]; then
    echo "missing RPM $1 - installing"
    yum install -y $1
  fi
}


# ------------ lab-specific stuff ----------------
# set up rtorrent

yum_install_rpm rtorrent
if [ ! -f /root/rtorrent-local.rb ]; then
	yak "configuring rtorrent for root"
	wget -O /root/rtorrent-local.rb http://ks.gina.alaska.edu/lab/rtorrent-local.rb
	wget -O /root/.rtorrent.rc http://ks.gina.alaska.edu/lab/.rtorrent.rc
else
	yak "rtorrent for root already configured.... skipping"
fi

if [ ! -f /etc/sysconfig/iptables.default ]; then
	yak "install iptables rules for rtorrent and nagios"
	cp /etc/sysconfig/iptables /etc/sysconfig/iptables.default
	wget -O /etc/sysconfig/iptables http://ks.gina.alaska.edu/lab/iptables
else
	yak "iptables for rtorrent and nagios already applied... skipping"
fi

# download latest lab image in the background
#echo "you need to manually download windowsimage.torrent, screen, and torrent it"
#wget http://pandora.lab.gina.alaska.edu/windowsimage.torrent
#screen -d -m rtorrent /root/windowsimage.torrent

#install vmware
rpm -q VMware-Workstation > /dev/null
if [ $? == 1 ]; then
	yak 'installing vmware...'
	wget http://ks.gina.alaska.edu/lab/VMware-Workstation-6.5.4.x86_64.rpm
	rpm -Uvh VMware-Workstation-6.5.4.x86_64.rpm
else
	yak "vmware workstation already installed... skipping"
fi

# download nvida driver
if [ ! -f NVIDIA-Linux-x86_64-173.14.18-pkg2.run ]; then
	wget http://ks.gina.alaska.edu/lab/NVIDIA-Linux-x86_64-173.14.18-pkg2.run
	echo "ok, go setup NVIDIA now"
else
	yak "nvidia driver downloaded (you still have to fixup)... skipping"
fi


grep labnfs.gina /etc/fstab > /dev/null
if [ $? == 1 ]; then
	# set up nfs mounts
	yak 'setting up nfs mounts...'
	echo '#Uranus mounts' >> /etc/fstab
	echo 'labnfs.gina.alaska.edu:/home    /home nfs rsize=16384,wsize=16384,intr,nolock 0 0' >> /etc/fstab
	echo 'labnfs.gina.alaska.edu:/shares  /hub/lab/shares nfs defaults 0 0' >> /etc/fstab
	echo 'labnfs.gina.alaska.edu:/scratch /hub/lab/scratch nfs defaults 0 0' >> /etc/fstab

	# create mountpoints
	echo 'creating mountpoints...'
	mkdir /hub
	mkdir /hub/lab
	mkdir /hub/lab/shares
	mkdir /hub/lab/scratch
	mkdir /opt/terascan
else
	yak "lab nfs mounts already setup... skippping"
fi

if [ ! -f /etc/hosts.default ]; then
	wget http://ks.gina.alaska.edu/lab/hosts
	cp /etc/hosts /etc/hosts.default
	cat ./hosts >> /etc/hosts
fi

yak "TODO: need to figure out proper receipe for gnome's automount issue and put it here"
if [ false ]; then
	yak "configuring gnome volume stuff"
	# disable gnome auto-mount (this doesnt quite work. still something to figure out)
	yum_install_rpm gnome-volume-manager
	gconftool-2 --direct --config-source xml:readwrite:/etc/gconf/gconf.xml.mandatory --type bool --set /desktop/gnome/volume_manager/automount_media false
	gconftool-2 --direct --config-source xml:readwrite:/etc/gconf/gconf.xml.mandatory --type bool --set /desktop/gnome/volume_manager/automount_drives false
	echo 'auto-mounting of usb devices is disabled.'
fi
	
# install tsch for insar user and do stuff for SARS class
yum_install_rpm tcsh
yum_install_rpm libglade-devel
yum_install_rpm libglade


#echo 'installing 64-bit flash plugin...'
#wget http://download.macromedia.com/pub/labs/flashplayer10/libflashplayer-10.0.22.87.linux-x86_64.so.tar.gz
#tar zxfv libflashplayer-10.0.22.87.linux-x86_64.so.tar.gz

#mv libflashplayer.so /usr/lib64/mozilla/plugins/

# some additional useful software
yum_install_rpm bash-completion 
yum_install_rpm Terminal

yak "applying full yum update before doign kernel exclude"
yum update -y

grep "exclude=" /etc/yum.conf > /dev/null
if [ $? == 1 ]; then
	yak "excluding kernel updates from now on"
	echo 'exclude=kernel*' >> /etc/yum.conf
else
	yak "kernel exclude already done in yum.conf.. skipping"
fi 

#echo 'preforming cleanup...'
#mkdir config-src/
#mv *.gz *.rpm ruby* hosts iptables.orig config-src/

# configure x server
if [ ! -f /etc/X11/xorg.conf.default ]; then
	yak "applying lab X config"
	wget -O /etc/X11/xorg.conf http://ks.gina.alaska.edu/lab/lab_xorg.conf
else
	yak "xorg.conf replaced already... skipping"
fi

# download lab image
if [ ! -f windowsimage.torrent ]; then
	yak "getting windowsimage.torrent and launching in a screen"
	wget http://pandora.lab.gina.alaska.edu/windowsimage.torrent
	screen -S labsync -d -m rtorrent windowsimage.torrent
	echo "the lab image is now downloading in the background"
	echo "type 'screen -x' to view"
else
	yak "windowsimage.torrent already downloaded... skipping"
fi


yak 'Done with basic lab configuration.'
echo 'You will need to reboot and manually run sh NVIDIA-Linux-x86_64-173.14.18-pkg2.run'
echo 'in order to install the video driver.'
