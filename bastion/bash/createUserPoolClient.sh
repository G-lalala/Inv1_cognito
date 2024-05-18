  aws cognito-idp create-user-pool-client \
    --client-name MyUserPoolClient \
    --user-pool-id ${USER_POOL_ID} \
    --generate-secret \
    --query "[UserPoolClient.ClientId, UserPoolClient.ExplicitAuthFlows]" \
    --output text \
    --endpoint-url ${ENDPOINT_URL} \
    --explicit-auth-flows "ADMIN_USER_PASSWORD_AUTH"