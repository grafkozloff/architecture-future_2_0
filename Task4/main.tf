terraform {
  required_version = ">= 1.5.0"

  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
      version = ">= 0.95.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.5.0"
    }
  }
}

provider "yandex" {
  zone      = var.zone
  cloud_id  = var.cloud_id
  folder_id = var.folder_id
  service_account_key_file = "authorized_key.json"
}

provider "random" {}

# Сетевые компоненты
resource "yandex_vpc_network" "main" {
  name = "future20-network"
}

resource "yandex_vpc_subnet" "main" {
  name           = "main-subnet"
  zone           = var.zone
  network_id     = yandex_vpc_network.main.id
  v4_cidr_blocks = ["10.10.0.0/24"]
}

resource "yandex_vpc_security_group" "external" {
  name        = "external-sg"
  network_id  = yandex_vpc_network.main.id
  description = "Security group for external access"

  egress {
    protocol       = "ANY"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol       = "TCP"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 80
  }

  ingress {
    protocol       = "TCP"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 443
  }

  ingress {
    protocol       = "TCP"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 22
  }
}

resource "yandex_vpc_security_group" "internal" {
  name        = "internal-sg"
  network_id  = yandex_vpc_network.main.id
  description = "Security group for internal services"

  ingress {
    protocol          = "ANY"
    security_group_id = yandex_vpc_security_group.external.id
  }

  ingress {
    protocol       = "TCP"
    v4_cidr_blocks = ["10.10.0.0/24"]
    from_port      = 0
    to_port        = 65535
  }
}

resource "yandex_vpc_gateway" "nat_gateway" {
  name = "nat-gateway"
  shared_egress_gateway {}
}

resource "yandex_vpc_route_table" "nat_route" {
  name       = "nat-route"
  network_id = yandex_vpc_network.main.id

  static_route {
    destination_prefix = "0.0.0.0/0"
    gateway_id         = yandex_vpc_gateway.nat_gateway.id
  }
}

# Управляемые сервисы
resource "yandex_mdb_kafka_cluster" "main" {
  name        = "future20-kafka"
  environment = "PRODUCTION"
  network_id  = yandex_vpc_network.main.id

  config {
    version          = var.kafka_version
    zones            = [var.zone]
    brokers_count    = 3
    assign_public_ip = false
    # unmanaged_topics removed - deprecated and enabled by default

    kafka {
      resources {
        resource_preset_id = "s2.medium"
        disk_type_id       = "network-ssd"
        disk_size          = 100
      }
    }
  }

  depends_on = [yandex_vpc_subnet.main]
}

resource "yandex_mdb_postgresql_cluster" "main" {
  name        = "future20-postgresql"
  environment = "PRODUCTION"
  network_id  = yandex_vpc_network.main.id

  config {
    version = var.postgresql_version
    resources {
      resource_preset_id = "s2.medium"
      disk_type_id       = "network-ssd"
      disk_size          = 100
    }
  }

  host {
    zone             = var.zone
    subnet_id        = yandex_vpc_subnet.main.id
    assign_public_ip = false
  }

  depends_on = [yandex_vpc_subnet.main]
}

resource "yandex_storage_bucket" "data_bucket" {
  bucket   = "future20-data-bucket-${random_id.bucket_suffix.hex}"
  max_size = 53687091200 # 50 GB
}

resource "random_id" "bucket_suffix" {
  byte_length = 8
}

# ВМ: Платформа данных
resource "yandex_compute_instance" "datahub" {
  name        = "datahub-server"
  platform_id = "standard-v3"
  zone        = var.zone

  resources {
    cores  = 4
    memory = 8
  }

  boot_disk {
    initialize_params {
      image_id = var.vm_image_id
      size     = 50
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.main.id
    nat       = true
    security_group_ids = [
      yandex_vpc_security_group.external.id,
      yandex_vpc_security_group.internal.id
    ]
  }

  metadata = {
    ssh-keys = "ubuntu:${file(var.ssh_public_key_path)}"
  }

  scheduling_policy {
    preemptible = true
  }
}

resource "yandex_compute_instance" "dremio" {
  name        = "dremio-server"
  platform_id = "standard-v3"
  zone        = var.zone

  resources {
    cores  = 8
    memory = 32
  }

  boot_disk {
    initialize_params {
      image_id = var.vm_image_id
      size     = 100
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.main.id
    nat       = true
    security_group_ids = [
      yandex_vpc_security_group.external.id,
      yandex_vpc_security_group.internal.id
    ]
  }

  metadata = {
    ssh-keys = "ubuntu:${file(var.ssh_public_key_path)}"
  }

  scheduling_policy {
    preemptible = true
  }
}

resource "yandex_compute_instance" "keycloak" {
  name        = "keycloak-server"
  platform_id = "standard-v3"
  zone        = var.zone
  allow_stopping_for_update = true

  resources {
    cores  = 4
    memory = 8
  }

  boot_disk {
    initialize_params {
      image_id = var.vm_image_id
      size     = 50
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.main.id
    nat       = true
    security_group_ids = [
      yandex_vpc_security_group.external.id,
      yandex_vpc_security_group.internal.id
    ]
  }

  metadata = {
    ssh-keys = "ubuntu:${file(var.ssh_public_key_path)}"
  }

  scheduling_policy {
    preemptible = true
  }
}

# ВМ: Бизнес-домены
resource "yandex_compute_instance" "medical" {
  name        = "medical-services"
  platform_id = "standard-v3"
  zone        = var.zone

  resources {
    cores  = 8
    memory = 16
  }

  boot_disk {
    initialize_params {
      image_id = var.vm_image_id
      size     = 100
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.main.id
    nat       = false
    security_group_ids = [
      yandex_vpc_security_group.internal.id
    ]
  }

  metadata = {
    ssh-keys = "ubuntu:${file(var.ssh_public_key_path)}"
  }

  scheduling_policy {
    preemptible = true
  }
}

resource "yandex_compute_instance" "fintech" {
  name        = "fintech-services"
  platform_id = "standard-v3"
  zone        = var.zone

  resources {
    cores  = 8
    memory = 16
  }

  boot_disk {
    initialize_params {
      image_id = var.vm_image_id
      size     = 100
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.main.id
    nat       = false
    security_group_ids = [
      yandex_vpc_security_group.internal.id
    ]
  }

  metadata = {
    ssh-keys = "ubuntu:${file(var.ssh_public_key_path)}"
  }

  scheduling_policy {
    preemptible = true
  }
}

resource "yandex_compute_instance" "ai" {
  name        = "ai-services"
  platform_id = "standard-v3"
  zone        = var.zone

  resources {
    cores  = 8
    memory = 32
  }

  boot_disk {
    initialize_params {
      image_id = var.vm_image_id
      size     = 200
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.main.id
    nat       = false
    security_group_ids = [
      yandex_vpc_security_group.internal.id
    ]
  }

  metadata = {
    ssh-keys = "ubuntu:${file(var.ssh_public_key_path)}"
  }

  scheduling_policy {
    preemptible = true
  }
}

# ВМ: Портал самообслуживания
resource "yandex_compute_instance" "portal" {
  name        = "self-service-portal"
  platform_id = "standard-v3"
  zone        = var.zone

  resources {
    cores  = 4
    memory = 8
  }

  boot_disk {
    initialize_params {
      image_id = var.vm_image_id
      size     = 50
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.main.id
    nat       = true
    security_group_ids = [
      yandex_vpc_security_group.external.id,
      yandex_vpc_security_group.internal.id
    ]
  }

  metadata = {
    ssh-keys = "ubuntu:${file(var.ssh_public_key_path)}"
  }

  scheduling_policy {
    preemptible = true
  }
}

resource "yandex_compute_instance" "bi" {
  name        = "powerbi-server"
  platform_id = "standard-v3"
  zone        = var.zone

  resources {
    cores  = 8
    memory = 16
  }

  boot_disk {
    initialize_params {
      image_id = var.vm_image_id
      size     = 100
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.main.id
    nat       = false
    security_group_ids = [
      yandex_vpc_security_group.internal.id
    ]
  }

  metadata = {
    ssh-keys = "ubuntu:${file(var.ssh_public_key_path)}"
  }

  scheduling_policy {
    preemptible = true
  }
}

# Load Balancer
resource "yandex_lb_network_load_balancer" "external_lb" {
  name = "external-load-balancer"

  listener {
    name = "http-listener"
    port = 80
    external_address_spec {
      ip_version = "ipv4"
    }
  }

  attached_target_group {
    target_group_id = yandex_lb_target_group.portal_target.id

    healthcheck {
      name = "http-healthcheck"
      http_options {
        port = 80
        path = "/health"
      }
    }
  }
}

resource "yandex_lb_target_group" "portal_target" {
  name      = "portal-target-group"
  region_id = "ru-central1"

  target {
    subnet_id = yandex_vpc_subnet.main.id
    address   = yandex_compute_instance.portal.network_interface[0].ip_address
  }
}

resource "yandex_lb_target_group" "services_target" {
  name      = "services-target-group"
  region_id = "ru-central1"

  target {
    subnet_id = yandex_vpc_subnet.main.id
    address   = yandex_compute_instance.medical.network_interface[0].ip_address
  }

  target {
    subnet_id = yandex_vpc_subnet.main.id
    address   = yandex_compute_instance.fintech.network_interface[0].ip_address
  }
}