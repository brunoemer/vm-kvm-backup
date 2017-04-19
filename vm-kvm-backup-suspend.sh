#!/bin/bash
# ------------------------------------------------------------------
# Copyright (c) 2017-04-19 Bruno Emer <emerbruno@gmail.com>
#
# Backup of kvm vms
# Needed ssh key to connect on target via rsync
#
# ------------------------------------------------------------------

if [ $# -lt 1 ]; then
    echo $0: usage: $0 "rsync_destination"
    exit 1
fi

rsync_target="$1"
with_suspend=0

virsh list | tail -n+3 | sed '/^$/d' | while read m; do
    vm_name=`echo $m | awk '{print $2}'`;
    vm_state=`echo $m | awk '{print $3 $4}'`

    echo "Backup init for $vm_name"

    #backup xml
    echo "Copying the XML"
    virsh dumpxml $vm_name > /tmp/$vm_name.xml
    rsync -hav /tmp/$vm_name.xml "$rsync_target$vm_name/"

    #suspend
    if [ $with_suspend -eq 1 ]; then
        echo "VM suspend $vm_name"
        virsh suspend $vm_name
    fi

    images=`virsh domblklist "$vm_name" --details | grep ^file | grep -v cdrom | awk '{print $4}'`
    for img in $images; do
        img_name=`basename "$img"`
        echo "Copying disk $img"
        
        rsync -hav $img "$rsync_target$vm_name/"

    done

    #resume
    if [ $with_suspend -eq 1 ]; then
        echo "VM resume $vm_name"
        virsh resume $vm_name
    fi

    echo "Backup finish $vm_name"
done
