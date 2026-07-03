IP=192.168.56.13
if [ ! -f ~/.ssh/id_rsa ]; then
  ssh-keygen -t rsa
fi
ssh-copy-id -i ~/.ssh/id_rsa.pub $IP
