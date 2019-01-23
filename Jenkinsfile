pipeline
{
    agent
    {
        dockerfile
        {
	        filename 'Dockerfile'
	        dir 'ci'
	        additionalBuildArgs '-t jenkins-${JOB_NAME}'
	        args """
	        	-v /tmp:/tmp
	        """
    	}
    }
    options
    {
    	ansiColor('xterm')
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
        stage('tb')
        {
            parallel
            {
        		stage('tb-unmanaged')
        		{
        			steps
        			{
        				sh '''
        					./ci/${STAGE_NAME}.sh
        				'''
        			}
        			post
        			{
        				failure
        				{
        					sh '''
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
                            ./ci/${STAGE_NAME}.sh
                        '''
                    }
                    post
                    {
                        failure
                        {
                            sh '''
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
                            ./ci/${STAGE_NAME}.sh
                        '''
                    }
                    post
                    {
                        failure
                        {
                            sh '''
                                VERBOSE=1 ./ci/${STAGE_NAME}.sh
                            '''
                        }
                    }
                }
            }
        }
        stage('tb-vunit')
        {
            steps
            {
                sh '''
                    cd tb/vunit
                    ./run.py --xunit-xml vunit_output.xml
                '''
            }
            post
            {
                always
                {
                    junit 'tb/vunit/vunit_output.xml' 
                }
            }
        }
        stage('codingstyle')
        {
			steps
			{
				sh '''
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
                subject: "[jenkins][${env.JOB_NAME}] Build ${env.BUILD_NUMBER} status:${currentBuild.currentResult}",
                mimeType: 'text/html',
                body: '${JELLY_SCRIPT,template="html"}',
                recipientProviders: [[$class: 'DevelopersRecipientProvider']]
            )
        }


        fixed
        {
            emailext (
                subject: "[jenkins][${env.JOB_NAME}] Build ${env.BUILD_NUMBER} fixed",
                mimeType: 'text/html',
                body: '${JELLY_SCRIPT,template="html"}',
                recipientProviders: [[$class: 'DevelopersRecipientProvider']]
            )
        }
        regression
        {
            emailext (
                subject: "[jenkins][${env.JOB_NAME}] Build ${env.BUILD_NUMBER} regression",
                mimeType: 'text/html',
                body: '${JELLY_SCRIPT,template="html"}',
                recipientProviders: [[$class: 'DevelopersRecipientProvider']]
            )
        }
    }
}
