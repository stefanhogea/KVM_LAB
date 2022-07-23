terraform {
  required_providers {
    libvirt = {
      source = "dmacvicar/libvirt"
      version ="0.6.14"
    }
  }
}

provider "libvirt" {
  ## Configuration options
  #alias = "server2"
  uri   = "qemu+ssh://root@192.168.0.105/system"
}

variable "VM_USER" {
    default ="root"
    type = string
}

variable "VM_COUNT" {
    default = 3
    type = number
}

# Defining VM Volume
resource "libvirt_volume" "ubuntu-qcow2" {
  count = var.VM_COUNT
  name = "ubuntu-${count.index}"
  #name = "ubuntu"
  pool = "default" # List storage pools using virsh pool-list
  #source = "https://cdimage.debian.org/debian-cd/current/amd64/iso-cd/debian-11.4.0-amd64-netinst.iso"
  #source = "./debian-11.4.0-amd64-netinst.iso"
  source = "bionic-minimal-cloudimg-amd64_20GB.img" 
  #to see info about the base iamge you are using before running terraform: sudo qemu-img info /var/lib/libvirt/images/bionic-minimal-cloudimg-amd64_20GB.img
  #to increase virtual disk size: sudo qemu-img resize /var/lib/libvirt/images/bionic-minimal-cloudimg-amd64_20GB.img +20G
  format = "qcow2"
  #size = "2000000000"
}

# resource "libvirt_network" "test_network" {
#    name = "test_network"
#    mode = "bridge"
#    bridge = "br0"
#    #addresses = ["192.168.0.0/24"]
#    dhcp {
#       enabled = true
#    }
   
# }

resource "libvirt_cloudinit_disk" "commoninit" {
  name = "commoninit.iso"
  pool = "default" # List storage pools using virsh pool-list
  user_data      = "${data.template_file.user_data.rendered}"
}


data "template_file" "user_data" {
  template = "${file("${path.module}/user-data.cfg")}"
}

#actually not using this right now as my router is providing dhcp leases
# data "template_file" "network_config" {
#     template = file("${path.module}/network-config.cfg")
# }

# Define KVM domain to create
resource "libvirt_domain" "ubuntu" {
  #count = "3"
  name   = "ubuntu${count.index}"
  count = var.VM_COUNT
  #name = "ubuntu"
  memory = "2048"
  vcpu   = 2
  autostart = true
  cloudinit = "${libvirt_cloudinit_disk.commoninit.id}"
  #qemu_agent = true


    network_interface {
        network_name = "host-bridge"
        #bridge = "br0"
        #hostname = "testvm"
        #network_id = "4acc84d2-7837-4edc-9be7-dd9d4f585413"  
        #network_id = "${libvirt_network.test_network.id}"
        }

    disk {
    volume_id = "${libvirt_volume.ubuntu-qcow2[count.index].id}"
    #volume_id = "${libvirt_volume.ubuntu-qcow2.id}"
    }

  
  console {
    type = "pty"
    target_type = "serial"
    target_port = "0"
  }

  graphics {
    type = "spice"
    listen_type = "address"
    autoport = true
  }
}

#Output Server IP
# output "ip" { 
#     value = "${libvirt_domain.ubuntu.network_interface.0.addresses.0}"
#             }