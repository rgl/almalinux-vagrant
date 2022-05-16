#!/bin/bash
set -eux

# configure the dnf number of parallel downloads.
# NB the default is 3.
echo 'max_parallel_downloads=10' >>/etc/dnf/dnf.conf

# remove old kernel packages.
dnf remove -y $(rpm -qa 'kernel*' | grep -v "$(uname -r)" | tr \\n ' ')

# remove uneeded firmware.
dnf remove -y linux-firmware

# make sure we cannot directly login as root.
usermod --lock root

# let users in the wheel group use root permissions without sudo asking for a password.
cat >/etc/sudoers.d/wheel <<'EOF'
# Allow users in wheel group to run all commands without a password.
%wheel ALL=(ALL) NOPASSWD:ALL
EOF
chmod 440 /etc/sudoers.d/wheel

# install the vagrant public key.
# NB vagrant will replace it on the first run.
install -d -m 700 /home/vagrant/.ssh
pushd /home/vagrant/.ssh
curl -so authorized_keys https://raw.githubusercontent.com/hashicorp/vagrant/master/keys/vagrant.pub
chmod 600 authorized_keys
chown -R vagrant:vagrant .
popd

# install the nfs client to support nfs synced folders in vagrant.
dnf -y install nfs-utils

# disable the DNS reverse lookup on the SSH server. this stops it from
# trying to resolve the client IP address into a DNS domain name, which
# is kinda slow and does not normally work when running inside VB.
echo UseDNS no >>/etc/ssh/sshd_config

# use the up/down arrows to navigate the bash history.
# NB to get these codes, press ctrl+v then the key combination you want.
cat >>/etc/inputrc <<"EOF"
"\e[A": history-search-backward
"\e[B": history-search-forward
set show-all-if-ambiguous on
set completion-ignore-case on
EOF

# reset the machine-id.
# NB systemd will re-generate it on the next boot.
# NB machine-id is indirectly used in DHCP as Option 61 (Client Identifier), which
#    the DHCP server uses to (re-)assign the same or new client IP address.
# see https://www.freedesktop.org/software/systemd/man/machine-id.html
# see https://www.freedesktop.org/software/systemd/man/systemd-machine-id-setup.html
echo '' >/etc/machine-id

# reset the random-seed.
# NB systemd-random-seed re-generates it on every boot and shutdown.
# NB you can prove that random-seed file does not exist on the image with:
#       sudo virt-filesystems -a ~/.vagrant.d/boxes/almalinux-36-amd64/0/libvirt/box.img
#       sudo guestmount -a ~/.vagrant.d/boxes/almalinux-36-amd64/0/libvirt/box.img -m /dev/sda1 --pid-file guestmount.pid --ro /mnt
#       sudo ls -laF /mnt/var/lib/systemd
#       sudo guestunmount /mnt
#       sudo bash -c 'while kill -0 $(cat guestmount.pid) 2>/dev/null; do sleep .1; done; rm guestmount.pid' # wait for guestmount to finish.
# see https://www.freedesktop.org/software/systemd/man/systemd-random-seed.service.html
# see https://manpages.debian.org/stretch/manpages/random.4.en.html
# see https://manpages.debian.org/stretch/manpages/random.7.en.html
# see https://github.com/systemd/systemd/blob/master/src/random-seed/random-seed.c
# see https://github.com/torvalds/linux/blob/master/drivers/char/random.c
systemctl stop systemd-random-seed
rm -f /var/lib/systemd/random-seed

# clean packages.
dnf clean all

# zero the free disk space -- for better compression of the box file.
# NB prefer discard/trim (safer; faster) over creating a big zero filled file
#    (somewhat unsafe as it has to fill the entire disk, which might trigger
#    a disk (near) full alarm; slower; slightly better compression).
root_dev="$(findmnt -no SOURCE /)"
if [ "$(lsblk -no DISC-GRAN $root_dev | awk '{print $1}')" != '0B' ]; then
    while true; do
        output="$(fstrim -v /)"
        cat <<<"$output"
        sync && sync && sync && blockdev --flushbufs $root_dev && sleep 15
        if [ "$output" == '/: 0 B (0 bytes) trimmed' ]; then
            break
        fi
    done
else
    dd if=/dev/zero of=/EMPTY bs=1M || true; rm -f /EMPTY
fi
