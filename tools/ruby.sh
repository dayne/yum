#!/bin/bash
# curl -s http://github.com/dayne/yum/raw/master/tools/sysconfig.sh | sh

function do_sleep {
  echo -n "will move on in "
  i=$1
  while [ ${i} -gt 0 ]
  do 
    echo -n "${i}.. "
    sleep 1;
    i=$(($i-1))
  done
  echo
}


pushd .

TARGET_PREFIX=$1  # first command line option
RUBYPICK=$2       # second command line option
# Gets Latest Version Link from Downloads page
LATEST_STABLE=`wget -O - http://www.ruby-lang.org/en/downloads/ 2>/dev/null| grep -i "Stable Version (<em>recommended</em>)" | grep -o -E "ftp://(.+)\.tar\.gz"`
# hard coded for 187 and 186 until somebody finds better method
LATEST_187="ftp://ftp.ruby-lang.org/pub/ruby/1.8/ruby-1.8.7-p160.tar.gz"
LATEST_186="ftp://ftp.ruby-lang.org/pub/ruby/1.8/ruby-1.8.6-p287.tar.gz"



got_ver='false'
pick=$RUBYPICK
while [ "$got_ver" != "true" ]
do
  if [ "$pick" == "" ]; then
    echo 
    echo "Pick which one you want to install: default is 1.8.7"
    echo 
    echo "[1] $LATEST_187"
    echo "[2] $LATEST_186"
    echo "[3] $LATEST_STABLE"
    echo
    echo -n "(1) : "
    read pick
    echo $pick
  fi

  case "$pick" in
    [1] ) TARGET_RUBY=$LATEST_187 
          got_ver='true'
          ;;
    [2] ) TARGET_RUBY=$LATEST_186
          got_ver='true'
          ;;
    [3] ) TARGET_RUBY=$LATEST_STABLE
          got_ver='true' 
          ;;
    * ) 
          echo "using default selection of $LATEST_187"
          TARGET_RUBY=$LATEST_187 
          got_ver='true' 
          ;;
  esac
done

RUBYVER=`basename $TARGET_RUBY .tar.gz`
FILE=`basename $TARGET_RUBY`
RUBYSITE=$TARGET_RUBY


# PREFIX SELECTION TIME
got_prefix='false';
while [ "$got_prefix" != "true" ]; do
  if [ ! -n "$TARGET_PREFIX" ]; then
    echo "empty target prefix - defaulting prefix to /usr/local/"
    PREFIX="/usr/local/"
  else
    echo "got PREFIX=$TARGET_PREFIX"
    PREFIX=$TARGET_PREFIX
  fi
  # verify validity of target prefix
  if [ ! -d $PREFIX ]; then
    echo "dir does not exist: $PREFIX"  
    echo -n "create it? (y/N) : "
    read input
    case "$input" in
      "y" ) mkdir $PREFIX ;;
      "n" ) echo "Ok, exiting"; exit ;;
      * ) echo "uggles" ;;
    esac
  else
    got_prefix='true';
  fi

done

TARGETSRC=$PREFIX/src

echo "
  #
  # installing $RUBYVER
  # PREFIX=$PREFIX
  # source code into $TARGETSRC
  # 
"
do_sleep 5

clear

function check_dist {
  DEB=`cat /etc/issue | grep -i -E "Ubuntu|Debian"`
  RPM=`cat /etc/issue | grep -i -E "Redhat|Fedora|CentOS"`

  if [ -n "$DEB" ]; then # Debian Time!
   echo "Detected DEB Platform."
   echo "Performing Hardcore Debian/Ubuntu Hacking."

   echo -n "Checking for libncurses5-dev... "
   NCURSES_INSTALLED=`dpkg -s libncurses5-dev 2>/dev/null | grep 'not-installed'`
   if [ -z "$NCURSES_INSTALLED" ];then
     echo "NCurses Installed."
   else
     echo "NCurses Missing.  Installing..."
     apt-get install libncurses5-dev
     if [ "$?" = 0 ];then
       echo "Installation Complete"
     else
       echo "Installation Failed: Exited with code $?"
       exit 1
     fi
   fi

   echo -n "Checking for libreadline-dev... "
   READLINE_INSTALLED=`dpkg -s libreadline5-dev 2>/dev/null | grep 'not-installed'`
   if [ -z "$READLINE_INSTALLED" ];then
     echo "Readline Installed."
   else
     echo "Readline Missing.  Installing..."
     apt-get install libreadline5-dev
     if [ "$?" = 0 ];then
       echo "Installation Complete"
     else
       echo "Installation Failed: Exited with code $?"
       exit 1
     fi
   fi

  elif [ -n "$RPM" ]; then # RedHat Time!
    echo "Detected RPM Platform."
    echo "making sure readline-devel, zlib-devel, and ncurses-devel installed"
    yum install -y readline-devel zlib-devel ncurses-devel
  else echo "Don't Know what Distro this is.  Oh well..."
  fi
}

function sanity_check {
	if [ ! $1 -eq 0 ] 
	then
		echo $2
		exit 1
	fi
}

echo "This script is about to install ${RUBYVER}"
echo "by default I will do the following to install ruby:"
echo "    ./configure --prefix=${PREFIX};make;make install"
check_dist
do_sleep 3



echo "checking for target src directory: $TARGETSRC"
if [ ! -d $TARGETSRC ] 
then
  echo  "/usr/local/src/ruby doesn't exist"
  mkdir $TARGETSRC
  if [ ! -d $TARGETSRC ]
  then
    echo "unable to create $TARGETSRC"
    echo "cannot continue"
    exit 1
  fi
else
  echo "$TARGETSRC already created .. good" 
fi

echo "testing create privilege in $TARGETSRC"
TF=testFile$$
touch $TARGETSRC/${TF}
if [ ! -f $TARGETSRC/${TF} ]
then
  echo "Unable to create a test file in $TARGETSRC"
  exit 1
else
  echo "yay, $TARGETSRC writable"
  rm $TARGETSRC/${TF}
fi

cd $TARGETSRC

if [ ! -f $FILE ]
then
  echo "no $FILE file - downloading it"
  #ls -l $FILE
  wget ${RUBYSITE}
  sanity_check $? "wget of ruby failed: ${RUBYSITE}"
else
  echo "already have a ruby tar ball to use.."
fi

if [ ! -f $FILE ]
then
  echo "download of ruby's source unsuccessful $TARGETSRC/${FILE} "
  exit 1
fi

#dlmd5=`md5sum ${FILE} | awk '{print $1}'`
#echo $dlmd5 $MD5
#
#if [ ! $dlmd5 == $MD5 ]
#then
  #echo "md5sum of downloaded ${FILE} not good"
  #exit 1
#fi
#echo "good md5"

if [ -d ${RUBYVER} ]
then
  echo "a ruby source directory already exists.. I'm going to toast it"
  sleep 1
  rm -rf ${RUBYVER} 
fi

echo tar xvfz ${FILE}
tar xvfz ${FILE}
cd ${RUBYVER}
make distclean
./configure --prefix=${PREFIX}

export LD_RUBY_PATH=$PREFIX/lib
export LD_LIBRARY_PATH=$PREFIX/lib

make
make install
make install-doc

echo "ok, ruby should be installed now"

$PREFIX/bin/ruby -e 'p $LOAD_PATH'
if [ ! $? -eq 0 ]
then
	echo "ruby does not appear to be working"
	exit 1
fi

# back to where we started
popd

exit
### we don't do the following any more
TOUCHTEST=test_me_now_and_then_remove_me_again
touch $TOUCHTEST
if [ -f $TOUCHTEST ]
then
  rm $TOUCHTEST
  echo "looks like I can write to the current directory: `pwd`"
  echo "I'll take advantage of that and download the next step"
  wget http://tofu.gina.alaska.edu/get_rubygems.rb
fi

echo "attempting to switch into an irb session"
# just making sure we aren't tainted by rubygems *yet*
export RUBYOPT=""
# make sure the bin path we now have is primary so we can find
# correct location of 'gem' and 'ruby' in the later stuff
export PATH=${PREFIX}/bin:${PATH}
hash -r
#echo "if this worked you should run: ruby get_rubygems.rb"
