pipeline {
    agent any

    environment {
        AWS_REGION = "us-east-1"
        TERRAFORM  = "C:\\terraform_1.13.3_windows_386\\terraform.exe"
        AWS_CLI    = "C:\\Program Files\\Amazon\\AWSCLIV2\\aws.exe"
        S3_BUCKET  = "jagvi-portfolio-site"
    }

    stages {
        stage('Clone Repository') {
            steps {
                echo '📦 Cloning portfolio repository...'
                git branch: 'main', url: 'https://github.com/vJagvi/PortfolioWebsite.git'
            }
        }

        stage('Terraform Init & Apply') {
            steps {
                echo '🏗️ Creating/Updating S3 and CloudFront via Terraform...'
                withCredentials([usernamePassword(
                    credentialsId: 'aws-s3-deploy-creds',
                    usernameVariable: 'AWS_ACCESS_KEY_ID',
                    passwordVariable: 'AWS_SECRET_ACCESS_KEY'
                )]) {
                    dir('terraform') {
                        bat """
                        set AWS_ACCESS_KEY_ID=%AWS_ACCESS_KEY_ID%
                        set AWS_SECRET_ACCESS_KEY=%AWS_SECRET_ACCESS_KEY%
                        "%TERRAFORM%" init
                        "%TERRAFORM%" apply -auto-approve
                        """
                    }
                }
            }
        }

        stage('Upload Website to S3') {
            steps {
                echo '🚀 Uploading static website files to S3...'
                withCredentials([usernamePassword(
                    credentialsId: 'aws-s3-deploy-creds',
                    usernameVariable: 'AWS_ACCESS_KEY_ID',
                    passwordVariable: 'AWS_SECRET_ACCESS_KEY'
                )]) {
                    dir('website') {
                        bat """
                        set AWS_ACCESS_KEY_ID=%AWS_ACCESS_KEY_ID%
                        set AWS_SECRET_ACCESS_KEY=%AWS_SECRET_ACCESS_KEY%
                        "%AWS_CLI%" s3 sync . s3://%S3_BUCKET% --delete --region %AWS_REGION%
                        """
                    }
                }
            }
        }

        stage('Invalidate CloudFront Cache') {
    steps {
        echo '🌐 Invalidating CloudFront cache for updated files...'
        withCredentials([usernamePassword(
            credentialsId: 'aws-s3-deploy-creds',
            usernameVariable: 'AWS_ACCESS_KEY_ID',
            passwordVariable: 'AWS_SECRET_ACCESS_KEY'
        )]) {
            dir('terraform') {
                bat """
                set AWS_ACCESS_KEY_ID=%AWS_ACCESS_KEY_ID%
                set AWS_SECRET_ACCESS_KEY=%AWS_SECRET_ACCESS_KEY%
                
                REM Get CloudFront domain from Terraform outputs
                "%TERRAFORM%" output -json > tf_output.json

                REM Extract domain name
                for /f "tokens=* usebackq" %%i in (`powershell -Command "(Get-Content tf_output.json | ConvertFrom-Json).cloudfront_domain.value"`) do set CLOUDFRONT_DOMAIN=%%i
                
                echo CloudFront Domain: %CLOUDFRONT_DOMAIN%

                REM Get Distribution ID safely
                for /f "delims=" %%d in ('"%AWS_CLI%" cloudfront list-distributions --query "DistributionList.Items[?DomainName==''%CLOUDFRONT_DOMAIN%''].Id" --output text') do set DIST_ID=%%d
                
                echo CloudFront Distribution ID: %DIST_ID%
                
                if "%DIST_ID%"=="" (
                    echo ❌ Could not find CloudFront Distribution ID for domain %CLOUDFRONT_DOMAIN%
                    exit /b 1
                ) else (
                    echo ✅ Creating CloudFront invalidation...
                    "%AWS_CLI%" cloudfront create-invalidation --distribution-id %DIST_ID% --paths "/*" --region %AWS_REGION%
                )
                """
            }
        }
    }
}

    }

    post {
    success {
        echo '✅ Portfolio successfully deployed to AWS S3 + CloudFront!'
        bat """
        "%TERRAFORM%" output -raw cloudfront_domain
        """
    }
    failure {
        echo '❌ Deployment failed! Check Jenkins logs for details.'
    }
}

}
