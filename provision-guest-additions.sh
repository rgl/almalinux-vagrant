#!/bin/bash
set -eux

# install the Guest Additions.
if [ "$(systemd-detect-virt)" == "kvm" ]; then
# install the qemu-kvm Guest Additions.
# see https://packages.fedoraproject.org/pkgs/qemu/qemu-guest-agent/
# see https://packages.fedoraproject.org/pkgs/spice-vdagent/spice-vdagent/
dnf install -y qemu-guest-agent spice-vdagent
else
echo 'ERROR: Unknown VM host.' || exit 1
fi

# reboot.
nohup bash -c "ps -eo pid,comm | awk '/sshd/{print \$1}' | xargs kill; sync; reboot"
