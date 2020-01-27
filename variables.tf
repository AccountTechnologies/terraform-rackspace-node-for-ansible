# Create instance
resource "openstack_compute_instance_v2" "instance" {
  count       = var.node_count
  name        = "${var.name_prefix}-${format("%03d", count.index)}"
  image_name  = var.image_name
  flavor_name = var.flavor_nam
  key_pair    = var.ssh_keypair

  dynamic "network" {
    iterator = network_name
    for_each = var.networks
    content {
      uuid   = network_name.value.uuid
      name   = network_name.value.name
    }
  }


locals {
  internal_network_index = index(var.networks.*.uuid, var.internal_network_uuid) 
  public_network_index = contains(var.networks.*.uuid,"00000000-0000-0000-0000-000000000000") ? index(var.networks.*.uuid, "00000000-0000-0000-0000-000000000000") : 0
  has_public_network =  contains(var.networks.*.uuid,"00000000-0000-0000-0000-000000000000")
  ssh_user = var.ssh_alt_user
  ssh_bastion_host = var.ssh_bastion_host
  ssh_key = file(var.ssh_key)
  servers = [
    for instance in openstack_compute_instance_v2.instance:
    {
      "id" = instance.id,
      "hostname" = instance.name 
      "ssh_bastion_host" = var.ssh_bastion_host,
      "ssh_key" = var.ssh_key,
      "ssh_user" = var.ssh_alt_user,
      "ssh_host" = "${(var.ssh_bastion_host == "" && local.has_public_network )  ? instance.network[local.public_network_index].fixed_ip_v4 : instance.network[local.internal_network_index].fixed_ip_v4}",
      "internal_network_ip" = instance.network[local.internal_network_index].fixed_ip_v4
      "public_network_ip" = ( local.has_public_network )  ? instance.network[local.public_network_index].fixed_ip_v4 : ""
      "host" = (var.ssh_bastion_host == "" && local.has_public_network )  ? instance.network[local.public_network_index].fixed_ip_v4 : instance.network[local.internal_network_index].fixed_ip_v4
      "roles" = var.roles,
      "host_ns" =  var.host_ns,
      "host_domain" =  var.host_domain,
    }
  ]
}

resource null_resource "prepare_nodes" {
  count = var.node_count

  triggers = {
    instance_id = "${element(openstack_compute_instance_v2.instance.*.id, count.index)}"
  }

  provisioner "remote-exec" {
    connection {
      # External
      bastion_host     = var.ssh_bastion_host
      bastion_host_key = file(var.ssh_key)

      # Internal
      host        = (var.ssh_bastion_host == "" && local.has_public_network )  ? openstack_compute_instance_v2.instance[count.index].network[local.public_network_index].fixed_ip_v4 : openstack_compute_instance_v2.instance[count.index].network[local.internal_network_index].fixed_ip_v4
      user        = var.ssh_user
      private_key = file(var.ssh_key)
    }
    inline = [
      "ip_addresses=\"${join(" ", var.ssh_allow_ip)}\" ",
      "for i in $ip_addresses; do ufw allow from $i to any port 22; done ",
      "echo 'y' | ufw enable",
      "ufw status",
      "exists=$(grep -c \"${var.ssh_alt_user}\" /etc/passwd)",
      "if [ $exists -eq 0 ]; then",
      "   adduser --disabled-password --gecos '' ${var.ssh_alt_user}",
      "   usermod -aG sudo ${var.ssh_alt_user}",
      "   mkdir -p $(getent passwd ${var.ssh_alt_user} | cut -d: -f6)/.ssh",
      "   cp ~/.ssh/authorized_keys $(getent passwd ${var.ssh_alt_user} | cut -d: -f6)/.ssh/",
      "   chmod 700 $(getent passwd ${var.ssh_alt_user} | cut -d: -f6)/.ssh",
      "   chmod 600 $(getent passwd ${var.ssh_alt_user} | cut -d: -f6)/.ssh/authorized_keys",
      "   chown -R ${var.ssh_alt_user}: $(getent passwd ${var.ssh_alt_user} | cut -d: -f6)/.ssh",
      "fi",
    ]
  }
}
variable node_count {
  description = "Number of nodes to be created"
}

variable name_prefix {
  description = "Prefix for the node name"
}

variable flavor_name {
  description = "Flavor to be used for this node"
}

variable image_name {
  description = "Image to boot this node from"
}

variable ssh_user {
  description = "SSH user name"
}

variable ssh_key {
  description = "Path to private SSH key"
}

variable ssh_keypair {
  description = "SSH keypair to inject in the instance (previosly created in OpenStack)"
}

variable ssh_allow_ip {
  description = "SSH IP to allow ufw"
  type        = list(string)
}

variable ssh_alt_user {
  description = "alternate user to create, so can ssh after disabling root ssh"
}

variable internal_network_uuid {
 description = "Name of the network to attach this node to"
}

variable networks {
  type        = list
  description = "list of required networks"
  default = ["public","private"]
}

variable roles {
  type        = list(string)
  description = "List of RKE-compliant roles for this node"
}

variable host_ns {
  type        = list(string)
  description = "list of nameservers"
}
variable host_domain {
  type        = string
  description = "name of fqdn"
}
variable ssh_bastion_host {
  description = "Bastion SSH host"
  default = ""
}
