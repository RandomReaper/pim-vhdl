pipeline
{
    environment
    {
        PROJECTNAME = "pim-vhdl"
        SUBJECT_SUB = "${env.PROJECTNAME} (${env.JOB_NAME},  build ${env.BUILD_NUMBER})"
    }

    agent
    {
        dockerfile
        {
	        filename 'Dockerfile'
	        dir 'ci'
	        additionalBuildArgs '-t jenkins-${JOB_NAME}'
	        args '''
	        	-v /tmp:/tmp
	        	-v "${WORKSPACE}:/repo"
	        '''
    	}
    }
    
    stages
    {
        stage('pre')
        {
			steps
			{
				sh '#apt-get install -y git'
			}
        }
        parallel
        {
    		stage('tb-unmanaged')
    		{
    			steps
    			{
    				sh '''
    					cd /repo
    					./ci/${STAGE_NAME}.sh
    				'''
    			}
    			post
    			{
    				failure
    				{
    					sh '''
    						cd /repo
    						VERBOSE=1 ./ci/${STAGE_NAME}.sh
    					'''
    				}
    			}
    		}
            stage('tb-managed_reset')
            {
                steps
                {
                    sh '''
                        cd /repo
                        ./ci/${STAGE_NAME}.sh
                    '''
                }
                post
                {
                    failure
                    {
                        sh '''
                            cd /repo
                            VERBOSE=1 ./ci/${STAGE_NAME}.sh
                        '''
                    }
                }
            }
            stage('tb-managed_no_reset')
            {
                steps
                {
                    sh '''
                        cd /repo
                        ./ci/${STAGE_NAME}.sh
                    '''
                }
                post
                {
                    failure
                    {
                        sh '''
                            cd /repo
                            VERBOSE=1 ./ci/${STAGE_NAME}.sh
                        '''
                    }
                }
            }
        }
        stage('codingstyle')
        {
			steps
			{
				sh '''
					cd /repo
					./ci/codingstyle.sh
				'''
			}
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
