#!/bin/bash
# DESC: check if nfs-share is mounted and tries to remount
# WHO: melvin.suter@uniqconsulting.ch
# DATE: 20190926


###########
#  CONF
###########
mountpoint="{{ nfs_mountpoint }}"
nfsshare="{{ nfs_share }}"
mailto='{{ nfs_mailto }}'
mailcontent=""
error=false


###########
#  SCRIPT
###########

mountoutput="$(mount)"

# Check mount
if [[ $mountoutput != *"$nfsshare on $mountpoint"* ]]; then
    mailcontent="${mailcontent}\nNFS Share not mounted."
    error=true
fi

# Try remount
if $error; then
    # Create dir if non existant
    if [ ! -d "$mountpoint" ]; then
        mkdir -p $mountpoint
    fi

    # Remount and wait
    mount -a
    sleep 10

    # Check mount-state
    if [[ $mountoutput != *"$nfsshare on $mountpoint"* ]]; then
        mailcontent="${mailcontent}\nRemount didn't work."
    fi

    # Send mail
    printf "There was an error with the veeam-linux-repo:\n\n${mailcontent}" | mailx -s "[$(hostname)] Linux Veeam Repo - Error" -r $mailto $mailto
fi

