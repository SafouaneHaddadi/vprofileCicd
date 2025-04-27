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
        RELEASE_REPO    = 'vprofile-release'
        CENTRAL_REPO    = 'vpro-maven-central'
        NEXUS_IP         = '172.31.20.96' //ip privée de l'instance EC2 Nexus
        NEXUS_PORT       = '8081'
        NEXUS_GRP_REPO  = 'vpro-maven-group'
        NEXUS_LOGIN     = 'nexuslogin' //NEXUS_LOGIN correspond à la var dans le fichier xml et 'nexuslogin' cest ce qu'on a indiqué dans les credentials sur Jenkins
        ARTIFACT_NAME = "vprofile-v${BUILD_ID}.war"
        AWS_S3_BUCKET = "vprofilecicdbean121"
        AWS_EB_APP_NAME = "vproapp-bean"
        AWS_EB_ENVIRONMENT = "Vproappbean-env"
        AWS_EB_APP_VERSION = "${BUILD_ID}"
        
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

stage("Quality gate") {
            /* Le webhook permet à SonarQube de prévenir Jenkins une fois que l’analyse est terminée.
            Sans ce webhook, Jenkins attendrait indéfiniment (ou jusqu'au timeout), car il n'aurait aucun moyen de savoir que SonarQube a fini l’analyse */  
            steps {
                timeout(time: 1, unit: 'HOURS') {
                    // Attend le résultat du quality gate de SonarQube, avec un timeout d'une heure
                    // Si la qualité ne passe pas, le pipeline est automatiquement arrêté
                    waitForQualityGate abortPipeline: true
                }
            }
        }

         // Définition d'une étape dans le pipeline Jenkins appelée "UploadArtifact"
        stage("UploadArtifact") {
    
            steps {
                // Utilisation du plugin nexusArtifactUploader pour uploader un artefact vers Nexus
                nexusArtifactUploader(
                    nexusVersion: 'nexus3',  // Spécifie la version de Nexus utilisée (ici Nexus 3)
                    protocol: 'http',        // Protocole de communication utilisé avec Nexus
                    nexusUrl: "${NEXUS_IP}:${NEXUS_PORT}",   // Adresse IP ou URL de Nexus, stockée dans une variable d’environnement
                    groupId: 'QA',           // Groupe Maven sous lequel l’artefact sera publié
                    // Version de l’artefact composée de l’ID du build + timestamp (timestamp fourni par un plugin Jenkins)
                    version: "${env.BUILD_ID}-${env.BUILD_TIMESTAMP}",
                    repository: "${RELEASE_REPO}", // Nom du repository Nexus où l’artefact sera uploadé (stocké dans une variable d’env)
                    credentialsId: "${NEXUS_LOGIN}", // Identifiants Jenkins pour se connecter à Nexus (ID des credentials configurés dans Jenkins)
                    artifacts: [ // Liste des artefacts à uploader
                        [
                            artifactId: 'vproapp',           // Nom de l’artefact (doit correspondre à l’ID défini dans le pom.xml s'il y a lieu)
                            classifier: '',                 // Classificateur (peut rester vide si non utilisé)
                            file: 'target/vprofile-v2.war', // Chemin vers le fichier à uploader (généré lors du build Maven par exemple)
                            type: 'war'                     // Type de l’artefact (ici une archive WAR)
                        ]
                    ]
                )
            }
        }

        stage("Deploy to Beanstalk stage env") {
            //car on va executer ces cmd cli avec les info de credential de l'user IAM
            withAWS(credentials: 'beancreds', region: 'us-east-1') {
               sh 'aws s3 cp ./target/vprofile-v2.war s3://$AWS_S3_BUCKET/$ARTIFACT_NAME'
               sh 'aws elasticbeanstalk create-application-version --application-name $AWS_EB_APP_NAME --version-label $AWS_EB_APP_VERSION --source-bundle S3Bucket=$AWS_S3_BUCKET,S3Key=$ARTIFACT_NAME'
               sh 'aws elasticbeanstalk update-environment --application-name $AWS_EB_APP_NAME --environment-name $AWS_EB_ENVIRONMENT --version-label $AWS_EB_APP_VERSION'

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
