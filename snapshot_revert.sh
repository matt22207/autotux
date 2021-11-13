#!/bin/bash
date "+%Y%m%d%H%M"

# name of domain, snapshot, and target disk device
thedomain="win10"
snapshotname="win10_bak_`date '+%Y%m%d%H%M'`"
targetdisk="vda"

pool="vmStorage"

# notice path to hda has now changed to snapshot file
echo "--- virsh domblklist $thedomain"
virsh domblklist $thedomain

snapshotname=$(virsh domblklist $thedomain | grep vda | sed -r 's/\s+vda\s+//g')
echo "--- snapshotname : $snapshotname"

# <source> has changed to snapshot file
echo "--- virsh dumpxml $thedomain | grep '<disk' -A5"
virsh dumpxml $thedomain | grep '<disk' -A5

# pull default pool path from xml 
pooldir=$(virsh pool-dumpxml $pool | grep -Po "(?<=path\>)[^<]+")
echo "--- contents of default pool dir: $pooldir"

# should see two files starting with $thedomain
# the one named $thedomain.$snapshotname is the snapshot
cd $pooldir
ls -latr $thedomain*

echo "--- sudo qemu-img info $snapshotname -U --backing-chain"
# snapshot points to backing file, which is original disk
#sudo qemu-img info $thedomain.$snapshotname -U --backing-chain
sudo qemu-img info $snapshotname -U --backing-chain

# capture original backing file name so we can revert
backingfile=$(qemu-img info $snapshotname -U | grep -Po 'backing file:\s\K(.*)')
echo "snapshotname: $snapshotname"
echo "backing file: $backingfile"

if [ "$backingfile" == "" ]; then
    echo "no backingfile, so do nothing."
else
    echo "--- stopping the vm"
    # stop VM
    virsh destroy $thedomain

    # edit hda path back to original qcow2 disk
    echo "--- revert xml: virt-xml $thedomain --edit target=$targetdisk --disk path=$backingfile --update"
    virt-xml $thedomain --edit target=$targetdisk --disk path=$backingfile --update

    # validate that we are now pointing back at original qcow2 disk
    echo "-- validate xml: virsh domblklist $thedomain"
    virsh domblklist $thedomain

    #snapshotfilename=$(echo $snapshotname | sed -n 's/^\(.*\/\)*\(.*\)/\2/p')
    snapshotfilename=$(echo $snapshotname | sed -n 's/\(.*\)\/\(.*\)\.\(.*\)$/\3/p')
    # delete snapshot metadata

    echo "--- delete snapshot metadata : virsh snapshot-delete --metadata $thedomain $snapshotfilename"
    virsh snapshot-delete --metadata $thedomain $snapshotfilename

    # delete snapshot qcow2 file
    #sudo rm $pooldir/$thedomain.$snapshotname
    echo "--- delete snapshot qcow2 file : sudo rm $snapshotname"
    sudo rm $snapshotname

    # start guest domain
    #virsh start $thedomain

fi

