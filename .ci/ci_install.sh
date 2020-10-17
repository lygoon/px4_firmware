#!/bin/bash
# author: Robert Penicka
set -e

distro=`lsb_release -r | awk '{ print $2 }'`
[ "$distro" = "18.04" ] && ROS_DISTRO="melodic"
[ "$distro" = "20.04" ] && ROS_DISTRO="noetic"

echo "Starting install preparation"

sudo apt-get -y update -qq
sudo apt-mark hold openssh-server

# the "gce-compute-image-packages" package often freezes the installation at some point
# the installation freezes when it tries to manage some systemd services
# this attempts to install the package and stop the problematic service during the process
((sleep 90 && (sudo systemctl stop google-instance-setup.service && echo "gce service stoped" || echo "gce service not stoped")) & (sudo timeout 120s apt-get -y install gce-compute-image-packages)) || echo "\e[1;31mInstallation of gce-compute-image-packages failed\e[0m"

sudo apt -y upgrade --fix-missing

sudo apt-get -y upgrade --fix-missing

sudo apt-get -y install git

echo "installing uav_core pre-requisities"
git clone https://github.com/ctu-mrs/uav_core
cd uav_core
./installation/install.sh

echo "clone simulation"
cd
git clone https://github.com/ctu-mrs/simulation.git
cd simulation

echo "running the main install.sh"
./installation/install.sh

gitman update

# get the current commit SHA
cd "$TRAVIS_BUILD_DIR"
SHA=`git rev-parse HEAD`

# get the current package name
PACKAGE_NAME=${PWD##*/}

# checkout the SHA
cd ~/simulation/.gitman/$PACKAGE_NAME
git checkout "$SHA"

# will need this to test the compilation
sudo apt-get -y install python-catkin-tools

mkdir -p ~/catkin_ws/src
cd ~/catkin_ws/src
ln -s ~/simulation
source /opt/ros/$ROS_DISTRO/setup.bash
cd ~/catkin_ws
catkin init

echo "install part ended"