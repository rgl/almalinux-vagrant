#!/bin/bash
set -eux

# install the Guest Additions.
if [ -n "$(grep VBOX /sys/firmware/acpi/tables/APIC)" ]; then
# install the VirtualBox Guest Additions.
# this will be installed at /opt/VBoxGuestAdditions-VERSION.
# REMOVE_INSTALLATION_DIR=0 is to fix a bug in VBoxLinuxAdditions.run.
# See http://stackoverflow.com/a/25943638.
dnf install -y kernel-headers kernel-devel gcc bzip2 tar make
rpm -qa 'kernel*' | sort
mkdir -p /mnt
mount /dev/sr1 /mnt
while [ ! -f /mnt/VBoxLinuxAdditions.run ]; do sleep 1; done
# NB we ignore exit code 2 (system must be rebooted).
REMOVE_INSTALLATION_DIR=0 /mnt/VBoxLinuxAdditions.run --target /tmp/VBoxGuestAdditions || [ $? -eq 2 ]
rm -rf /tmp/VBoxGuestAdditions
umount /mnt
eject /dev/sr1
modinfo vboxguest
else
# install the qemu-kvm Guest Additions.
dnf install -y qemu-guest-agent spice-vdagent
fi

# reboot.
nohup bash -c "ps -eo pid,comm | awk '/sshd/{print \$1}' | xargs kill; sync; reboot"
