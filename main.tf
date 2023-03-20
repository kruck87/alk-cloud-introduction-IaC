terraform {
    required_providers {
        google = {
            source = "hashicorp/google"
            version = "4.57.0"
    }

  }
}

provider "google" {
    credentials = file("terraform-cloud-introduction-807a43c4d312.json")
    project = var.project_id
    region  = var.region
}

resource "google_compute_network" "vpc_network" {
    name = var.network
    auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "subnet" {
    name = var.subnet
    region = var.region
    network = google_compute_network.vpc_network.id
    ip_cidr_range = "10.1.0.0/24"
    private_ip_google_access = true
    
}


resource "google_storage_bucket" "startup_script_bucket" {
    name = "lk-alk-terraform-project-startup-bucket"
    project = var.project_id
    storage_class = "STANDARD"
    location = "EU"
}

resource "google_storage_bucket_access_control" "public_rule_for_startup_script_bucket" {
  bucket = google_storage_bucket.startup_script_bucket.name
  role   = "READER"
  entity = "allUsers"
}

resource "google_storage_object_access_control" "public_rule" {
  object = google_storage_bucket_object.index_file.output_name
  bucket = google_storage_bucket.startup_script_bucket.name
  role   = "READER"
  entity = "allUsers"
}

resource "google_storage_bucket" "media_bucket" {
    name = "lk-alk-terraform-project-media-bucket"
    project = var.project_id
    storage_class = "STANDARD"
    location = "EU"
}

resource "google_compute_backend_bucket" "media_backend" {
  name        = "lk-alk-terraform-project-media-bucket"
  bucket_name = google_storage_bucket.media_bucket.name
  enable_cdn  = true
}

resource "google_storage_bucket_access_control" "public_rule_for_media_bucket" {
  bucket = google_storage_bucket.media_bucket.name
  role   = "READER"
  entity = "allUsers"
}

resource "google_compute_firewall" "allow-health_check" {
  name          = "fw-allow-health-check"
  direction     = "INGRESS"
  network       = google_compute_network.vpc_network.id
  priority      = 1000
  source_ranges = ["130.211.0.0/22", "35.191.0.0/16"]
  target_tags   = ["allow-health-check"]
  allow {
    ports    = ["80"]
    protocol = "tcp"
  }
}

resource "google_compute_firewall" "allow-http" {
  name          = "fw-allow-http"
  direction     = "INGRESS"
  network       = google_compute_network.vpc_network.id
  priority      = 1000
  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["http", "https", "http-server", "https-server"]
  allow {
    ports    = ["80"]
    protocol = "tcp"
  }
}

resource "google_compute_firewall" "allow-ssh" {
  name          = "fw-allow-ssh"
  direction     = "INGRESS"
  network       = google_compute_network.vpc_network.id
  priority      = 1000
  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["ssh"]
  allow {
    ports    = ["22"]
    protocol = "tcp"
  }
}



resource "google_storage_bucket_object" "index_file" {
    name         = "index.html"
    source       = "./Files/index.html"
    content_type = "text/html"
    bucket       = google_storage_bucket.startup_script_bucket.id
}


resource "google_storage_bucket_object" "file1" {
    name         = "src/1.jpeg"
    source       = "./Files/1.jpeg"
    content_type = "image/jpeg"
    bucket       = google_storage_bucket.media_bucket.id
}

resource "google_storage_object_access_control" "public_rule_media1" {
  object = google_storage_bucket_object.file1.output_name
  bucket = google_storage_bucket.media_bucket.name
  role   = "READER"
  entity = "allUsers"
}

resource "google_storage_bucket_object" "file2" {
    name         = "src/2.jpg"
    source       = "./Files/2.jpg"
    content_type = "image/jpeg"
    bucket       = google_storage_bucket.media_bucket.id
}

resource "google_storage_object_access_control" "public_rule_media2" {
  object = google_storage_bucket_object.file2.output_name
  bucket = google_storage_bucket.media_bucket.name
  role   = "READER"
  entity = "allUsers"
}

resource "google_storage_bucket_object" "file3" {
    name         = "src/3.jpeg"
    source       = "./Files/3.jpeg"
    content_type = "image/jpeg"
    bucket       = google_storage_bucket.media_bucket.id
}

resource "google_storage_object_access_control" "public_rule_media3" {
  object = google_storage_bucket_object.file3.output_name
  bucket = google_storage_bucket.media_bucket.name
  role   = "READER"
  entity = "allUsers"
}

resource "google_storage_bucket_object" "file4" {
    name         = "src/4.jpeg"
    source       = "./Files/4.jpeg"
    content_type = "image/jpeg"
    bucket       = google_storage_bucket.media_bucket.id
}

resource "google_storage_object_access_control" "public_rule_media4" {
  object = google_storage_bucket_object.file4.output_name
  bucket = google_storage_bucket.media_bucket.name
  role   = "READER"
  entity = "allUsers"
}

resource "google_compute_instance_template" "apache_server_template" {
    description = "Template instancji backendowych"

    tags = [ "http", "https", "healthcheck", "ssh", "allow-health-check", "http-server" ,"https-server"]
    name_prefix = "http-backend-"
    
    machine_type = "n1-standard-1"
      
    disk {
        source_image      = "debian-cloud/debian-11-bullseye-v20230306"
        auto_delete       = true
        boot              = true
    }

    network_interface {
        network = var.network
        subnetwork = var.subnet
    }


    metadata_startup_script = <<SCRIPT
        #! /bin/bash
        sudo apt update
        sudo apt -y install apache2
        valhost=$(hostname)
        cd /var/www/html
        rm index.html
        gsutil cp gs://${google_storage_bucket.startup_script_bucket.name}/index.html .
        touch /var/www/html/which.html
        touch /var/www/html/hc.html
        echo '<html><body><p>hc</p></body>' > /var/www/html/hc.html
        echo '<html><body><p>Plik serwowany z '  > /var/www/html/which.html
        echo $valhost >> /var/www/html/which.html
        echo '</p></body></html>' >>  /var/www/html/which.html
    SCRIPT

}



resource "google_compute_health_check" "autohealing" {
    name               = "http-basic-check"
    check_interval_sec = 15
    healthy_threshold  = 2
    http_health_check {
        port               = 80
        request_path       = "/hc.html"
    }
    timeout_sec         = 5
    unhealthy_threshold = 10

}


resource "google_compute_autoscaler" "autoscaler" {
  name   = "basic-autoscaler"
  zone   = var.zone
  target = google_compute_instance_group_manager.apache-backend.id

  autoscaling_policy {
    max_replicas    = 5
    min_replicas    = 2
    cooldown_period = 120

    cpu_utilization {
      target = 0.8
    }
  }
}


resource "google_compute_instance_group_manager" "apache-backend" {
  name = "apache-backend-group"
  base_instance_name = "apache"
  zone               = var.zone

  version {
    instance_template  = google_compute_instance_template.apache_server_template.self_link
  }

  target_size  = 3

  named_port {
    name = "http"
    port = 80
  }

  auto_healing_policies {
    health_check      = google_compute_health_check.autohealing.id
    initial_delay_sec = 300
  }
}



resource "google_compute_health_check" "lb_autohealing" {
    name               = "lb-basic-check"
    check_interval_sec = 15
    healthy_threshold  = 2
    http_health_check {
        port               = 80
        request_path       = "/hc.html"
    }
    timeout_sec         = 5
    unhealthy_threshold = 10
}

resource "google_compute_global_address" "external_ip" {
    name         = "external-ip-for-lb"
}

resource "google_compute_router" "router" {
  name    = "my-router"
  region  = google_compute_subnetwork.subnet.region
  network = google_compute_network.vpc_network.name

  bgp {
    asn = 64514
  }
}

resource "google_compute_router_nat" "nat" {
  name                               = "my-router-nat"
  router                             = google_compute_router.router.name
  region                             = google_compute_router.router.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  log_config {
    enable = false
    filter = "ERRORS_ONLY"
  }
}

resource "google_compute_backend_service" "lb_web_backend" {
  name                            = "web-backend-service"
  connection_draining_timeout_sec = 0
  health_checks                   = [google_compute_health_check.lb_autohealing.id]
  load_balancing_scheme           = "EXTERNAL_MANAGED"
  port_name                       = "http"
  protocol                        = "HTTP"
  session_affinity                = "NONE"
  timeout_sec                     = 30
  backend {
    group           = google_compute_instance_group_manager.apache-backend.instance_group
    balancing_mode  = "UTILIZATION"
    capacity_scaler = 1.0
  }
}


resource "google_compute_url_map" "default" {
  name        = "urlmap"
  description = "a description"

  default_service = google_compute_backend_service.lb_web_backend.self_link

  host_rule {
    hosts        = ["*"]
    path_matcher = "mysite"
  }

  path_matcher {
    name            = "mysite"
    default_service = google_compute_backend_service.lb_web_backend.self_link

    path_rule {
      paths   = ["/src"]
      service = google_compute_backend_bucket.media_backend.id 
    }

    path_rule {
      paths   = ["/src/*"]
      service = google_compute_backend_bucket.media_backend.id
    }

     path_rule {
      paths   = ["/"]
      service = google_compute_backend_service.lb_web_backend.self_link
    }


     path_rule {
      paths   = ["/*"]
      service = google_compute_backend_service.lb_web_backend.self_link
    }

  }
}


resource "google_compute_target_http_proxy" "default" {
  name    = "http-lb-proxy"
  url_map = google_compute_url_map.default.id
}

resource "google_compute_global_forwarding_rule" "default" {
  name                  = "http-content-rule"
  ip_protocol           = "TCP"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  port_range            = "80-80"
  target                = google_compute_target_http_proxy.default.id
  ip_address            = google_compute_global_address.external_ip.id
}

