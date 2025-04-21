#!/bin/bash
# Spécifie que le script doit être exécuté avec Bash

sudo rpm --import https://yum.corretto.aws/corretto.key
# Importe la clé GPG d'Amazon Corretto pour sécuriser les paquets

sudo curl -L -o /etc/yum.repos.d/corretto.repo https://yum.corretto.aws/corretto.repo
# Télécharge et place le fichier de dépôt Amazon Corretto dans le bon dossier

sudo yum install -y java-17-amazon-corretto-devel wget -y
# Installe Java 17 (Amazon Corretto) + wget
# Java est nécessaire pour faire tourner Nexus

# 📁 Création des dossiers nécessaires
mkdir -p /opt/nexus/
mkdir -p /tmp/nexus/

cd /tmp/nexus/
# Va dans le dossier temporaire pour télécharger Nexus

#  Téléchargement de Nexus
NEXUSURL="https://download.sonatype.com/nexus/3/nexus-unix-x86-64-3.78.0-14.tar.gz"
wget $NEXUSURL -O nexus.tar.gz
# Télécharge l’archive Nexus et la renomme

sleep 10
# Petite pause pour s'assurer que le téléchargement est bien terminé

EXTOUT=`tar xzvf nexus.tar.gz`
# Décompresse l’archive Nexus et stocke le nom du dossier extrait

NEXUSDIR=`echo $EXTOUT | cut -d '/' -f1`
# Récupère le nom du dossier extrait (ex: nexus-3.78.0-14)

sleep 5
rm -rf /tmp/nexus/nexus.tar.gz
# Supprime l’archive une fois extraite

cp -r /tmp/nexus/* /opt/nexus/
# Copie tous les fichiers extraits dans le dossier final d'installation

sleep 5

useradd nexus
# Crée un utilisateur système "nexus" pour faire tourner le service

chown -R nexus.nexus /opt/nexus
# Donne les droits à l’utilisateur nexus sur le dossier d’installation

# Création du service systemd pour démarrer Nexus automatiquement
cat <<EOT>> /etc/systemd/system/nexus.service
[Unit]
Description=nexus service
After=network.target

[Service]
Type=forking
LimitNOFILE=65536
ExecStart=/opt/nexus/$NEXUSDIR/bin/nexus start
ExecStop=/opt/nexus/$NEXUSDIR/bin/nexus stop
User=nexus
Restart=on-abort

[Install]
WantedBy=multi-user.target
EOT
# Crée un fichier de service systemd pour Nexus, afin qu’il soit géré comme un service Linux

echo 'run_as_user="nexus"' > /opt/nexus/$NEXUSDIR/bin/nexus.rc
# Configure Nexus pour qu’il tourne sous l’utilisateur "nexus"

systemctl daemon-reload
# Recharge la configuration des services systemd

systemctl start nexus
# Démarre le service Nexus

systemctl enable nexus
# Active Nexus pour qu’il se lance automatiquement au démarrage du système
