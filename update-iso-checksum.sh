#!/bin/bash
# this will update the almalinux.json file with the current netboot image checksum.
# see https://wiki.almalinux.org/release-notes/10.1.html#installation-instructions
set -euxo pipefail
wget -qO- https://repo.almalinux.org/almalinux/RPM-GPG-KEY-AlmaLinux-10 | gpg --import
iso_url=$(perl -n -e '/"(.+\.iso)"/ && print $1' almalinux.pkr.hcl)
iso_checksum_url="$(dirname $iso_url)/CHECKSUM"
iso_checksum_file=$(basename $iso_checksum_url)
curl -O -L --silent --show-error $iso_checksum_url
gpg --verify $iso_checksum_file
iso_checksum=$(grep -E "SHA256.+$(basename $iso_url)" $iso_checksum_file | awk '{print $4}')
sed -i -E "s,\"sha.+?:[a-f0-9]*\",\"sha256:$iso_checksum\",g" almalinux.pkr.hcl
rm $iso_checksum_file
echo 'iso_checksum updated successfully'
