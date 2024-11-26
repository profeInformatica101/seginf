#!/bin/bash
# Crear usuarios con contraseñas
users=("webadmin:admin123" "developer1:dev123" "developer2:dev456" "tester:test123")
for user_pass in "${users[@]}"; do
    user=$(echo $user_pass | cut -d':' -f1)
    pass=$(echo $user_pass | cut -d':' -f2)
    sudo useradd -m -s /bin/bash "$user"
    echo -e "$pass\n$pass" | sudo passwd "$user"
done
# Crear grupos y asignar usuarios
sudo groupadd admins
sudo groupadd developers
sudo groupadd testers
sudo usermod -aG admins webadmin
sudo usermod -aG developers developer1 developer2
sudo usermod -aG testers tester
# Crear directorios
sudo mkdir -p /var/www/webproject/dev
sudo mkdir -p /var/www/webproject/test
sudo chown webadmin:admins /var/www/webproject
sudo chmod 770 /var/www/webproject
