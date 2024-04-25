#  Курсовая работа на профессии "DevOps-инженер с нуля" -Филатов А. В.

Содержание
==========
* [Задача](#Задача)
* [Инфраструктура](#Инфраструктура)
    * [Сайт](#Сайт)
    * [Мониторинг](#Мониторинг)
    * [Логи](#Логи)
    * [Сеть](#Сеть)
    * [Резервное копирование](#Резервное-копирование)
    * [Дополнительно](#Дополнительно)
* [Выполнение работы](#Выполнение-работы)
* [Критерии сдачи](#Критерии-сдачи)
* [Как правильно задавать вопросы дипломному руководителю](#Как-правильно-задавать-вопросы-дипломному-руководителю) 

---------
## Задача
Ключевая задача — разработать отказоустойчивую инфраструктуру для сайта, включающую мониторинг, сбор логов и резервное копирование основных данных. Инфраструктура должна размещаться в [Yandex Cloud](https://cloud.yandex.com/).

## Инфраструктура
Для развёртки инфраструктуры используйте Terraform и Ansible. 

Параметры виртуальной машины (ВМ) подбирайте по потребностям сервисов, которые будут на ней работать. 

Ознакомьтесь со всеми пунктами из этой секции, не беритесь сразу выполнять задание, не дочитав до конца. Пункты взаимосвязаны и могут влиять друг на друга.

### Сайт
Создайте две ВМ в разных зонах, установите на них сервер nginx, если его там нет. ОС и содержимое ВМ должно быть идентичным, это будут наши веб-сервера.

Используйте набор статичных файлов для сайта. Можно переиспользовать сайт из домашнего задания.

Создайте [Target Group](https://cloud.yandex.com/docs/application-load-balancer/concepts/target-group), включите в неё две созданных ВМ.

Создайте [Backend Group](https://cloud.yandex.com/docs/application-load-balancer/concepts/backend-group), настройте backends на target group, ранее созданную. Настройте healthcheck на корень (/) и порт 80, протокол HTTP.

Создайте [HTTP router](https://cloud.yandex.com/docs/application-load-balancer/concepts/http-router). Путь укажите — /, backend group — созданную ранее.

Создайте [Application load balancer](https://cloud.yandex.com/en/docs/application-load-balancer/) для распределения трафика на веб-сервера, созданные ранее. Укажите HTTP router, созданный ранее, задайте listener тип auto, порт 80.

Протестируйте сайт
`curl -v <публичный IP балансера>:80` 

### Мониторинг
Создайте ВМ, разверните на ней Zabbix. На каждую ВМ установите Zabbix Agent, настройте агенты на отправление метрик в Zabbix. 

Настройте дешборды с отображением метрик, минимальный набор — по принципу USE (Utilization, Saturation, Errors) для CPU, RAM, диски, сеть, http запросов к веб-серверам. Добавьте необходимые tresholds на соответствующие графики.

### Логи
Cоздайте ВМ, разверните на ней Elasticsearch. Установите filebeat в ВМ к веб-серверам, настройте на отправку access.log, error.log nginx в Elasticsearch.

Создайте ВМ, разверните на ней Kibana, сконфигурируйте соединение с Elasticsearch.

### Сеть
Разверните один VPC. Сервера web, Elasticsearch поместите в приватные подсети. Сервера Zabbix, Kibana, application load balancer определите в публичную подсеть.

Настройте [Security Groups](https://cloud.yandex.com/docs/vpc/concepts/security-groups) соответствующих сервисов на входящий трафик только к нужным портам.

Настройте ВМ с публичным адресом, в которой будет открыт только один порт — ssh. Настройте все security groups на разрешение входящего ssh из этой security group. Эта вм будет реализовывать концепцию bastion host. Потом можно будет подключаться по ssh ко всем хостам через этот хост.

### Резервное копирование
Создайте snapshot дисков всех ВМ. Ограничьте время жизни snaphot в неделю. Сами snaphot настройте на ежедневное копирование.

### Дополнительно
Не входит в минимальные требования. 

1. Для Zabbix можно реализовать разделение компонент - frontend, server, database. Frontend отдельной ВМ поместите в публичную подсеть, назначте публичный IP. Server поместите в приватную подсеть, настройте security group на разрешение трафика между frontend и server. Для Database используйте [Yandex Managed Service for PostgreSQL](https://cloud.yandex.com/en-ru/services/managed-postgresql). Разверните кластер из двух нод с автоматическим failover.
2. Вместо конкретных ВМ, которые входят в target group, можно создать [Instance Group](https://cloud.yandex.com/en/docs/compute/concepts/instance-groups/), для которой настройте следующие правила автоматического горизонтального масштабирования: минимальное количество ВМ на зону — 1, максимальный размер группы — 3.
3. В Elasticsearch добавьте мониторинг логов самого себя, Kibana, Zabbix, через filebeat. Можно использовать logstash тоже.
4. Воспользуйтесь Yandex Certificate Manager, выпустите сертификат для сайта, если есть доменное имя. Перенастройте работу балансера на HTTPS, при этом нацелен он будет на HTTP веб-серверов.

## Выполнение работы
На этом этапе вы непосредственно выполняете работу. При этом вы можете консультироваться с руководителем по поводу вопросов, требующих уточнения.

⚠️ В случае недоступности ресурсов Elastic для скачивания рекомендуется разворачивать сервисы с помощью docker контейнеров, основанных на официальных образах.

**Важно**: Ещё можно задавать вопросы по поводу того, как реализовать ту или иную функциональность. И руководитель определяет, правильно вы её реализовали или нет. Любые вопросы, которые не освещены в этом документе, стоит уточнять у руководителя. Если его требования и указания расходятся с указанными в этом документе, то приоритетны требования и указания руководителя.

## Критерии сдачи
1. Инфраструктура отвечает минимальным требованиям, описанным в [Задаче](#Задача).
2. Предоставлен доступ ко всем ресурсам, у которых предполагается веб-страница (сайт, Kibana, Zabbix).
3. Для ресурсов, к которым предоставить доступ проблематично, предоставлены скриншоты, команды, stdout, stderr, подтверждающие работу ресурса.
4. Работа оформлена в отдельном репозитории в GitHub или в [Google Docs](https://docs.google.com/), разрешён доступ по ссылке. 
5. Код размещён в репозитории в GitHub.
6. Работа оформлена так, чтобы были понятны ваши решения и компромиссы. 
7. Если использованы дополнительные репозитории, доступ к ним открыт. 

## Как правильно задавать вопросы дипломному руководителю
Что поможет решить большинство частых проблем:
1. Попробовать найти ответ сначала самостоятельно в интернете или в материалах курса и только после этого спрашивать у дипломного руководителя. Навык поиска ответов пригодится вам в профессиональной деятельности.
2. Если вопросов больше одного, присылайте их в виде нумерованного списка. Так дипломному руководителю будет проще отвечать на каждый из них.
3. При необходимости прикрепите к вопросу скриншоты и стрелочкой покажите, где не получается. Программу для этого можно скачать [здесь](https://app.prntscr.com/ru/).

Что может стать источником проблем:
1. Вопросы вида «Ничего не работает. Не запускается. Всё сломалось». Дипломный руководитель не сможет ответить на такой вопрос без дополнительных уточнений. Цените своё время и время других.
2. Откладывание выполнения дипломной работы на последний момент.


 ### Решение
 http://158.160.34.132/zabbix   
 http://158.160.111.165:5601/app/discover#/   
 http://158.160.136.102   
Все файлы находятся в папках
установочные файлы не умещаются
[text](ansible-elasticsearch/kibana-8.13.2-amd64.deb) [text](ansible-elasticsearch/elasticsearch-8.13.2-amd64.deb) [text](ansible-elasticsearch/filebeat-8.13.2-amd64.deb)
 Terraform
 ```
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



 ```
