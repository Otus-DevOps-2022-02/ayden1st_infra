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
