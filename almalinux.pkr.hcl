packer {
  required_plugins {
    # see https://github.com/hashicorp/packer-plugin-qemu
    qemu = {
      source  = "github.com/hashicorp/qemu"
      version = "1.1.3"
    }
    # see https://github.com/hashicorp/packer-plugin-vagrant
    vagrant = {
      source  = "github.com/hashicorp/vagrant"
      version = "1.1.5"
    }
  }
}

variable "disk_size" {
  type    = string
  default = 40 * 1024 # MiB
}

variable "iso_url" {
  type    = string
  default = "http://mirrors.ptisp.pt/almalinux/10/isos/x86_64/AlmaLinux-10.0-x86_64-boot.iso"
}

variable "iso_checksum" {
  type    = string
  default = "sha256:a1549729bfb66a28e3546c953033c9928eae7280917bb1c490983dba3bb9941c"
}

variable "ks" {
  type    = string
  default = "ks.cfg"
}

variable "version" {
  type    = string
  default = "10"
}

variable "vagrant_box" {
  type = string
}

source "qemu" "almalinux-amd64" {
  accelerator  = "kvm"
  machine_type = "q35"
  boot_command = [
    "<home>e", // edit the install boot entry.
    "<down><down>", // go to the linux line.
    "<end><bs><bs><bs><bs><bs><bs>", // delete the "quiet" word.
    " net.ifnames=0",
    " ipv6.disable=1",
    " inst.cmdline",
    " inst.ksstrict",
    " inst.ks=http://{{.HTTPIP}}:{{.HTTPPort}}/${var.ks}",
    "<f10>" // boot.
  ]
  boot_wait      = "5s"
  disk_cache     = "unsafe"
  disk_discard   = "unmap"
  disk_interface = "virtio-scsi"
  disk_size      = var.disk_size
  format         = "qcow2"
  headless       = true
  net_device     = "virtio-net"
  http_directory = "."
  iso_checksum   = var.iso_checksum
  iso_url        = var.iso_url
  cpus           = 2
  memory         = 2048
  qemuargs = [
    ["-cpu", "host"],
  ]
  ssh_username     = "vagrant"
  ssh_password     = "vagrant"
  ssh_timeout      = "60m"
  shutdown_command = "echo vagrant | sudo -S poweroff"
}

build {
  sources = [
    "source.qemu.almalinux-amd64",
  ]

  provisioner "shell" {
    execute_command   = "echo vagrant | sudo -S {{ .Vars }} bash {{ .Path }}"
    expect_disconnect = true
    scripts = [
      "upgrade.sh",
      "provision-guest-additions.sh",
      "provision.sh",
    ]
  }

  post-processor "vagrant" {
    output               = var.vagrant_box
    vagrantfile_template = "Vagrantfile.template"
  }
}
