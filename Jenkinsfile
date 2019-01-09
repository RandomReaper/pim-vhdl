pipeline
{
    environment
    {
        PROJECTNAME = "pim-vhdl"
        SUBJECT_SUB = "${env.PROJECTNAME} (${env.JOB_NAME},  build ${env.BUILD_NUMBER})"
    }

    agent
    {
        docker
        {
            image 'ghdl/ghdl:ubuntu18-llvm-5.0'
            args '''
                -u root:root
                -v "${WORKSPACE}:/repo"
                -v "${JENKINS_HOME}/caches/${env.PROJECTNAME}-bundle-cache:/usr/local/bundle:rw"
            '''
        }
    }
    
    stages
    {
		stage('tb')
		{
			steps
			{
				script
				{
					try
					{
						sh '''
							cd /repo
							./ci/tb.sh
						'''
					}
					catch (Exception e)
					{
						sh '''
							cd /repo
							VERBOSE=1 ./ci/tb.sh
						'''
  					}
				}
            }
		}
        stage('codingstyle')
        {
				sh '''
					cd /repo
					./ci/codingstyle.sh
				'''
        }		
    }

    post
    {
        always
        {
            emailext (
                subject: "[jenkins] Job always ${env.SUBJECT_SUB}",
                mimeType: 'text/html',
                body: '${JELLY_SCRIPT,template="html"}',
                recipientProviders: [[$class: 'DevelopersRecipientProvider']]
            )
        }


        fixed
        {
            emailext (
                subject: "[jenkins] Job fixed ${env.SUBJECT_SUB}",
                mimeType: 'text/html',
                body: '${JELLY_SCRIPT,template="html"}',
                recipientProviders: [[$class: 'DevelopersRecipientProvider']]
            )
        }
        regression
        {
            emailext (
                subject: "[jenkins] Job regression ${env.SUBJECT_SUB}",
                mimeType: 'text/html',
                body: '${JELLY_SCRIPT,template="html"}',
                recipientProviders: [[$class: 'DevelopersRecipientProvider']]
            )
        }
    }
}
