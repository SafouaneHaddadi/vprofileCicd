
def buildNumber = Jenkins.instance.getItem('cicd-jenkins-beanstalk-stage').lastSuccessfulBuild.number

def COLOR_MAP = [
    'SUCCESS': 'good', //good dans slack signifie la couleur vert
    'FAILURE': 'danger,'
]

pipeline {
    agent any
{

   environment {
        ARTIFACT_NAME = "vprofile-v${buildNumber}.war"
        AWS_S3_BUCKET = "vprofilecicdbean121"
        AWS_EB_APP_NAME = "vproapp-bean"
        AWS_EB_ENVIRONMENT = "Vproapp-bean-prod-env"
        AWS_EB_APP_VERSION = "${buildNumber}"
        
    }

        stage("Deploy to Beanstalk prod env") {
            steps{
            //car on va executer ces cmd cli avec les info de credential de l'user IAM
            withAWS(credentials: 'awsbeancreds', region: 'us-east-1') {
               sh 'aws elasticbeanstalk update-environment --application-name $AWS_EB_APP_NAME --environment-name $AWS_EB_ENVIRONMENT --version-label $AWS_EB_APP_VERSION'

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
