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
| **Packer Build** | Ручной (`workflow_dispatch`) | Сборка образа, авто-push ID |
| **Terraform Dev** | Push в `main` | Validate → Plan → Apply (подтверждение) |
| **Terraform Prod** | Push в `main` | Validate → Plan → Apply (подтверждение) |

## 🔧 Технологии

- **Terraform** — Infrastructure as Code (модули, S3 backend)
- **Packer** — сборка образов (Ubuntu + nginx + PHP)
- **GitHub Actions** — CI/CD пайплайн
- **VK Cloud** — облачный провайдер

## 🛠️ Использование

### Локальный запуск

```bash
# Packer
cd packer
cp variables.pkrvars.hcl.example variables.pkrvars.hcl
# Настройте variables.pkrvars.hcl под свой проект
packer init lab-packer-config.pkr.hcl
OS_CLOUD=vkcs packer build lab-packer-config.pkr.hcl

# Terraform Dev
cd envs/dev
terraform init
terraform plan -var-file=dev.tfvars
terraform apply -var-file=dev.tfvars

# Terraform Prod
cd envs/prod
terraform init
terraform plan -var-file=prod.tfvars
terraform apply -var-file=prod.tfvars
```

## CI/CD запуск

- **Packer:** Actions → Packer Build → Run workflow
- **Terraform Dev/Prod** запускаются автоматически при push
- **Apply** требует подтверждения в GitHub

## 📝 Переменные

| Переменная | Описание | Dev | Prod |
|------------|----------|-----|------|
| `web_count` | Количество веб-серверов | 1 | 2 |
| `bastion_ip` | IP бастиона | 192.168.1.50 | 192.168.11.50 |
| `db_ip` | IP БД | 192.168.2.200 | 192.168.12.200 |

## 🔐 Обновление Packer образа

По умолчанию в модуле `compute` используется `lifecycle { ignore_changes = [image_id] }`. Это защищает ВМ от пересоздания при каждом `terraform apply`.

### Когда нужно обновить образ:
1. **Запустить Packer** (локально или через GitHub Actions → Packer Build)
2. **Получить новый ID образа:**
   - Локально: Packer запишет `image.auto.tfvars` автоматически
   - Через CI/CD: выполнить `git pull` для получения обновлённого `image.auto.tfvars`
3. **Отключить защиту:** закомментировать `lifecycle { ignore_changes = [image_id] }` в `modules/compute/main.tf`
4. **Применить Terraform:** `terraform apply` — ВМ пересоздадутся с новым образом
5. **Вернуть защиту:** раскомментировать `lifecycle` обратно
6. При последующих `terraform apply` ВМ не будут пересоздаваться