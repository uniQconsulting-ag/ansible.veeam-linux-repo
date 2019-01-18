#!/usr/bin/bash
###############################################################################################################
# DESC: tool to setup linux configurations with ansible
# $Author: mike $
# $Revision: 0.1 $
# $RCSfile: install-script.sh,v $
###############################################################################################################
# Copyright (C) 2018  Mike
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.

export PATH=$HOME/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/root/bin

# --------- Test VM on VMware Infrastructure ---------
if [ $(dmidecode -s system-product-name | cut -d ' ' -f1 ) == "VMware" ]
then
  # --------- Test if open-vm-tools are installed. Install it, if not present ---------
  if [ $(rpm -q open-vm-tools | grep -v package | wc -l) -eq 0 ]
  then
    echo "[*] Install open-vm-tools with yum"
    yum -y install open-vm-tools
    systemctl start vmtoolsd
    systemctl enable vmtoolsd
  fi

  # --------- Create Vars File from VMware Tools for Ansible ---------
  echo "[*] Create vars file from VMware Tools"
  vmtoolsd --cmd "info-get guestinfo.ovfenv" | grep -i "Property oe" | awk '{ print $2 $3 }' | sed 's/oe:key\=\"//' | sed 's/oe\:value\=//' | sed 's/\"/\: /' | sed 's/\/>//' > /etc/ansible/$(hostname -s).yml
  sed -i 's/"[T|t]rue"/true/g' /etc/ansible/$(hostname -s).yml
  sed -i 's/"[F|f]alse"/false/g' /etc/ansible/$(hostname -s).yml
fi

ansible-playbook /etc/ansible/playbook/network-setup.yml

if [ ! -f /root/.veeam-appliance-setup ]
then
  ansible-playbook /etc/ansible/playbook/veeam-appliance-setup.yml
  touch /root/.veeam-appliance-setup
fi
