terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "4.61.0"
    }
  }
}

provider "google" {
  credentials = file("/Users/seebo/Documents/Uni/DevOps/Allocate-a-virtual-machine-in-the-cloud/devops-384013-04274ab32f14.json")

  project = "devops-384013"
  region  = "eu-central1"
  zone    = "europe-central2-a"
}

resource "google_compute_network" "vpc_network" {
  name                    = "terraform-network"
  auto_create_subnetworks = "true"
}

resource "google_compute_instance" "vm_instance" {
  name         = "terraform-instance"
  machine_type = "e2-micro"

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }

  network_interface {
    network = google_compute_network.vpc_network.name
    access_config {
      // This block is empty to request an ephemeral IP address.
    }
  }

  metadata = {
    ssh-keys = "devOps:${file("devops-project-nginx-git/.ssh/devops")}"
  }

  // Include the startup script here
  metadata_startup_script = file("${path.module}/startup-script.sh")
}

resource "google_compute_firewall" "allow_http_https" {
  name    = "allow-http-https"
  network = google_compute_network.vpc_network.name

  allow {
    protocol = "tcp"
    ports    = ["80", "443"]
  }

  source_ranges = ["0.0.0.0/0"]
}


resource "google_service_account" "myaccount" {
  account_id   = "myaccount"
  display_name = "My Service Account"
}

resource "google_service_account_key" "mykey" {
  service_account_id = google_service_account.myaccount.name
  public_key_type    = "TYPE_X509_PEM_FILE"
}

output "instanceIPv4" {
  value = google_compute_instance.vm_instance.network_interface.0.access_config.0.nat_ip
}
