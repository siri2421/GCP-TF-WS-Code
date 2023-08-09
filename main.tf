/******************************************
API
 *****************************************/

locals {
  gce_zone = "${var.region}-b"
}

resource "google_compute_network" "my_vpc" {
  project                 = "tf-ws-1"
  name                    = "my-vpc"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "my_subnet" {
  name          = "my-subnet"
  project       = google_compute_network.my_vpc.project
  ip_cidr_range = "192.168.0.0/24"
  region        = "us-central1"
  network       = google_compute_network.my_vpc.id
}
/*
resource "google_compute_instance" "my_www_vm_1" {
  #  count        = var.create_www_instance ? 1 : 0     ### loops
  project      = google_compute_network.my_vpc.project
  name         = "my-www-vm-1"
  # name         = "${var.vm_prefix}-1"   ### variables
  machine_type = "e2-micro"
  zone         = "us-central1-a"
  #zone        = "${var.region}-a" ### variables
  #zone        = local.gce_zone ### locals

  tags = ["www"]

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }
  network_interface {
    network    = google_compute_network.my_vpc.id
    subnetwork = google_compute_subnetwork.my_subnet.id
  }
  shielded_instance_config {
    enable_secure_boot = true
   
  }
  allow_stopping_for_update = true
  metadata_startup_script = "apt update && apt install -y nginx"
}
*/

### loops compute resource

resource "google_compute_instance" "my_www_vms" {
  for_each = toset(var.my_vms)
  #  count        = var.create_www_instance ? 1 : 0     ### loops
  project      = google_compute_network.my_vpc.project
  #name         = "my-www-vm-1"
  # name         = "${var.vm_prefix}-1"   ### variables
  name        = "${var.vm_prefix}-${each.value}"
  machine_type = "e2-micro"
  zone         = "us-central1-a"
  #zone        = "${var.region}-a" ### variables
  #zone        = local.gce_zone ### locals

  tags = ["www"]

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }
  network_interface {
    network    = google_compute_network.my_vpc.id
    subnetwork = google_compute_subnetwork.my_subnet.id
  }
  shielded_instance_config {
    enable_secure_boot = true
   
  }
  allow_stopping_for_update = true
  metadata_startup_script = "apt update && apt install -y nginx"
}

resource "google_compute_firewall" "allow_www" {
  name          = "allow-www"
  project       = google_compute_network.my_vpc.project
  network       = google_compute_network.my_vpc.id
  source_ranges = ["192.168.0.0/24"]
  target_tags   = ["www"]
  allow {
    protocol = "tcp"
    ports    = ["80"]
  }
}

resource "google_compute_firewall" "allow_iap" {
  name          = "allow-iap"
  project       = google_compute_network.my_vpc.project
  network       = google_compute_network.my_vpc.id
  source_ranges = ["35.235.240.0/20"]
  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
}

resource "google_compute_instance_group" "my_www_vms" {
  name        = "www-servers"
  description = "The instance group to the www servers"
  project     = google_compute_network.my_vpc.project
  instances   = [for _,vm in google_compute_instance.my_www_vms : vm.self_link]

  named_port {
    name = "http"
    port = "80"
  }

  zone = "us-central1-a"
}

module "my_ilb" {
  source        = "github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/net-lb-int"
  project_id    = google_compute_network.my_vpc.project
  region        = "us-central1"
  name          = "lb-test"
  ports         = [80]

  vpc_config    = {
    network       = google_compute_network.my_vpc.self_link
    subnetwork    = google_compute_subnetwork.my_subnet.self_link
  }

  backends = [{
    group          = google_compute_instance_group.my_www_vms.self_link
    }
  ]
}

module "my_nat" {
  source         = "github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/net-cloudnat"
  name           = "my-nat"
  project_id     = google_compute_network.my_vpc.project
  region         = "us-central1"
  router_network = google_compute_network.my_vpc.self_link
}
  
resource "google_compute_firewall" "allow_hc" {
  name          = "allow-hc"
  project       = google_compute_network.my_vpc.project
  network       = google_compute_network.my_vpc.id
  source_ranges = ["35.191.0.0/16", "130.211.0.0/22"]
  target_tags   = ["www"]


  allow {
    protocol = "tcp"
    ports     = ["80"]
  }
}


resource "google_compute_instance" "my_client" {
  name         = "my-client"
  project      = google_compute_network.my_vpc.project
  machine_type = "e2-micro"
  zone         = "us-east1-a"

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }
  network_interface {
    network    = google_compute_network.my_vpc.id
    subnetwork = google_compute_subnetwork.my_subnet.id
  }
}


resource "google_storage_bucket" "default" {
  name                        = "${google_compute_network.my_vpc.project}-bucket-tfstate"
  project                     = google_compute_network.my_vpc.project
  location                    = "US"
  uniform_bucket_level_access = true
  force_destroy               = true

  versioning {
    enabled = true
  }
}
