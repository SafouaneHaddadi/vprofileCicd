def COLOR_MAP = [
    'SUCCESS': 'good', //good dans slack signifie la couleur vert
    'FAILURE': 'danger,'
]

pipeline {
    agent any {

   environment {
    
        NEXUSPASS = credentials('nexuspass')
    }


       //demande les parametres que l'user doit entrer, qui sera le mm que celui correspondant à la version de l'artefact 
        stage("Setup parameters"){
            steps{
                script{
                    properties([
                        parameters([
                            string(
                                defaultValue: '', //nothing
                                name: 'BUILD', //nom de la var
                            ),
                            string(
                                defaultValue: '',
                                name: 'TIME'
                            )
                        ])
                    ])
                }
            }
        }
    
        stage('Ansible Deploy to prod'){
            steps {
                ansiblePlaybook([
                inventory   : 'ansible/prod.inventory',
                playbook    : 'ansible/site.yml',
                installation: 'ansible',
                colorized   : true,
			    credentialsId: 'applogin-prod', //credentials sur jenkins
			    disableHostKeyChecking: true,
                extraVars   : [
                   	USER: "admin",
                    PASS: "${NEXUSPASS}",
			        nexusip: "172.31.20.96",
			        reponame: "vprofile-release",
			        groupid: "QA",
			        time: "${env.TIME}",
			        build: "${env.BUILD}",
                    artifactid: "vproapp",
			        vprofile_version: "vproapp-${env.BUILD}-${env.TIME}.war"
                ]
             ])
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
