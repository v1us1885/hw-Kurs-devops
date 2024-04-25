# Объявление переменных для конфиденциальных параметров

variable "folder_id" {
  description = "ID of the folder where resources will be created"
  type = string
}

variable "vm_user" {
  type = string
}

variable "ssh_key_path1" {
  type      = string
  sensitive = true
}

variable "image_id" {
  type = string
}

# Создание VPC
resource "yandex_vpc_network" "main_network" {
  name = "main_network"
}

# Создание Gateway
resource "yandex_vpc_gateway" "nat_gateway" {
  name = "gateway"
  shared_egress_gateway {}
}

# Создание route-gateway
resource "yandex_vpc_route_table" "rt" {
  name       = "route-table"
  network_id = yandex_vpc_network.main_network.id
  static_route {
    destination_prefix = "0.0.0.0/0"
    gateway_id         = yandex_vpc_gateway.nat_gateway.id
  }
}

# Создание private_subnet-1
resource "yandex_vpc_subnet" "private_subnet_1" {
  name           = "private_subnet_1"
  zone           = "ru-central1-a" 
  network_id     = yandex_vpc_network.main_network.id
  v4_cidr_blocks = ["10.0.1.0/24"]
  route_table_id = yandex_vpc_route_table.rt.id
}

# Создание private_subnet-2
resource "yandex_vpc_subnet" "private_subnet_2" {
  name           = "private_subnet_2"
  zone           = "ru-central1-b" 
  network_id     = yandex_vpc_network.main_network.id
  v4_cidr_blocks = ["10.0.2.0/24"]
  route_table_id = yandex_vpc_route_table.rt.id
}

# Создание public_subnet
resource "yandex_vpc_subnet" "public_subnet" {
  name           = "public_subnet"
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.main_network.id
  v4_cidr_blocks = ["10.0.3.0/24"]
}

# Создание SecGroup Bastion SSH access
resource "yandex_vpc_security_group" "ssh_access_bastion" {
  name        = "ssh_access_bastion"
  network_id  = yandex_vpc_network.main_network.id
  
  egress {
    protocol       = "TCP"
    description    = "SSH"
    v4_cidr_blocks = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
    port           = 22
  
  }
  ingress {
    protocol       = "TCP"
    description    = "Bastion SSH access"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 22
  }

  #Zabbix 
  ingress {
    protocol          = "TCP"
    description       = "zabbix"
    v4_cidr_blocks = ["10.0.3.0/24"]
    port              = 10050
  }
  egress {
    protocol          = "TCP"
    description       = "zabbix"
    v4_cidr_blocks = ["10.0.3.0/24"]
    port              = 10051
  }  
  egress {
    protocol          = "TCP"
    description       = "zabbix"
    v4_cidr_blocks = ["10.0.3.0/24"]
    port              = 10052
  }

  egress {
    protocol          = "TCP"
    description       = "apt"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port              = 80
  }
  egress {
    protocol          = "TCP"
    description       = "apt"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port              = 443
  }
}

# Создание SecGroup Balancer 
resource "yandex_vpc_security_group" "balancer_sg" {
  name        = "balancer_sg"
  network_id  = yandex_vpc_network.main_network.id
   
  ingress {
    protocol          = "TCP"
    description       = "HTTP"
    v4_cidr_blocks    = ["0.0.0.0/0"]
    port              = 80
  }  
  ingress {
    protocol          = "TCP"
    description       = "healthchecks"
    predefined_target = "loadbalancer_healthchecks"
    port              = 30080
  }
  egress {
    protocol       = "ANY"
    description    = "ANY"
    v4_cidr_blocks = ["0.0.0.0/0"]
    from_port      = 0
    to_port        = 65535
  }
}

# Создание SecGroup Zabbix
resource "yandex_vpc_security_group" "zabbix_sg" {
  name        = "zabbix_sg"
  network_id  = yandex_vpc_network.main_network.id
  
  #Bastion SSH access   
  ingress {
    protocol          = "TCP"
    description       = "Bastion SSH access"
    security_group_id = yandex_vpc_security_group.ssh_access_bastion.id
    port              = 22
  }  
  
  #zabbix web
  ingress {
    protocol          = "TCP"
    description       = "zabbix web"
    v4_cidr_blocks    = ["0.0.0.0/0"]
    port              = 80
  } 
  
  #zabbix agent
  ingress {
    protocol          = "TCP"
    description       = "zabbix agent"
    v4_cidr_blocks    = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
    port              = 10052
  }
  #zabbix agent
  ingress {
    protocol          = "TCP"
    description       = "zabbix agent"
    v4_cidr_blocks    = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
    port              = 10051
  }

  #zabbix agent
  ingress {
    protocol          = "UDP"
    description       = "zabbix agent"
    v4_cidr_blocks    = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
    port              = 162
  }

  #zabbix agent
  egress {
    protocol       = "ANY"
    description    = "ANY"
    v4_cidr_blocks = ["0.0.0.0/0"]
    from_port      = 0
    to_port        = 65535
  }
}


# Создание SecGroup web server private 
resource "yandex_vpc_security_group" "private_wb_sg" {
  name        = "private_wb_sg"
  network_id  = yandex_vpc_network.main_network.id
  
  #Bastion SSH access   
  ingress {
    protocol          = "TCP"
    description       = "Bastion SSH access"
    security_group_id = yandex_vpc_security_group.ssh_access_bastion.id
    port              = 22
  }

  #Balancer
  ingress {
    protocol          = "TCP"
    description       = "HTTP-Balancer"
    security_group_id = yandex_vpc_security_group.balancer_sg.id
    port              = 80
  }

  #Zabbix 
  ingress {
    protocol          = "TCP"
    description       = "zabbix"
    v4_cidr_blocks = ["10.0.3.0/24"]
    port              = 10050
  }
  egress {
    protocol       = "ANY"
    description    = "ANY"
    v4_cidr_blocks = ["0.0.0.0/0"]
    from_port      = 0
    to_port        = 65535
  }
}

# Создание SecGroup ELK
resource "yandex_vpc_security_group" "elk_sg" {
  name        = "elk_sg"
  network_id  = yandex_vpc_network.main_network.id

  ingress {
    protocol          = "TCP"
    description       = "SSH"
    security_group_id = yandex_vpc_security_group.ssh_access_bastion.id
    port              = 22
  }

  #Zabbix 
  ingress {
    protocol          = "TCP"
    description       = "zabbix"
    v4_cidr_blocks = ["10.0.3.0/24"]
    port              = 10050
  }
  
  #ELK
  ingress {
    protocol          = "TCP"
    description       = "elk"
    v4_cidr_blocks = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
    port              = 9200
  }

  egress {
    protocol       = "ANY"
    description    = "ANY"
    v4_cidr_blocks = ["0.0.0.0/0"]
    from_port      = 0
    to_port        = 65535
  }
}

# Создание SecGroup Kibana
resource "yandex_vpc_security_group" "kibana_sg" {
  name        = "kibana_sg"
  network_id  = yandex_vpc_network.main_network.id

  ingress {
    protocol          = "TCP"
    description       = "SSH"
    security_group_id = yandex_vpc_security_group.ssh_access_bastion.id
    port              = 22
  }

  #Zabbix 
  ingress {
    protocol          = "TCP"
    description       = "zabbix"
    v4_cidr_blocks = ["10.0.3.0/24"]
    port              = 10050
  }
  
  #ELK
  ingress {
    protocol          = "TCP"
    description       = "elk"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port              = 5601
  }

  ingress {
    protocol          = "TCP"
    description       = "elk"
    v4_cidr_blocks = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
    port              = 9200
  }

  ingress {
    protocol          = "TCP"
    description       = "elk"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port              = 80
  }

  egress {
    protocol       = "ANY"
    description    = "ANY"
    v4_cidr_blocks = ["0.0.0.0/0"]
    from_port      = 0
    to_port        = 65535
  }
}

# Создание Bastion Host
resource "yandex_compute_instance" "bastion_host" {
  name                       = "bastion-host"
  allow_stopping_for_update = true
  zone                       = "ru-central1-a"
  platform_id               = "standard-v3"
  resources {
    core_fraction = 50
    cores         = 2
    memory        = 2
  }
  boot_disk {
    initialize_params {
      image_id = var.image_id
      size     = 20
    }
  }
  metadata = {
    user-data = "#cloud-config\nusers:\n  - name: ${var.vm_user}\n    groups: sudo\n    shell: /bin/bash\n    sudo: ['ALL=(ALL) NOPASSWD:ALL']\n    ssh-authorized-keys:\n      - ${file("${var.ssh_key_path1}")}"
  }
  scheduling_policy {
    preemptible = true
  }
  network_interface {
    subnet_id = yandex_vpc_subnet.public_subnet.id
    nat       = true
    security_group_ids = [yandex_vpc_security_group.ssh_access_bastion.id]
  }

}

# Создание web-server-1
resource "yandex_compute_instance" "web_server_1" {
  name                       = "web-server-1"
  allow_stopping_for_update = true
  zone                       = "ru-central1-a"
  platform_id               = "standard-v3"
  resources {
    core_fraction = 50
    cores         = 2
    memory        = 2
  }
  boot_disk {
    initialize_params {
      image_id = var.image_id
      size     = 20
    }
  }
  metadata = {
    user-data = "#cloud-config\nusers:\n  - name: ${var.vm_user}\n    groups: sudo\n    shell: /bin/bash\n    sudo: ['ALL=(ALL) NOPASSWD:ALL']\n    ssh-authorized-keys:\n      - ${file("${var.ssh_key_path1}")}"
  }
  scheduling_policy {
    preemptible = true
  }
  network_interface {
    subnet_id          = yandex_vpc_subnet.private_subnet_1.id
    nat                = false
    security_group_ids = [yandex_vpc_security_group.private_wb_sg.id]
  }
}

# Создание web-server-2
resource "yandex_compute_instance" "web_server_2" {
  name                       = "web-server-2"
  allow_stopping_for_update = true
  zone                       = "ru-central1-b"
  platform_id               = "standard-v3"
  resources {
    core_fraction = 50
    cores         = 2
    memory        = 2
  }
  boot_disk {
    initialize_params {
      image_id = var.image_id
      size     = 20
    }
  }
  metadata = {
    user-data = "#cloud-config\nusers:\n  - name: ${var.vm_user}\n    groups: sudo\n    shell: /bin/bash\n    sudo: ['ALL=(ALL) NOPASSWD:ALL']\n    ssh-authorized-keys:\n      - ${file("${var.ssh_key_path1}")}"
  }
  scheduling_policy {
    preemptible = true
  }
  network_interface {
    subnet_id          = yandex_vpc_subnet.private_subnet_2.id
    nat                = false
    security_group_ids = [yandex_vpc_security_group.private_wb_sg.id]
  }
}

# Создание Zabbix
resource "yandex_compute_instance" "zabbix" {
  name                       = "zabbix"
  allow_stopping_for_update = true
  zone                       = "ru-central1-a"
  platform_id               = "standard-v3"
  resources {
    core_fraction = 50
    cores         = 2
    memory        = 8
  }
  boot_disk {
    initialize_params {
      image_id = var.image_id
      size     = 20
    }
  }
  metadata = {
    user-data = "#cloud-config\nusers:\n  - name: ${var.vm_user}\n    groups: sudo\n    shell: /bin/bash\n    sudo: ['ALL=(ALL) NOPASSWD:ALL']\n    ssh-authorized-keys:\n      - ${file("${var.ssh_key_path1}")}"
  }

  scheduling_policy {
    preemptible = true
  }
  network_interface {
    subnet_id = yandex_vpc_subnet.public_subnet.id
    nat       = true
    security_group_ids = [yandex_vpc_security_group.zabbix_sg.id]
  }
}

# Создание Elasticserch
resource "yandex_compute_instance" "elasticserch" {
  name                       = "elasticserch"
  allow_stopping_for_update = true
  zone                       = "ru-central1-a"
  platform_id               = "standard-v3"
  resources {
    core_fraction = 50
    cores         = 4
    memory        = 16
  }
  boot_disk {
    initialize_params {
      image_id = var.image_id
      size     = 100
    }
  }
  metadata = {
    user-data = "#cloud-config\nusers:\n  - name: ${var.vm_user}\n    groups: sudo\n    shell: /bin/bash\n    sudo: ['ALL=(ALL) NOPASSWD:ALL']\n    ssh-authorized-keys:\n      - ${file("${var.ssh_key_path1}")}"
  }
  scheduling_policy {
    preemptible = true
  }
  network_interface {
    subnet_id          = yandex_vpc_subnet.private_subnet_1.id
    nat                = false
    security_group_ids = [yandex_vpc_security_group.elk_sg.id]
  }
}

# Создание  Kibana
resource "yandex_compute_instance" "kibana" {
  name                       = "kibana"
  allow_stopping_for_update = true
  zone                       = "ru-central1-a"
  platform_id               = "standard-v3"
  resources {
    core_fraction = 50
    cores         = 2
    memory        = 2
  }
  boot_disk {
    initialize_params {
      image_id = var.image_id
      size     = 20
    }
  }
  metadata = {
    user-data = "#cloud-config\nusers:\n  - name: ${var.vm_user}\n    groups: sudo\n    shell: /bin/bash\n    sudo: ['ALL=(ALL) NOPASSWD:ALL']\n    ssh-authorized-keys:\n      - ${file("${var.ssh_key_path1}")}"
  }
  scheduling_policy {
    preemptible = true
  }
  network_interface {
    subnet_id = yandex_vpc_subnet.public_subnet.id
    nat       = true
    security_group_ids = [yandex_vpc_security_group.kibana_sg.id]
  }
}

# Создание Target Group
resource "yandex_alb_target_group" "web_target_group" {
  name      = "web-target-group"

  target {
    subnet_id    = yandex_vpc_subnet.private_subnet_1.id
    ip_address  = yandex_compute_instance.web_server_1.network_interface.0.ip_address
  }

  target {
    subnet_id    = yandex_vpc_subnet.private_subnet_2.id
    ip_address  = yandex_compute_instance.web_server_2.network_interface.0.ip_address
  }
}

# Создание Backend Group
resource "yandex_alb_backend_group" "web_backend_group" {
  name = "web-backend-group"

  http_backend {
    name              = "http-backend"
    port              = 80
    target_group_ids = [yandex_alb_target_group.web_target_group.id]  
    
    healthcheck {
      timeout          = "5s"
      interval         = "10s"
      healthcheck_port = 80

      http_healthcheck {
        path = "/"
      }
    }
  }
}

# Создание HTTP router
resource "yandex_alb_http_router" "http_router" {
  name = "http-router"
}

# Создание Virtual host
resource "yandex_alb_virtual_host" "virtual_host" {
  name            = "virtual-host"
  http_router_id  = yandex_alb_http_router.http_router.id

  route {
    name = "route"

    http_route {
      http_route_action {
        backend_group_id = yandex_alb_backend_group.web_backend_group.id
        timeout          = "3s"
      }
    }
  }
}

# Создание Application Load Balancer
resource "yandex_alb_load_balancer" "web_lb" {
  name                = "web-lb"
  network_id          = yandex_vpc_network.main_network.id
  security_group_ids  = [yandex_vpc_security_group.balancer_sg.id]

  allocation_policy {
    location {
      zone_id   = "ru-central1-a"
      subnet_id = yandex_vpc_subnet.private_subnet_1.id
    }
    location {
      zone_id   = "ru-central1-b"
      subnet_id = yandex_vpc_subnet.private_subnet_2.id
    }
  }

  listener {
    name = "http-listener"

    endpoint {
      address {
        external_ipv4_address {}
      }
      ports = [80]
    }

    http {
      handler {
        http_router_id = yandex_alb_http_router.http_router.id
      }
    }
  }
}

# Output internal IP

output "web_server_1_ip" {
  value = yandex_compute_instance.web_server_1.network_interface.0.ip_address
}

output "web_server_2_ip" {
  value = yandex_compute_instance.web_server_2.network_interface.0.ip_address
}

output "elasticsearch_ip" {
  value = yandex_compute_instance.elasticserch.network_interface.0.ip_address
}

output "zabbix_ip" {
  value = yandex_compute_instance.zabbix.network_interface.0.ip_address
}

output "kibana_ip" {
  value = yandex_compute_instance.kibana.network_interface.0.ip_address
}

output "bastion_host" {
  value = yandex_compute_instance.bastion_host.network_interface.0.ip_address
}

# Output externel IP

output "bastion_host_ip_external" {
  value = yandex_compute_instance.bastion_host.network_interface.0.nat_ip_address
}

output "zabbix_ip_external" {
  value = yandex_compute_instance.zabbix.network_interface.0.nat_ip_address
}

output "kibana_ip_external" {
  value = yandex_compute_instance.kibana.network_interface.0.nat_ip_address
}

output "web_lb_external_ip" {
  value = yandex_alb_load_balancer.web_lb.listener[0].endpoint[0].address[0].external_ipv4_address[0].address
}


