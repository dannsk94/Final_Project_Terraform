# Final Project: Infrastructure as Code with Terraform

## 📋 Описание

Автоматизированное развертывание отказоустойчивой веб-инфраструктуры в VK Cloud с использованием Terraform модулей, Packer и GitHub Actions CI/CD.

## 🏗️ Архитектура

| Компонент | Описание |
|-----------|----------|
| **VPC** | Публичная и приватная подсети |
| **Бастион** | SSH доступ, внешний IP |
| **Веб-серверы** | nginx + PHP-FPM (из Packer образа) |
| **Балансировщик** | L7 HTTP, Round Robin |
| **PostgreSQL 15** | Управляемая БД, приватная подсеть |

## 📁 Структура проекта

```text
├── modules/ # Terraform модули
│ ├── network/ # VPC, подсети, Security Groups
│ ├── compute/ # Бастион, веб-серверы
│ ├── database/ # PostgreSQL
│ └── loadbalancer/ # Балансировщик
├── envs/
│ ├── dev/ # Dev окружение (1 веб-сервер)
│ │ ├── main.tf
│ │ ├── variables.tf
│ │ └── dev.tfvars
│ └── prod/ # Prod окружение (2 веб-сервера)
│ ├── main.tf
│ ├── variables.tf
│ └── prod.tfvars
├── packer/ # Packer образ
│ ├── lab-packer-config.pkr.hcl
│ └── variables.pkrvars.hcl.example
├── .github/workflows/ # CI/CD
│ ├── packer.yml
│ ├── terraform-dev.yml
│ └── terraform-prod.yml
└── README.md
```

## 🚀 CI/CD Пайплайн

| Workflow | Триггер | Описание |
|----------|---------|----------|
| **Packer Build** | Ручной | Сборка образа, авто-push ID |
| **Terraform Dev** | Push / Ручной | Validate → Plan → Apply / Destroy |
| **Terraform Prod** | Push / Ручной | Validate → Plan → Apply / Destroy |

## 🔐 GitHub Secrets

Для работы CI/CD пайплайнов необходимы следующие секреты репозитория:

| Secret | Назначение |
|--------|------------|
| `CLOUDS_YAML` | Конфигурация `clouds.yaml` для аутентификации Packer и Terraform в VK Cloud. Содержит те же параметры, что и `openrc.sh`, но в формате YAML |
| `AWS_ACCESS_KEY_ID` | Ключ доступа к S3 (хранение state) |
| `AWS_SECRET_ACCESS_KEY` | Секретный ключ доступа к S3 |
| `SSH_PUBLIC_KEY` | Публичный SSH-ключ для доступа к ВМ |
| `PACKER_GITHUB_API_TOKEN` | GitHub токен для скачивания Packer плагинов |
| `MY_IP` | Ваш публичный IP для Security Groups (`0.0.0.0/0` для открытого доступа) |
| `OS_AUTH_URL` | URL аутентификации VK Cloud |
| `OS_USERNAME` | Имя пользователя VK Cloud |
| `OS_PASSWORD` | Пароль пользователя VK Cloud |
| `OS_PROJECT_ID` | ID проекта VK Cloud |
| `OS_REGION_NAME` | Регион (RegionOne) |
| `OS_USER_DOMAIN_NAME` | Домен пользователя (users) |
| `OS_INTERFACE` | Интерфейс (public) |
| `OS_IDENTITY_API_VERSION` | Версия API (3) |

## 🔧 Технологии

- **Terraform** — Infrastructure as Code (модули, S3 backend)
- **Packer** — сборка образов (Ubuntu + nginx + PHP)
- **GitHub Actions** — CI/CD пайплайн
- **VK Cloud** — облачный провайдер
- **OpenRC** — авторизация в VK Cloud

## 🛠️ Порядок развертывания

### 1. Настроить переменные окружения

Скопировать `.example` файлы в `*.tfvars`, указав свои параметры (ключи доступа, и т.д.).

### 2. Выбор сценария работы с образами ВМ

#### Вариант А: Использование стандартного Ubuntu (без Packer)

Ничего дополнительно делать не требуется. При создании ВМ через Terraform будет использован стандартный образ Ubuntu 22.04, а nginx установится через `user_data`:

```hcl
user_data = <<-EOF
  #!/bin/bash
  apt-get update && apt-get install -y nginx
  systemctl enable nginx && systemctl start nginx
  echo "<h1>Web Server ${count.index + 1}</h1>" > /var/www/html/index.html
EOF
```

##### Вариант Б: Сборка кастомизированного Packer образа
**Локальная сборка:**

```bash
cd packer
cp variables.pkrvars.hcl.example variables.pkrvars.hcl
# Отредактировать variables.pkrvars.hcl, указав свои параметры:
# network_id = ["<network_id>"] - ID сети для Packer
# security_groups = ["packer"] - Security Group для Packer
# flavor = "STD2-2-4" - 2 vCPU, 4 GB RAM
# source_image = "<image_id>" - Ubuntu 22.04
packer init lab-packer-config.pkr.hcl
packer build lab-packer-config.pkr.hcl
```

> **Примечание:** для успешной сборки Packer необходима отдельная приватная сеть с роутером.

После успешной сборки Packer создаст файл `modules/compute/image.auto.tfvars` с ID нового образа.

Для использования собранного образа в Terraform необходимо скопировать этот файл в директории окружений:

```bash
cp modules/compute/image.auto.tfvars envs/dev/
cp modules/compute/image.auto.tfvars envs/prod/
```

**Сборка через CI/CD (GitHub Actions):**

1. Запустить workflow **Packer Build** вручную из интерфейса GitHub Actions
2. Дождаться завершения сборки (около 5-7 минут)
3. Выполнить `git pull`, чтобы получить обновлённый файл `modules/compute/image.auto.tfvars` с ID нового образа
4. **Отключить защиту:** закомментировать `lifecycle { ignore_changes = [image_id] }` в `modules/compute/main.tf`
5. Файл автоматически скопируется в `envs/dev/` и `envs/prod/` через шаг `Copy image ID to envs` в CI/CD пайплайне
6. **Применить Terraform:** `terraform apply` — ВМ пересоздадутся с новым образом
7. **Вернуть защиту:** раскомментировать `lifecycle` обратно
8. При последующих `terraform apply` ВМ не будут пересоздаваться

### 3. Развертывание окружения Dev

```bash
cd envs/dev
terraform init
terraform plan -var-file=dev.tfvars
terraform apply -var-file=dev.tfvars
```

### 4. Развертывание окружения Prod
```bash
cd envs/prod
terraform init
terraform plan -var-file=prod.tfvars
terraform apply -var-file=prod.tfvars
```

### 5. Автоматический CI/CD для Terraform

**Terraform Plan/Apply:**

- При пуше в `main` пайплайны `terraform-dev.yml` и `terraform-prod.yml` автоматически запускают `validate` и `plan`
- Для запуска `apply` необходимо внести изменения в любой файл в `envs/dev/` или `envs/prod/` (например, добавить комментарий в `main.tf`) и запушить в `main` — это запустит пайплайн с `validate` и `plan`, после чего `apply` требует ручного подтверждения через `environment: dev/prod` в GitHub Actions (кнопка **Review** в интерфейсе GitHub)
- После подтверждения применяются изменения инфраструктуры

**Terraform Destroy:**

- Выполняется вручную через запуск workflow **Destroy Dev** или **Destroy Prod** из интерфейса GitHub Actions
- Требует ручного подтверждения через `environment: dev` или `environment: prod` для защиты от случайного удаления
- Удаляет все ресурсы окружения в обратном порядке создания (защищено от даунтайма)

> **Важно:** Файл `variables.pkrvars.hcl` не заливается в Git (добавлен в `.gitignore`), так как содержит реальные ID ресурсов. В репозитории хранится только `variables.pkrvars.hcl.example` как шаблон.

## 📝 Переменные

| Переменная | Описание | Dev | Prod |
|------------|----------|-----|------|
| `web_count` | Количество веб-серверов | 1 | 2 |
| `bastion_ip` | IP бастиона | 192.168.1.50 | 192.168.11.50 |
| `db_ip` | IP БД | 192.168.2.200 | 192.168.12.200 |

## 🗑️ Удаление инфраструктуры

**Локально:**
```bash
# Dev
cd envs/dev
terraform destroy -var-file=dev.tfvars

# Prod
cd envs/prod
terraform destroy -var-file=prod.tfvars
```

**Через CI/CD:**

| Workflow | Триггер | Описание |
|----------|---------|----------|
| **Destroy Dev** | Ручной (`workflow_dispatch`) | Удаление инфраструктуры DEV |
| **Destroy Prod** | Ручной (`workflow_dispatch`) | Удаление инфраструктуры PROD |

- Запускаются вручную из интерфейса GitHub Actions
- Требуют ручного подтверждения через `environment: dev` и `environment: prod` для защиты от случайного удаления
- Удаляют все ресурсы окружения в обратном порядке создания