data "google_compute_default_service_account" "default" {
  project = var.gcp-project-id
}

# Windows server instance
resource "google_compute_instance" "windows_instance" {
  project          = var.gcp-project-id
  zone             = var.zone
  name             = "windows-server-${var.environment}"
  machine_type     = "custom-8-8192" # 8-Core CPU with 8 GB of memory

  boot_disk {
    device_name = "windows-server-disk-${var.environment}"
    initialize_params {
      image = "windows-server-2012-r2-dc-v20220210"
    }
  }
  network_interface {
    network       = google_compute_network.vpc.self_link   
    access_config {
      // Ephemeral public IP
    }
  }
  service_account {
    email  = data.google_compute_default_service_account.default.email
    scopes = [
              "https://www.googleapis.com/auth/devstorage.read_only",
              "https://www.googleapis.com/auth/logging.write",
              "https://www.googleapis.com/auth/monitoring.write",
              "https://www.googleapis.com/auth/pubsub",
              "https://www.googleapis.com/auth/service.management.readonly",
              "https://www.googleapis.com/auth/servicecontrol",
              "https://www.googleapis.com/auth/trace.append",
            ] 
  }
  shielded_instance_config {
    enable_secure_boot = false
    enable_vtpm        = true
    enable_integrity_monitoring = true
  }

  resource_policies = [
    google_compute_resource_policy.daily.self_link,
  ]
}

# Schedule policy for Windows server instance
resource "google_compute_resource_policy" "daily" {
  name   = "windows-server-timer"
  region = var.region
  description = "start 7:30 stop 8:30"
  
  instance_schedule_policy {
    vm_start_schedule {
      schedule = "30 7 * * *"
    }
    vm_stop_schedule{
      schedule  = "30 8 * * *"
    }
    time_zone   = "Europe/Helsinki"
  }
}

# Compute Instance Admin role for Compute Engine Service Agent 
# for scheduled instance to start and stop
resource "google_project_iam_binding" "compute_instance_admin" {
  project = var.gcp-project-id
  role = "roles/compute.instanceAdmin.v1"
  members = [
    "serviceAccount:service-${var.gcp_project_number}@compute-system.iam.gserviceaccount.com",
  ]
}

resource "google_compute_network" "vpc" {
  name                    = "windows-server-vpc-${var.environment}"
  auto_create_subnetworks = "false"
  routing_mode            = "REGIONAL"
}

resource "google_compute_subnetwork" "vpc_subnet" {
  name          = "windows-server-subnetwork-${var.environment}"
  ip_cidr_range = "xxx"
  network       = google_compute_network.vpc.name
  region        = var.region
  private_ip_google_access = true
}

resource "google_compute_route" "vpc_route" {
  name                 = "windows-server-vpc-route-${var.environment}"  
  dest_range           = "xxx"
  network              = google_compute_network.vpc.self_link
  next_hop_gateway     = "default-internet-gateway"  
}

# Allow ssh
resource "google_compute_firewall" "allow-ssh" {
  name    = "windows-server-allow-ssh-${var.environment}"
  network = google_compute_network.vpc.name
  description = "Allows TCP connections from any source to any instance on the network using port 22."

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["0.0.0.0/0"]
  priority      = 65534
}

# allow rdp
resource "google_compute_firewall" "allow-rdp" {
  name    = "windows-server-allow-rdp-${var.environment}"
  network = google_compute_network.vpc.name
  description = "Allows RDP connections from any source to any instance on the network using port 3389."

  allow {
    protocol = "tcp"
    ports    = ["3389"]
  }

  source_ranges = ["0.0.0.0/0"]
  priority      = 65534
}

# Allow 1688
resource "google_compute_firewall" "allow-1688" {
  name    = "windows-server-allow-1688-${var.environment}"
  network = google_compute_network.vpc.name
  allow {
    protocol = "tcp"
    ports    = ["1688"]
  }
  destination_ranges = ["xxx"]
  direction = "EGRESS"
  priority = 0
}