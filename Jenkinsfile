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
                set PATH=%PATH%;"C:\\Program Files\\Amazon\\AWSCLIV2\\"

                echo 🔍 Getting CloudFront domain from Terraform outputs...
                "%TERRAFORM%" output -raw cloudfront_domain > domain.txt

                for /F "tokens=* delims=" %%A in (domain.txt) do set CLOUDFRONT_DOMAIN=%%A
                echo Found CloudFront domain: %CLOUDFRONT_DOMAIN%

                echo 🔍 Getting Distribution ID from AWS CloudFront...
                powershell -Command "$env:AWS_ACCESS_KEY_ID='%AWS_ACCESS_KEY_ID%'; $env:AWS_SECRET_ACCESS_KEY='%AWS_SECRET_ACCESS_KEY%'; $domain='%CLOUDFRONT_DOMAIN%'; $distId=(aws cloudfront list-distributions --query \\"DistributionList.Items[?DomainName=='$domain'].Id\\" --output text); if ($distId -eq '') { Write-Host '❌ Could not find CloudFront Distribution ID'; exit 1 } else { Write-Host '✅ Found Distribution ID:' $distId; aws cloudfront create-invalidation --distribution-id $distId --paths '/*' --region %REGION%; }"
                """
            }
        }
    }
}
