docker run -d \
  --name sap-keeplive \
  -e EMAIL="你的邮箱 邮箱2" \
  -e PASSWORD="你的密码 密码2" \
  -e TIME=8:30 \   #重启时间                                                                                                                                                                                           
  ghcr.io/evecus/keeplive:main
