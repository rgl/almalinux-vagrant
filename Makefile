VERSION=8.6

help:
	@echo type make build-libvirt

build-libvirt: almalinux-${VERSION}-amd64-libvirt.box

almalinux-${VERSION}-amd64-libvirt.box: ks.cfg upgrade.sh provision.sh almalinux.pkr.hcl Vagrantfile.template
	rm -f $@
	PACKER_KEY_INTERVAL=10ms CHECKPOINT_DISABLE=1 PACKER_LOG=1 PACKER_LOG_PATH=$@.log PKR_VAR_vagrant_box=$@ \
		packer build -only=qemu.almalinux-amd64 -on-error=abort -timestamp-ui almalinux.pkr.hcl
	@echo BOX successfully built!
	@echo to add to local vagrant install do:
	@echo vagrant box add -f almalinux-${VERSION}-amd64 almalinux-${VERSION}-amd64-libvirt.box

.PHONY: buid-libvirt
