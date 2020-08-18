#!/usr/bin/bash

# Created by Venkat Pinisetti (venkat.pinisetti@in.ibm.com)

IP=$1
DISKIDS="0.0.0101 0.0.0102 0.0.0103 0.0.0104"
DISKS="/dev/dasdb /dev/dasdc /dev/dasdd /dev/dasde"
PARTITION="extpart"
usage () {
  echo -e "\nUsage: Run this script as below format."
  echo -e "\nsh zvm-setup.sh <hostname of the worker node>\n"
}
# Usage of the script
if [[ $1 == "-h" || $1 == "--help" || $# -eq 0 ]] ; then
  usage
  exit 1
fi
ssh core@$IP "sudo chccwdev -e $DISKIDS"
for disk in $DISKS
do
  ssh core@$IP "sudo dasdfmt $disk -b 4096 -p -y"
  ssh core@$IP "sudo fdasd -a $disk"
  ssh core@$IP "sudo pvcreate ${disk}1"
  ssh core@$IP "sudo vgs basevg"
  if [[ $? == 0 ]]; then
    ssh core@$IP "sudo vgextend basevg ${disk}1"
  else
    ssh core@$IP "sudo vgcreate basevg ${disk}1"
  fi
done
ssh core@$IP "sudo lvcreate -L178G -n $PARTITION basevg"
echo -e "\nCompleted setting up extra disk"
