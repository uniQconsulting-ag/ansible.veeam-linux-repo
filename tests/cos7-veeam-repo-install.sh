#!/usr/bin/env bash
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

### Variables ###
linuxveeamreposcript="cos7-veeam-repo-install.sh"
veeamreconfigfile="/root/.veeamreconfig"
ansible_role="uniQconsulting.veeam_linux_repo"
ansiblerootfolder="/etc/ansible/"
ansibleconfigfile="/etc/ansible/ansible.cfg"
ansiblerolefolder="/etc/ansible/roles/"
ansibleplaybookfolder="/etc/ansible/roles/uniQconsulting.veeam_linux_repo/tests/"

if [ ! -f $veeamreconfigfile ]
then
  echo "[*] Configure Linux Veeam Proxy Server"

  ### Test if ansible installed and install it, if not present ###
  if [ $(rpm -q ansible | grep -v package | wc -l) -eq 0 ]
  then
    echo "[*] Install ansible with yum"
    yum -y install ansible 
  fi

  if [ $(rpm -q epel-release | grep -v package | wc -l) -eq 0 ]
  then
    echo "[*] Install epel-release with yum"
    yum -y install epel-release
  fi

  if [ $(rpm -q open-vm-tools | grep -v package | wc -l) -eq 0 ]
  then
    echo "[*] Install open-vm-tools with yum"
    yum -y install open-vm-tools
    systemctl start vmtoolsd
    systemctl enable vmtoolsd
  fi


  # Create Vars File from VMware Tools
  echo "[*] Create vars file from VMware Tools"
  vmtoolsd --cmd "info-get guestinfo.ovfenv" | grep -i "Property oe" | awk '{ print $2 $3 }' | sed 's/oe:key\=\"//' | sed 's/oe\:value\=//' | sed 's/\"/\: /' | sed 's/\/>//' > /etc/ansible/$(hostname -s).yml

  ### Create Ansible Roles and Playbooks folders ###
  test -d $ansiblerolefolder || echo "[*] Create folder " $ansiblerolefolder && mkdir -p $ansiblerolefolder

  ### Configure Ansible ###
  echo "[*] Configure Ansible"
  sed -i 's|^#inventory.*|inventory      = /etc/ansible/hosts|g' $ansibleconfigfile
  sed -i 's|^#roles_path.*|roles_path    = /etc/ansible/roles|g' $ansibleconfigfile
  sed -i 's|^#remote_user.*|remote_user = root|g' $ansibleconfigfile
  sed -i 's|^#log_path.*|log_path = /var/log/ansible.log|g' $ansibleconfigfile
  sed -i 's|^#nocows.*|nocows = 1|g' $ansibleconfigfile

  ## Ansible CentOS 7 Linux Veeam Repo
  echo "[*] Install Role and Deps from Ansible Galaxy: $ansible_role"
  wget -q --spider https://galaxy.ansible.com
  if [ $? -ne 0 ]
  then
    echo "[!] Cannot connect to Ansible Galaxy"
    echo "[!] Don't update $ansible_role"
  else
    ansible-galaxy install -f $ansible_role
  fi

  # Run Ansible and install Linux Veeam Repo Proxy
  echo "[*] Install CentOS 7 Veeam Linux Repo with Ansible"
  ansible-playbook $ansibleplaybookfolder"local-install.yml"

  touch $veeamreconfigfile
else
  echo "[*] Don't configure Linux Veeam Proxy Server"
  echo "[*] If you want to reconfigure Linux Veeam Proxy Server, please remove" $veeamreconfigfile
  exit 0
fi
