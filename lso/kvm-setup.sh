#!/usr/bin/bash

SIZE='10'
WORKER_NUMBER='3'

rm -rf /opt/iso/*

for i in {1..3}
do
qemu-img create -f raw /opt/iso/disk-worker${i}.img ${SIZE}G
virsh list | grep worker | tail -n +1 | sed -n "${i} p" | awk -v var="$i"  '{system("virsh attach-disk " $2 " /opt/iso/disk-worker" var ".img sda")}'
done


