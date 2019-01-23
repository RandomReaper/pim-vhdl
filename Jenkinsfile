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
                    ./run.py --clean --no-color --xunit-xml vunit_output.xml
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
            telegramSend """
            Build *${env.JOB_NAME}* #${env.BUILD_NUMBER} status:*${currentBuild.currentResult}*, [details](${env.BUILD_URL})
            """
        }


        fixed
        {
            telegramSend """
            Build *${env.JOB_NAME}* #${env.BUILD_NUMBER} status:*Fixed !*, [details](${env.BUILD_URL})
            """
        }

        regression
        {
            telegramSend """
            Build *${env.JOB_NAME}* #${env.BUILD_NUMBER} status:*Regression!*, [details](${env.BUILD_URL})
            """
        }
    }
}
