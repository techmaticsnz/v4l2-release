#!/bin/bash

#set -x
echo "--------------------------------------"
echo "usage: $0 veyecam2m/csimx307/cssc132/veye_mvcam/veye_vbyone/ds90ub954"
driver_name=null;

model=$(tr -d '\0' </proc/device-tree/model)
if [[ $model == *"Raspberry Pi 5"* ]]; then
    echo "This is a Raspberry Pi 5. Pls use install_driver_rpi5.sh"
	exit 0;
fi


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

write_camera_to_config()
{
	awk "BEGIN{ count=0 } \
	 { \
		 if(\$1 == \"dtoverlay=${driver_name}\"){ \
			 count++; \
		 } \
	 } \
	 END{ \
		 if(count <= 0){ \
			 system(\"sudo sh -c 'echo dtoverlay=${driver_name},media-controller=0>> ${CONFIG_FILE}'\"); \
		 } \
	 }" "${CONFIG_FILE}"
}
echo "--------------------------------------"
echo "Enable i2c0 adapter..."
echo "--------------------------------------"
sudo modprobe i2c-dev
# add dtparam=i2c_vc=on to /boot/config.txt
awk "BEGIN{ count=0 }\
{\
    if(\$1 == \"dtparam=i2c_vc=on\"){\
        count++;\
    }\
}END{\
    if(count <= 0){\
        system(\"sudo sh -c 'echo dtparam=i2c_vc=on >> ${CONFIG_FILE}'\");\
    }\
}" "${CONFIG_FILE}"

echo "Add dtoverlay=$driver_name to ${CONFIG_FILE} "
echo "--------------------------------------"
write_camera_to_config;
echo "Add gpu=256M to ${CONFIG_FILE} "
awk "BEGIN{ count=0 }
{
    if(\$1 == \"gpu_mem=256\"){
        count++;
    }
}END{
    if(count <= 0){
        system(\"sudo sh -c 'echo gpu_mem=256 >> ${CONFIG_FILE}'\");
    }
}" "${CONFIG_FILE}"

echo "Add cma=128M to /boot/cmdline.txt "
echo "--------------------------------------"
sudo sed 's/cma=128M//g' -i /boot/cmdline.txt
sudo sed 's/[[:blank:]]*$//' -i /boot/cmdline.txt
sudo sed 's/$/& cma=128M/g' -i /boot/cmdline.txt
echo "Installing the $driver_name.ko driver"
echo "--------------------------------------"
sudo install -p -m 644 ./driver_bin/$(uname -r)/$driver_name.ko  /lib/modules/$(uname -r)/kernel/drivers/media/i2c/
sudo install -p -m 644 ./driver_bin/$(uname -r)/$driver_name.dtbo /boot/overlays/
sudo /sbin/depmod -a $(uname -r)
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

        
