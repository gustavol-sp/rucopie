#!/bin/bash

#export __has_kms=1 __has_dispmanx=1 # for the opengl fkms driver setup

separator="********************************************"
cd ~

echo "$separator"
echo "Installing RetroPie dependencies..."
/boot/dietpi/dietpi-software install 5 6 16 17

echo "$separator"
echo ''
echo "Executing RetroPie Setup (ANSWER YES to user ownership messages and THEN EXIT)..."
echo ''

/usr/bin/git clone --depth=1 https://github.com/RetroPie/RetroPie-Setup.git
echo 'Entering folder RetroPie-Setup...'
cd RetroPie-Setup
echo 'Starting RetroPie setup...'
./retropie_setup.sh

cd ~
declare -a pkgs=(
  "retroarch"
  "love"
  "splashscreen"
  "lr-gambatte"
  "lr-fceumm"
  "lr-snes9x"
  "lr-fbneo"
  "lr-stella2014"
)

for pkg in "${pkgs[@]}"
do
  echo "$separator"
  ~/RetroPie-Setup/retropie_packages.sh $pkg depends
  echo "Installing now $pkg..."
  ~/RetroPie-Setup/retropie_packages.sh $pkg install_bin
done

/usr/bin/git clone https://github.com/tavuntu/rucopie
cd rucopie
echo "$separator"
echo "Installing config files..."

cp -r boot/ /
cp -r opt/ /
cp -r root/ /
cp -r var/ /
cp -r etc/ /
chmod +x ~/RucoPie/scripts/*

echo "Creating global link for love..."
cd ..
ln -s /opt/retropie/ports/love/bin/love /usr/bin/

echo "Installing alsamixer equalizer..."
apt-get --assume-yes install libasound2-plugin-equal

echo "Installing extra Lua stuff..."
apt-get --assume-yes install luarocks
luarocks install luafilesystem

echo "Enabling RucoPie splashscreen..."
systemctl enable asplashscreen.service

echo "$separator"
echo "Done! Restarting now..."
echo "$separator"

reboot
