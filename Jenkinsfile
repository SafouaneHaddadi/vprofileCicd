def COLOR_MAP = [
    'SUCCESS': 'good', //good dans slack signifie la couleur vert
    'FAILURE': 'danger,'
]

pipeline {
    agent any

    tools {
        maven "MAVEN3.9"
        jdk "JDK17" //le nom qu'on a donné dans la section 'Tools' de Jenkins
    }

    environment {
        SNAP_REPO       = 'vprofile-snapshot'
        NEXUS_USER      = 'admin'
        NEXUS_PASS      = 'admin123'
        RELEASE_REPO    = 'vprofile-release'
        CENTRAL_REPO    = 'vpro-maven-central'
        NEXUSIP         = '172.31.20.96' //ip privée de l'instance EC2 Nexus
        NEXUSPORT       = '8081'
        NEXUS_GRP_REPO  = 'vpro-maven-group'
        NEXUS_LOGIN     = 'nexuslogin' //NEXUS_LOGIN correspond à la var dans le fichier xml et 'nexuslogin' cest ce qu'on a indiqué dans les credentials sur Jenkins
        registryCredential = 'ecr:us-east-1:awscreds' //awscreds est le credential ajouté sur jenkins
        appRegistry = '039612873733.dkr.ecr.us-east-1.amazonaws.com/vprofileappimg' //on c/c l'url de notre repository ECR sur aws (syntaxe : [Account_Name]/[Image_name]) c'est le nom de notre image
        vprofileRegistry = 'hhttps://039612873733.dkr.ecr.us-east-1.amazonaws.com' //ici on c/c l'url
        cluster = "vprostaging" //cluster représente le nom du cluster ECS où nos conteneurs sont déployés.
        service = "vproappprodsvc" //le service dans un cluster est la tache qui executera notre conteneur; qui recuperera l'image de ECR et executera le conteneur.
        /* En gros, Le service ECS déploie un ou plusieurs conteneurs à partir d'une définition de tâche. Une définition de tâche spécifie l'image Docker à utiliser, les ressources nécessaires (CPU, mémoire), 
        les ports à exposer, et d'autres configurations. */
    }

    stages {
        stage('Build') {
            steps {
                sh 'mvn -s settings.xml -DskipTests install' //on skip le test d'unité. Et dans les settings.xml on indique que qd on lance la cmd maven, elle doit DL les dependances àpd Nexus   
            }
            post {
                success {
                    echo "Now archiving..."
                    archiveArtifacts artifacts: "**/*.war" //on archive tout ce qui se termine par .war
                }
            }
        }

        stage('Test') {
            steps {
                sh 'mvn -s settings.xml test' //generera un report
            }
        }

        stage('Checkout Analysis') {
            steps {
                sh 'mvn -s settings.xml checkstyle:checkstyle' //generera un report au format xml mais ces 2 rapports ne sont pas lisible par l'homme, on a donc besoin d'un outil capable de stocker ces données, de les analyser et de les présenter dans un format lisible
            }
        }

         stage("Sonar Code Analysis") {
    environment {
        scannerHome = tool 'sonar6.2' // Nom de l'outil sonar-scanner configuré dans Jenkins (Manage Jenkins > Global Tool Configuration)
    }
    steps {
        withSonarQubeEnv('sonarserver') { // Nom du serveur SonarQube configuré dans Jenkins (Manage Jenkins > Configure System)
            sh """
                ${scannerHome}/bin/sonar-scanner \
                -Dsonar.projectKey=vprofile \
                -Dsonar.projectName=vprofile \
                -Dsonar.projectVersion=1.0 \
                -Dsonar.sources=src/ \
                -Dsonar.java.binaries=target/test-classes/com/visualpathit/account/controllerTest/ \
                -Dsonar.junit.reportsPath=target/surefire-reports/ \
                -Dsonar.jacoco.reportsPath=target/jacoco.exec \
                -Dsonar.java.checkstyle.reportPaths=target/checkstyle-result.xml
            """
        }

        
    }
}
      

    }
  // Bloc 'post' dans un pipeline Jenkins : actions à exécuter après que le job ait tourné (réussi ou échoué)
post {
    
    // 'always' signifie que ce bloc sera exécuté à chaque fois, que le build réussisse ou non
    always {

        // Affiche un message dans la console Jenkins pour indiquer que la notification Slack va être envoyée
        echo "Slack notifications"

        // Envoie une notification Slack
        slackSend(
            // Canal Slack où le message sera envoyé. Ici, c’est juste un # en placeholder (à remplacer par ex: '#dev')
            channel: '#',

            // Couleur du message (vert pour succès, rouge pour échec, etc.) en fonction du résultat du build
            color: COLOR_MAP[currentBuild.currentResult],

            // Message affiché dans Slack : indique le résultat du build, le nom du job, le numéro du build,
            // et un lien vers plus d'infos (l'URL du build Jenkins)
            message: "*${currentBuild.currentResult}:* Job ${env.JOB_NAME} build ${env.BUILD_NUMBER} \n More info at: ${env.BUILD_URL}"
        )
    }
}

}
