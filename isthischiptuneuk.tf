# Tell terraform to use the provider and select a version.
terraform {
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "~> 1.45"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "5.0.0-rc1"
    }
  }
}

resource "hcloud_firewall" "web_server_and_ssh" {
  name = "Allow SSH and Icecast"
  rule {
    description = "Allow SSH traffic"
    direction   = "in"
    protocol    = "tcp"
    port        = "22"
    source_ips = [
      "0.0.0.0/0",
      "::/0"
    ]
  }
  rule {
    description = "Allow Icecast traffic"
    direction   = "in"
    protocol    = "tcp"
    port        = "8000"
    source_ips = [
      "0.0.0.0/0",
      "::/0"
    ]
  }
}

### Server creation with one linked primary ip (ipv4)
resource "hcloud_primary_ip" "primary_ip_1" {
  name          = "primary_ip_isthischiptuneuk"
  datacenter    = "hel1-dc2"
  type          = "ipv4"
  assignee_type = "server"
  auto_delete   = true
}

resource "hcloud_server" "server" {

  name        = "is.this.chiptune.uk"
  image       = "fedora-41"
  server_type = "cax11"
  datacenter  = "hel1-dc2"

  public_net {
    ipv4_enabled = true
    ipv4         = hcloud_primary_ip.primary_ip_1.id
    ipv6_enabled = true
  }

  ssh_keys = [ data.hcloud_ssh_key.ssh_key.id ]

}

resource "cloudflare_dns_record" "isthischiptuneuk_dns" {
  zone_id = "562026e174550b5a02d64a1108f68d00"
  comment = "Managed by Terraform"
  content = hcloud_primary_ip.primary_ip_1.ip_address
  name    = "is.this.chiptune.uk"
  proxied = false
  ttl  = 3600
  type = "A"
}

data "hcloud_ssh_key" "ssh_key" {
  name = "SSH"
}

# Set the variable value in *.tfvars file
# or using the -var="hcloud_token=..." CLI option
variable "hcloud_token" {
  sensitive = true
}

variable "cloudflare_token" {
  sensitive = true
}

# Configure the Hetzner Cloud Provider
provider "hcloud" {
  token = var.hcloud_token
}

provider "cloudflare" {
  api_token = var.cloudflare_token
}
