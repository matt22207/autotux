#!/bin/bash
date "+%Y%m%d%H%M"

# name of domain, snapshot, and target disk device
thedomain="win10"
snapshotname="win10_bak_`date '+%Y%m%d%H%M'`"
targetdisk="vda"

# look at '<disk>' types, should be just 'file' types
virsh dumpxml $thedomain | grep '<disk' -A5

# show block level devices and qcow2 paths (hda,hdb,..etc)
virsh domblklist $thedomain

# create snapshot in default pool location
# file name is $thedomain.$snapshotname
virsh snapshot-create-as $thedomain --name $snapshotname --disk-only

# list snapshot
virsh snapshot-list $thedomain

# show block level devices and qcow2 paths (hda,hdb,..etc)
virsh domblklist $thedomain
