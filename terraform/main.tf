module "kube-hetzner" {
  providers = {
    hcloud = hcloud
  }

  hcloud_token = var.hcloud_token
  source = "kube-hetzner/kube-hetzner/hcloud"
  ssh_public_key = file("./hetzner_ssh.key.pub")
  ssh_private_key = file("./hetzner_ssh.key")
  network_region = "us-east"

  control_plane_nodepools = [
    {
      name        = "control-plane",
      server_type = "cpx11",
      location    = "ash",
      labels      = [],
      taints      = ["node-role.kubernetes.io/control-plane=:PreferNoSchedule"],
      count       = 3
    }
  ]

  agent_nodepools = [
    {
      name        = "agent",
      server_type = "cpx11",
      location    = "ash",
      labels      = [],
      taints      = [],
      count       = 2
    }
  ]

  load_balancer_type     = "lb11"
  load_balancer_location = "ash"
  system_upgrade_use_drain = true

  dns_servers = [
    "1.1.1.1",
    "8.8.8.8",
    "2606:4700:4700::1111",
  ]

  create_kubeconfig = false
  create_kustomization = false
}

provider "hcloud" {
  token = var.hcloud_token
}

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = ">= 1.49.1"
    }
  }
}

output "kubeconfig" {
  value     = module.kube-hetzner.kubeconfig
  sensitive = true
}

variable "hcloud_token" {
  sensitive = true
  default   = ""
}
