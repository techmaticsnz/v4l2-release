#!/bin/bash
echo "--------------------------------------"
echo "usage: $0 veyecam2m/csimx307/cssc132/veye_mvcam/veye_vbyone/ds90ub954"
driver_name=null;

model=$(tr -d '\0' </proc/device-tree/model)

if [[ $model == *"Raspberry Pi 5"* ]]; then
    echo "This is a Raspberry Pi 5."
elif [[ $model == *"Raspberry Pi Compute Module 5"* ]]; then
    echo "This is a Raspberry Pi Compute Module 5."
else
    echo "This is not a Raspberry Pi 5."
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
			 system(\"sudo sh -c 'echo dtoverlay=${driver_name} >> ${CONFIG_FILE}'\"); \
			 system(\"sudo sh -c 'echo dtoverlay=${driver_name},cam0 >> ${CONFIG_FILE}'\"); \
		 } \
	 }" "${CONFIG_FILE}"
}

echo "--------------------------------------"
echo "Enable i2c adapter... pls use i2c-4/i2c-11 for cam1, i2c-6/i2c-10 for cam0"
echo "--------------------------------------"
sudo modprobe i2c-dev
# add dtparam=i2c_vc=on to ${CONFIG_FILE}
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

        
