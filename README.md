This builds an up-to-date Vagrant AlmaLinux Base Box.

Currently this targets [AlmaLinux 9](https://almalinux.org/).

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
store your anwsers in the `/root/anaconda-ks.cfg` (aka kickstart) file.
This file is later used to fully automate a new installation by specifying
its location in the `inst.ks` kernel command line argument.

# Reference

* [AlmaLinux 9.0 Release Notes](https://wiki.almalinux.org/release-notes/9.0.html)
* [Product Documentation for Red Hat Enterprise Linux 9](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/9)
* [Anaconda boot options](https://anaconda-installer.readthedocs.io/en/latest/boot-options.html)
* [Kickstart manual](http://pykickstart.readthedocs.io/en/latest/kickstart-docs.html)
* [Kickstart Syntax Reference](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/9/html/performing_an_advanced_rhel_installation/kickstart_references)
* [Automating the Installation with Kickstart](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/9/html/performing_an_advanced_rhel_installation/performing_an_automated_installation_using_kickstart)
* [Mirror list](https://mirrors.almalinux.org)
* [AlmaLinux cloud-images](https://github.com/AlmaLinux/cloud-images)
