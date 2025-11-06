# Lightweight image for static website build
FROM alpine:3.18

RUN apk add --no-cache aws-cli

WORKDIR /app
COPY website/ /app/

CMD ["sh", "-c", "aws s3 sync . s3://$S3_BUCKET_NAME --delete --region $AWS_REGION"]
