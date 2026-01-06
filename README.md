This builds an up-to-date Vagrant AlmaLinux Base Box.

Currently this targets [AlmaLinux 10](https://almalinux.org/).

# Usage

Install [Packer](https://www.packer.io/) and [Vagrant](https://www.vagrantup.com/).

## qemu-kvm usage

Install qemu-kvm:

```bash
apt-get install -y qemu-kvm
apt-get install -y sysfsutils
systool -m kvm_intel -v
```

Type `make build-libvirt` and follow the instructions.

Try the example guest:

```bash
cd example
apt-get install -y virt-manager libvirt-dev
vagrant plugin install vagrant-libvirt
vagrant up --provider=libvirt
vagrant ssh
exit
vagrant destroy -f
```

# Kickstart

The AlmaLinux installation iso uses the Anaconda installer to install AlmaLinux.
During the installation it will ask you some questions and it will also
store your answers in the `/root/anaconda-ks.cfg` (aka kickstart) file.
This file is later used to fully automate a new installation by specifying
its location in the `inst.ks` kernel command line argument.

# Reference

* [AlmaLinux 10.1 Release Notes](https://wiki.almalinux.org/release-notes/10.1.html)
* [Product Documentation for Red Hat Enterprise Linux 10](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/10)
* [Anaconda boot options](https://anaconda-installer.readthedocs.io/en/latest/boot-options.html)
* [Kickstart manual](http://pykickstart.readthedocs.io/en/latest/kickstart-docs.html)
* [Kickstart script file format reference](https://docs.redhat.com/en/documentation/red_hat_enterprise_linux/10/html/automatically_installing_rhel/kickstart-script-file-format-reference)
* [Kickstart commands and options reference](https://docs.redhat.com/en/documentation/red_hat_enterprise_linux/10/html/automatically_installing_rhel/kickstart-commands-and-options-reference)
* [Automated installation workflow](https://docs.redhat.com/en/documentation/red_hat_enterprise_linux/10/html/automatically_installing_rhel/automated-installation-workflow)
* [Mirror list](https://mirrors.almalinux.org)
* [AlmaLinux cloud-images](https://github.com/AlmaLinux/cloud-images)
