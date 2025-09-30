#!/bin/bash

echo "--------------------------------------"
echo "usage: $0 veyecam2m/csimx307/cssc132/veye_mvcam/veye_vbyone/ds90ub954"
driver_name=null;

CONFIG_FILE=""

if [ -f /boot/firmware/config.txt ]; then
    CONFIG_FILE="/boot/firmware/config.txt"
else
	CONFIG_FILE="/boot/config.txt"
fi

echo "CONFIG_FILE: $CONFIG_FILE"	

valid_drivers=("veyecam2m" "csimx307" "cssc132" "veye_mvcam" "veye_vbyone" "ds90ub954")

if [[ " ${valid_drivers[@]} " =~ " $1 " ]]; then
  driver_name=$1
else
  echo "Please provide a correct camera module name!"
  exit 0
fi

sudo sed "s/^dtoverlay=${driver_name}/#dtoverlay=${driver_name}/g" -i ${CONFIG_FILE}

echo "uninstall $driver_name driver"
sudo rm /lib/modules/$(uname -r)/kernel/drivers/media/i2c/$driver_name.ko
sudo rm /boot/overlays/$driver_name.dtbo
sudo /sbin/depmod -a $(uname -r)
#sudo sed 's/^dtoverlay=$driver_name/#dtoverlay=$driver_name/g' -i ${CONFIG_FILE}
echo "reboot now?(y/n):"
read USER_INPUT
case $USER_INPUT in
'y'|'Y')
    echo "reboot"
    sudo reboot
;;
*)
    echo "cancel"
;;
esac

