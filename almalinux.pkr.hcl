packer {
  required_plugins {
    # see https://github.com/hashicorp/packer-plugin-qemu
    qemu = {
      source  = "github.com/hashicorp/qemu"
      version = "1.1.6"
    }
    # see https://github.com/hashicorp/packer-plugin-proxmox
    proxmox = {
      version = "1.2.4"
      source  = "github.com/hashicorp/proxmox"
    }
    # see https://github.com/hashicorp/packer-plugin-vagrant
    vagrant = {
      source  = "github.com/hashicorp/vagrant"
      version = "1.1.7"
    }
  }
}

variable "http_bind_address" {
  type    = string
  default = env("PACKER_HTTP_BIND_ADDRESS")
}

variable "disk_size" {
  type    = string
  default = 40 * 1024 # MiB
}

variable "iso_url" {
  type    = string
  default = "http://mirrors.ptisp.pt/almalinux/10/isos/x86_64/AlmaLinux-10.2-x86_64-boot.iso"
}

variable "iso_checksum" {
  type    = string
  default = "sha256:b3f865468075bcada8f208d830289302c67529789d668041d24e8d6fc697ba6a"
}

variable "proxmox_node" {
  type    = string
  default = env("PROXMOX_NODE")
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

source "qemu" "almalinux-uefi-amd64" {
  headless          = true
  accelerator       = "kvm"
  machine_type      = "q35"
  efi_boot          = true
  efi_firmware_code = "/usr/share/OVMF/OVMF_CODE_4M.fd"
  efi_firmware_vars = "/usr/share/OVMF/OVMF_VARS_4M.fd"
  boot_command = [
    "<home>e",                       // edit the install boot entry.
    "<down><down>",                  // go to the linux line.
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
  net_device     = "virtio-net"
  http_directory = "."
  iso_checksum   = var.iso_checksum
  iso_url        = var.iso_url
  cpus           = 2
  memory         = 4 * 1024
  qemuargs = [
    ["-cpu", "host"],
  ]
  ssh_username     = "vagrant"
  ssh_password     = "vagrant"
  ssh_timeout      = "60m"
  shutdown_command = "echo vagrant | sudo -S poweroff"
}

source "proxmox-iso" "almalinux-uefi-amd64" {
  template_name            = "template-almalinux-${var.version}-uefi"
  template_description     = <<-EOS
                              See https://github.com/rgl/almalinux-vagrant

                              ```
                              Build At: ${timestamp()}
                              ```
                              EOS
  tags                     = "almalinux-${var.version}-uefi;template"
  insecure_skip_tls_verify = true
  node                     = var.proxmox_node
  machine                  = "q35"
  http_directory           = "."
  http_bind_address        = var.http_bind_address
  boot_command = [
    "<home>e",                       // edit the install boot entry.
    "<down><down>",                  // go to the linux line.
    "<end><bs><bs><bs><bs><bs><bs>", // delete the "quiet" word.
    " net.ifnames=0",
    " ipv6.disable=1",
    " inst.cmdline",
    " inst.ksstrict",
    " inst.ks=http://{{.HTTPIP}}:{{.HTTPPort}}/${var.ks}",
    "<f10>" // boot.
  ]
  boot_wait = "5s"
  bios      = "ovmf"
  efi_config {
    efi_storage_pool = "local-lvm"
  }
  cpu_type = "host"
  cores    = 2
  memory   = 4 * 1024
  vga {
    type   = "qxl"
    memory = 16
  }
  network_adapters {
    model  = "virtio"
    bridge = "vmbr0"
  }
  scsi_controller = "virtio-scsi-single"
  disks {
    type         = "scsi"
    io_thread    = true
    ssd          = true
    discard      = true
    disk_size    = "${var.disk_size}M"
    storage_pool = "local-lvm"
    format       = "raw"
  }
  boot_iso {
    type             = "scsi"
    iso_storage_pool = "local"
    iso_url          = var.iso_url
    iso_checksum     = var.iso_checksum
    iso_download_pve = true
    unmount          = true
  }
  os           = "l26"
  ssh_username = "vagrant"
  ssh_password = "vagrant"
  ssh_timeout  = "60m"
}

build {
  sources = [
    "source.qemu.almalinux-uefi-amd64",
    "source.proxmox-iso.almalinux-uefi-amd64",
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
    only = [
      "qemu.almalinux-uefi-amd64",
    ]
    output               = var.vagrant_box
    vagrantfile_template = "Vagrantfile.template"
  }
}
