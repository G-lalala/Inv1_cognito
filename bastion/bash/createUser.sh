aws cognito-idp admin-create-user \
  --user-pool-id ${USER_POOL_ID} \
  --username ${COGNITO_USER_EMAIL} \
  --message-action SUPPRESS \
  --desired-delivery-mediums EMAIL \
  --endpoint-url ${ENDPOINT_URL} \
  --user-attributes \
    Name=email,Value=${COGNITO_USER_EMAIL} \
    Name=email_verified,Value=true