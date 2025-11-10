pipeline {
  agent any

  environment {
    AWS_REGION = "us-east-1"
    S3_BUCKET  = "jagvi-portfolio-site"
  }

  stages {

    stage('Checkout') {
      steps {
        echo "📦 Cloning Portfolio Repository..."
        git branch: 'main', url: 'https://github.com/vJagvi/PortfolioWebsite.git'
      }
    }

    stage('Terraform Init & Apply') {
      steps {
        echo "🏗️ Running Terraform inside its container..."
        withCredentials([usernamePassword(
          credentialsId: 'aws-s3-deploy-creds',
          usernameVariable: 'AWS_ACCESS_KEY_ID',
          passwordVariable: 'AWS_SECRET_ACCESS_KEY'
        )]) {
          sh '''
            echo ➡️ Executing Terraform in container...
            docker exec \
              -e AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID} \
              -e AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY} \
              -e AWS_REGION=${AWS_REGION} \
              terraform sh -c "
                cd /workspace
                terraform init -input=false
                terraform apply -auto-approve -input=false
              "
          '''
        }
      }
    }

    stage('Upload Website to S3') {
      steps {
        echo "☁️ Uploading static website files using AWS CLI container..."
        withCredentials([usernamePassword(
          credentialsId: 'aws-s3-deploy-creds',
          usernameVariable: 'AWS_ACCESS_KEY_ID',
          passwordVariable: 'AWS_SECRET_ACCESS_KEY'
        )]) {
          sh '''
            echo ➡️ Syncing website folder to S3...
            docker exec \
              -e AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID} \
              -e AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY} \
              -e AWS_REGION=${AWS_REGION} \
              awscli sh -c "
                cd /workspace
                aws s3 sync . s3://${S3_BUCKET} --delete --region ${AWS_REGION}
              "
          '''
        }
      }
    }

            stage('Invalidate CloudFront Cache') {
      steps {
        echo "🌀 Invalidating CloudFront cache..."
        withCredentials([usernamePassword(
          credentialsId: 'aws-s3-deploy-creds',
          usernameVariable: 'AWS_ACCESS_KEY_ID',
          passwordVariable: 'AWS_SECRET_ACCESS_KEY'
        )]) {
          sh '''
            echo ➡️ Fetching CloudFront domain from Terraform outputs...
            CLOUDFRONT_DOMAIN=$(docker exec terraform terraform output -raw cloudfront_domain)
            echo "🌍 CloudFront Domain: $CLOUDFRONT_DOMAIN"

            echo 🔍 Fetching Distribution ID inside awscli container...
            DIST_ID=$(docker exec \
              -e AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID} \
              -e AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY} \
              -e AWS_REGION=${AWS_REGION} \
              awscli sh -c "
                aws cloudfront list-distributions \
                  --query 'DistributionList.Items[?DomainName==\\\"'${CLOUDFRONT_DOMAIN}'\\\"].Id' \
                  --output text
              ")

            if [ -z "$DIST_ID" ] || [ "$DIST_ID" = "None" ]; then
              echo "❌ Could not find CloudFront Distribution for domain $CLOUDFRONT_DOMAIN"
              exit 1
            fi

            echo "✅ Found Distribution ID: $DIST_ID"
            docker exec \
              -e AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID} \
              -e AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY} \
              -e AWS_REGION=${AWS_REGION} \
              awscli sh -c "
                aws cloudfront create-invalidation \
                  --distribution-id $DIST_ID \
                  --paths '/*' \
                  --region ${AWS_REGION}
              "
          '''
        }
      }
    }

  }

  post {
    success {
      echo "✅ Portfolio successfully deployed to AWS S3 + CloudFront!"
    }
    failure {
      echo "❌ Deployment failed. Check Jenkins logs for details."
    }
  }
}
