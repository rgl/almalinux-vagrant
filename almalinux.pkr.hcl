variable "disk_size" {
  type    = string
  default = "40960"
}

variable "iso_url" {
  type    = string
  default = "http://mirrors.pt/almalinux/9.0/isos/x86_64/AlmaLinux-9.0-x86_64-boot.iso"
}

variable "iso_checksum" {
  type    = string
  default = "sha256:c41ce7bc2f4ab27a3597b3e160fc8b01c56a6b58e1046a4a23b8518fb9e9a61f"
}

variable "ks" {
  type = string
  default = "ks.cfg"
}

variable "version" {
  type = string
  default = "9"
}

variable "vagrant_box" {
  type = string
}

source "qemu" "almalinux-amd64" {
  accelerator = "kvm"
  machine_type = "q35"
  boot_command = [
    "<up><tab>",
    "<leftCtrlOn>w<leftCtrlOff>", // delete the "quiet" word.
    " inst.cmdline",
    " inst.ksstrict",
    " inst.ks=http://{{.HTTPIP}}:{{.HTTPPort}}/${var.ks}",
    "<enter>"
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
