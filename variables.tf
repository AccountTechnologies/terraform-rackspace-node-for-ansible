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
