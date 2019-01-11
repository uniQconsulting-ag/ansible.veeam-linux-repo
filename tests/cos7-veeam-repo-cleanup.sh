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
veeamreconfigfile="/root/.veeamreconfig"
ansiblerolefolder="/etc/ansible/roles/"
install_script_url="https://raw.githubusercontent.com/uniQconsulting-ag/ansible.veeam-linux-repo/master/tests/cos7-veeam-repo-install.sh"

echo "CLEANUP VM"
echo "-------------------------------------------------------------------------"
echo
echo " Remove old config"
cd /etc/ansible && rm -fv *.yml
echo
echo "Remove $veeamreconfigfile"
rm -fv $veeamreconfigfile
echo
echo "Install Veeam repo configuration toolset"
curl "$install_script_url" | sh 
echo
echo "Remove $veeamreconfigfile"
rm -fv $veeamreconfigfile
echo
echo "Clean up Yum Repos"
yum clean all
rm -rf /var/cache/yum
echo
echo "Remove old Kernels"
package-cleanup -y --oldkernels --count=1
echo
echo "Clean up /etc/fstab"
sed -i '/ nfs4 /d' /etc/fstab
echo
echo "Remove bash history"
rm -fv /root/.bash_history
echo
echo "
   VM CLEANUP DON, YOU CAN NOW SHUTDOWN AND EXPORT THE OVA
   "
