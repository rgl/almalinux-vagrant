VERSION=10

help:
	@echo type one of:
	@echo 	make build-uefi-libvirt
	@echo 	make build-uefi-vsphere

build-uefi-libvirt: almalinux-${VERSION}-uefi-amd64-libvirt.box
build-uefi-vsphere: almalinux-${VERSION}-uefi-amd64-vsphere.box

almalinux-${VERSION}-uefi-amd64-libvirt.box: ks.cfg upgrade.sh provision.sh almalinux.pkr.hcl Vagrantfile.template
	rm -f $@
	CHECKPOINT_DISABLE=1 PACKER_LOG=1 PACKER_LOG_PATH=$@.init.log \
		packer init almalinux.pkr.hcl
	PACKER_KEY_INTERVAL=10ms CHECKPOINT_DISABLE=1 PACKER_LOG=1 PACKER_LOG_PATH=$@.log PKR_VAR_version=${VERSION} PKR_VAR_vagrant_box=$@ \
		packer build -only=qemu.almalinux-uefi-amd64 -on-error=abort -timestamp-ui almalinux.pkr.hcl
	@./box-metadata.sh libvirt almalinux-${VERSION}-uefi-amd64 $@

almalinux-${VERSION}-uefi-amd64-vsphere.box: tmp/ks-vsphere.cfg provision.sh almalinux-vsphere.pkr.hcl Vagrantfile.template
	rm -f $@
	CHECKPOINT_DISABLE=1 PACKER_LOG=1 PACKER_LOG_PATH=$@.init.log \
		packer init almalinux-vsphere.pkr.hcl
	CHECKPOINT_DISABLE=1 PACKER_LOG=1 PACKER_LOG_PATH=$@.log PKR_VAR_version=${VERSION} PKR_VAR_ks=tmp/ks-vsphere.cfg PKR_VAR_vagrant_box=$@ \
		packer build -only=vsphere-iso.almalinux-uefi-amd64 -timestamp-ui almalinux-vsphere.pkr.hcl
	echo '{"provider":"vsphere"}' >metadata.json
	tar cvf $@ metadata.json
	rm metadata.json
	@./box-metadata.sh vsphere almalinux-${VERSION}-uefi-amd64 $@

# see https://git.almalinux.org/rpms/open-vm-tools
tmp/ks-vsphere.cfg: ks.cfg
	mkdir -p tmp
	sed -E 's,(%packages .+),\1\nopen-vm-tools,g' ks.cfg >$@

.PHONY: \
	build-uefi-libvirt \
	build-uefi-vsphere
