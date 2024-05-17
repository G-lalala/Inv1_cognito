  aws cognito-idp create-user-pool \
    --pool-name MyUserPool \
    --alias-attributes "email" \
    --username-attributes "email" \
    --query UserPool.Id \
    --output text \
    --endpoint-url ${ENDPOINT_URL} \
    --schema \
        Name=email,Required=true