[![Validate](https://github.com/Otus-DevOps-2022-02/ayden1st_infra/actions/workflows/validate.yml/badge.svg)](https://github.com/Otus-DevOps-2022-02/ayden1st_infra/actions/workflows/validate.yml)

# ayden1st_infra
ayden1st Infra repository

### 5 лекция
#### 5.1 Подключение к внутреннему хосту в одну строку
Используется ProxyJump
`ssh -i ~/.ssh/appuser -J appuser@193.32.218.235 appuser@10.128.0.32`
#### 5.2 Конфигурация ssh
Для подключения к внутренним ресурсам можно создать алиас в конфигурации ssh.
Настроить `~/.ssh/config`
```
### The Bastion Host
Host bastion
    Hostname 193.32.218.235
    User appuser

### someinternalhost
host someinternalhost
    Hostname 10.128.0.32
    User appuser
    ProxyJump bastion
```
#### 5.3 Конфигурация pritunl для проверки
Pritunl установлен на ubuntu 20.04 (для 16.04 нет пакета pritunl)
Настроен сертификат Let's Encrypt через nip.io.
https://193.32.218.235.nip.io
Маршрут задан для 10.128.0.32/32
bastion_IP = 193.32.218.235
someinternalhost_IP = 10.128.0.32

### 6 Лекция
Команда создания виртуальной машины
```
yc compute instance create \
--name reddit-app \
--hostname reddit-app \
--memory=4 \
--create-boot-disk image-folder-id=standard-images,image-family=ubuntu-1604-lts,size=10GB \
--network-interface subnet-name=default-ru-central1-a,nat-ip-version=ipv4 \
--metadata serial-port-enable=1 \
--metadata-from-file user-data=./metadata.yaml
```
cloud-init конфигурация в файле `metadata.yaml`

testapp_IP = 51.250.69.13
testapp_port = 9292

### 7 Лекция
#### 7.1 Образ reddit-base
Создана конфигурация для packer создающая образ виртуальной машины с установленными зависимостями для приложения.
Запуск `cd packer&&packer build -var-file=variables.json ./ubuntu16.json`
Файл variable.json создать по примеру variable.json.example.
Файл key.json можно создать следующими коммандами:
```
SVC_ACCT="<имя сервисной учетной записи>"
FOLDER_ID="<id папки>"
yc iam service-account create --name $SVC_ACCT --folder-id $FOLDER_ID

ACCT_ID=$(yc iam service-account get $SVC_ACCT | \
grep ^id | \
awk '{print $2}')

yc resource-manager folder add-access-binding --id $FOLDER_ID \
--role editor \
--service-account-id $ACCT_ID

yc iam key create --service-account-id $ACCT_ID --output <путь до ключа>/key.json
```
#### 7.2 Образ reddit-full
Создана конфигурация для packer создающая образ виртуальной машины с установленными зависимостями и запущенным приложением.
Запуск `cd packer&&packer build -var-file=variables.json ./immutable.json`
Файлы variable.json и создать по примеру variable.json.examples.
Скрипт создания виртуальной машины `config-sripts/create-reddit-vm.sh`

### 8 Лекция
Yandex провайдер
```
terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
      version = "0.73.0"
    }
  }
}
```
Зеркало yandex провайдера
```
terraform {
  required_providers {
    yandex = {
      source = "terraform-registry.storage.yandexcloud.net/yandex-cloud/yandex"
      version = "0.72.0"
    }
  }
}
```
#### 8.1 Конфигурация terraform
В папке `terraform` создана конфигурация инфраструктуры с описанием создания виртуальных машин и балансировщика в формате terraform (файлы `*.tf` ). Пример переменных для конфигурации вынесен в файл `terraform.tfvars.example`

Применение конфигурации:
```
terraform plan
terraform apply --auto-approve
```
Удаление инфраструктуры:
```
terraform destroy
```
#### 8.2 Балансировщик
В файле `lb.tf` описана конфигурация балансировщика для серверов приложения.
Недостаток описания каждого сервера приложения заключается в колличестве кода, возможности ошибок. Так же база данных не вынесена в бэкэнд.
Лишнего кода позволяет избежать использование мета-переменной `count`, задающую количество инстансов приложения и включающих их в группу балансировки.

### 9 Лекция
Созданы модули ресурсов `app`, `db` и `vpc`.
Созданы две среды `prod` и `stage`, с использовнием модулей и определением переменных.
Инициализация модулей:
```
terraform get
```
#### 9.1 Удаленное хранилище состояния
Конфигурация бекэнда хранилища статуса в файле `storage.tf`.
Для получения ключа и секрета доступа нужно выполнить:
```
SVC_ACCT="<имя сервисной учетной записи>"
FOLDER_ID="<id папки>"
yc iam service-account create --name $SVC_ACCT --folder-id $FOLDER_ID

ACCT_ID=$(yc iam service-account get $SVC_ACCT | \
grep ^id | \
awk '{print $2}')

yc resource-manager folder add-access-binding --id $FOLDER_ID \
--role editor \
--service-account-id $ACCT_ID

yc iam access-key create --service-account-name $SVC_ACCT
```
Key_id записать в переменную `storage_key`, Secret в переменную `storage_secret`.

Перед использованием бекенда нужно выполнить:
```
terraform init
```
Для конфигурации бекэнда хранения состояния, нельзя использовать переменные.
Есть выход в использования конфигурационного файла или ключ=значение в командной стороке (? возможно использовать защищенные переменные из хранилищ)
```
terraform init \
    -backend-config="address=demo.consul.io" \
    -backend-config="path=example_app/terraform_state" \
    -backend-config="scheme=https"
```
```
terraform init -backend-config=./backend.conf
```
Конфигурация сохраняется в удаленное хранилище и блокирует выполнение одновременных изменений.
#### 9.2
В модули `app` и `db` добавлены provisions с переменной `enable_provisions` (по-умолчанию true) через `null_resource`:
- В модуле `db` добавлен шаблон конфигурации сервиса `mongod` для определения ip адреса
- В модуле `app` добавлена установка приложения из прошлых заданий, и шаблон сервиса `puma.service`, который принимает ip адрес от ресурса `db`.
Null провайдер от hashicorp не скачивался, использовался альтернативный:
```
null = {
      source = "mildred/null"
      version = "1.1.0"
    }
```

### 10 Лекция

#### 10.1 Динамический inventory
Динамический inventory - исполняемыq файл, который гененрирует список в JSON формате (через API, парсере вывода утилит и т.п.) при обращении к файлу с параметрами:
- `--list` - отдает в JSON формате группы со списком входящими в них хостами и переменными группы
```
{
    "group1": {
        "hosts": ["host1", "host2"],
        "vars": {
            "a": true
        }
    },
    "group2": ["host2", "host3"]
}
```
- `--host` <HOSTNAME> - отдает переменные хоста, например `ansible_host: <IP-адрес>`
```
{
    "favcolor": "red",
    "ntpserver": "wolf.example.com",
    "monitoring": "pack.example.com"
}
```
Для выполения опросов всех хостов при параметре `--host <HOSTNAME>` может понадобится много обращений, для минимизации обращений, предусмотрен элемент `_meta`, в котором можно перечислить все переменные для хостов без дополнительных вызовов параметра `--host`.
```
{
    _meta": {
        "hostvars": {
            "host1": {
                "ansible_host": "192.168.0.1"
            },
            "host2": {
                "ansible_host": "192.168.0.2"
            }
        }
    },
    "group1": {
        "hosts": ["host1", "host2"]
    }
}
```
В рамках задания создан скрипт `inventory.json` возвращающий данные с элементом `_meta` из состояния сред prod и stage, или одной из них.

### 11 Лекция

#### 11.1 Ansible
Добавлены ansible плейбуки установки и настройки базы данных и приложения, `app.yml`, `db.yml`, `deploy.yml`.
Установка всех:
```
ansible-playbook site.yml
```
#### 11.2 Packer & Ansible
Добавлены ansible плейбуки для сборки образов с packer, `packer_app.yml`, `packer_db.yml`.
Запуск сборки из корня репозитория:
```
packer build -var-file=packer/variables.json packer/app.json
packer build -var-file=packer/variables.json packer/db.json
```

В ходе сборки может возникнуть ошибка <span style="color:red">failed to handshake</span>:
В блок provisioners можно добавить параметр:
```
"extra_arguments": ["-vvvv"]
```
для дебага.

Для испраления ошибки handshake нужно внести в `~/.ssh/config` строку:
```
Host *
  PubkeyAcceptedKeyTypes=+ssh-dss
```

### Лекция 12
Созданы роли для установки app, db. Отредактированы плейбуки для использования ролей. Созданы два инвентаря для сред stage и prod с отдельными переменными. Добавлена роль jdauphant.nginx из ansible-galaxy для установки http_proxy для app. Добавлены зашифрованные переменные для плейбука users.yml через ansible-vault, ключ в vault.key (создана заглушка vault.key.example)
Запуск полной установки:
```
ansible-playbook playbooks/site.yml #stage
ansible-playbook -i enviroments/prod/inventory playbooks/site.yml
```
#### 12.1
Для динамического инвентаря под окружения stage, prod адаптирован скрипт inventory.py получающий JSON из state terraform.

#### 12.2
Написаны проверки GitHub Actions через TravisCI, добавлены в файл workflows/validate.yml
- packer validate
- terraform validate
- ansible-lint
В каталог ansible добавлен конфиг .config/ansible-lint.yml для ansible-lint.
Добавлен бэйдж в файл README.md

### Лекция 13
Установлен Vagrant и VirtualBox. При запуске Vagrantfile, возможно возникновение ошибки:
```
Stderr: VBoxManage: error: Code E_ACCESSDENIED (0x80070005) - Access denied (extended info not available)
VBoxManage: error: Context: "EnableStaticIPConfig(Bstr(pszIp).raw(), Bstr(pszNetmask).raw())" at line 242 of file VBoxManageHosto
nly.cpp
```
Для исправления нужно в файл `/etc/vbox/networks.conf` прописать параметр `* 10.0.0.0/8`.
Доработаны роли app и db для провиженинга в vagrant.
Установлены утилиты тестирования molecule, testinfra.
Создание venv для python и установка зависимостей:
```
python3 -m venv env ~/env/otus
source ~/env/otus/bin/activate
python3 -m pip install -r ansible/requirements.txt
```
В роли db создан сценарий тестирования:
```
molecule init scenario -r db -d vagrant
```
Добавлен тест на доступность порта mongod. Запуск тестов:
```
molecule test --all
```
Плейбуки для сборки образов `app`, `db` в packer доработаны на испольование ролей. Путь до ролей задается ENV `ANSIBLE_ROLES_PATH`.
