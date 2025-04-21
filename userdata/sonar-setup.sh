#!/bin/bash
# Utilise l'interpréteur Bash

# Sauvegarde du fichier sysctl (configuration du noyau Linux)
cp /etc/sysctl.conf /root/sysctl.conf_backup

# Mise à jour des limites système nécessaires à Elasticsearch (utilisé par SonarQube)
cat <<EOT> /etc/sysctl.conf
vm.max_map_count=262144
fs.file-max=65536
ulimit -n 65536
ulimit -u 4096
EOT

# Sauvegarde des limites de sécurité pour les utilisateurs
cp /etc/security/limits.conf /root/sec_limit.conf_backup

# Configuration des limites spécifiques à l’utilisateur sonarqube
cat <<EOT> /etc/security/limits.conf
sonarqube   -   nofile   65536
sonarqube   -   nproc    409
EOT



#---------------------------------------------------
# Installation de Java et PostgreSQL 

sudo apt-get update -y
sudo apt-get install openjdk-17-jdk -y
# Installe OpenJDK 17, requis pour SonarQube

sudo update-alternatives --config java
java -version
# Permet de s'assurer que Java 17 est bien sélectionné

# Installation de PostgreSQL (base de données utilisée par SonarQube)
sudo apt update

#Importer la clé GPG officielle de PostgreSQL pour que notre système fasse confiance aux paquets venant de ce dépôt.
wget -q https://www.postgresql.org/media/keys/ACCC4CF8.asc -O - | sudo apt-key add -

#ajoute le dépôt officiel PostgreSQL à ton système Debian/Ubuntu pour pouvoir installer une version plus récente de PostgreSQL que celle disponible par défaut
sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt/ $(lsb_release -cs)-pgdg main" >> /etc/apt/sources.list.d/pgdg.list'
#'release -cs C’est une substitution de commande : elle renvoie le nom de code de ta distribution (ex : jammy pour Ubuntu 22.04)

sudo apt install postgresql postgresql-contrib -y
sudo systemctl enable postgresql.service
sudo systemctl start  postgresql.service




#--------------------------
#Configuration PostgreSQL pour SonarQube :

sudo echo "postgres:admin123" | chpasswd
# Modifie le mot de passe de l’utilisateur postgres

runuser -l postgres -c "createuser sonar"
# Crée un utilisateur PostgreSQL appelé sonar

sudo -i -u postgres psql -c "ALTER USER sonar WITH ENCRYPTED PASSWORD 'admin123';"
sudo -i -u postgres psql -c "CREATE DATABASE sonarqube OWNER sonar;"
sudo -i -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE sonarqube to sonar;"
systemctl restart postgresql



#------------------------------------

#Téléchargement et configuration de SonarQube :

#systemctl status -l   postgresql

netstat -tulpena | grep postgres
# Vérifie que PostgreSQL écoute bien

sudo mkdir -p /sonarqube/
cd /sonarqube/
sudo curl -O https://binaries.sonarsource.com/Distribution/sonarqube/sonarqube-9.9.8.100196.zip
# Télécharge la version de SonarQube

sudo apt-get install zip -y
sudo unzip -o sonarqube-9.9.8.100196.zip -d /opt/
sudo mv /opt/sonarqube-9.9.8.100196/ /opt/sonarqube

# Création de l'utilisateur système pour exécuter SonarQube
sudo groupadd sonar
sudo useradd -c "SonarQube - User" -d /opt/sonarqube/ -g sonar sonar
sudo chown sonar:sonar /opt/sonarqube/ -R


#-----------------------------------

#Configuration de SonarQube (sonar.properties) : 


cp /opt/sonarqube/conf/sonar.properties /root/sonar.properties_backup
cat <<EOT> /opt/sonarqube/conf/sonar.properties
sonar.jdbc.username=sonar
sonar.jdbc.password=admin123
sonar.jdbc.url=jdbc:postgresql://localhost/sonarqube
sonar.web.host=0.0.0.0
sonar.web.port=9000
sonar.web.javaAdditionalOpts=-server
sonar.search.javaOpts=-Xmx512m -Xms512m -XX:+HeapDumpOnOutOfMemoryError
sonar.log.level=INFO
sonar.path.logs=logs
EOT


#----------------------------

#  Création du service SonarQube :

cat <<EOT> /etc/systemd/system/sonarqube.service
[Unit]
Description=SonarQube service
After=syslog.target network.target

[Service]
Type=forking

ExecStart=/opt/sonarqube/bin/linux-x86-64/sonar.sh start
ExecStop=/opt/sonarqube/bin/linux-x86-64/sonar.sh stop

User=sonar
Group=sonar
Restart=always

LimitNOFILE=65536
LimitNPROC=4096


[Install]
WantedBy=multi-user.target
EOT

systemctl daemon-reload
systemctl enable sonarqube.service
#systemctl start sonarqube.service
#systemctl status -l sonarqube.service



#---------------------------------------

#Reverse Proxy avec Nginx : 


apt-get install nginx -y
rm -rf /etc/nginx/sites-enabled/default
rm -rf /etc/nginx/sites-available/default
cat <<EOT> /etc/nginx/sites-available/sonarqube
server{
    listen      80;
    server_name sonarqube.groophy.in;

    access_log  /var/log/nginx/sonar.access.log;
    error_log   /var/log/nginx/sonar.error.log;

    proxy_buffers 16 64k;
    proxy_buffer_size 128k;

    location / {
        proxy_pass  http://127.0.0.1:9000;
        proxy_next_upstream error timeout invalid_header http_500 http_502 http_503 http_504;
        proxy_redirect off;
              
        proxy_set_header    Host            \$host;
        proxy_set_header    X-Real-IP       \$remote_addr;
        proxy_set_header    X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header    X-Forwarded-Proto http;
    }
}
EOT
ln -s /etc/nginx/sites-available/sonarqube /etc/nginx/sites-enabled/sonarqube
systemctl enable nginx.service
#systemctl restart nginx.service


#---------------------

#Firewall et redémarrage : 


sudo ufw allow 80,9000,9001/tcp

echo "System reboot in 30 sec"
sleep 30
reboot
