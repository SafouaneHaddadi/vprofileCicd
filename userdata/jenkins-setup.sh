#!/bin/bash
# Déclare que ce script doit être exécuté avec Bash

sudo apt update
# Met à jour la liste des paquets disponibles sur le système

sudo apt install openjdk-17-jdk -y
# Installe OpenJDK 17 (Jenkins nécessite Java pour fonctionner)

sudo wget -O /usr/share/keyrings/jenkins-keyring.asc \
https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key
# Télécharge la clé GPG officielle de Jenkins et la stocke dans /usr/share/keyrings/
# Cette clé permet de vérifier l’authenticité du dépôt Jenkins

echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/" | \
sudo tee /etc/apt/sources.list.d/jenkins.list > /dev/null
# Ajoute le dépôt officiel de Jenkins à la liste des sources de paquets
# La clé précédemment téléchargée est utilisée pour signer ce dépôt

sudo apt-get update
# Recharge la liste des paquets, y compris ceux du nouveau dépôt Jenkins

sudo apt-get install jenkins -y
# Installe Jenkins depuis le dépôt officiel
