docker run -d \
  --name my-sap-task \
  -e CF_EMAIL="你的邮箱" \
  -e CF_PASSWORD="你的密码" \
  -e CF_URLS="你的URL" \
  ghcr.io/evecus/keeplive:main
