# ayden1st_infra
ayden1st Infra repository

### 5 лекция
#### 5.1 Подключение к внутреннему хосту в одну строку
Используется ProxyJump
`ssh -i ~/.ssh/appuser -J appuser@178.154.255.137 appuser@10.128.0.32`
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
