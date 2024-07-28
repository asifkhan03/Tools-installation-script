##Install in Amazon Ubuntu
#!binbash
sudo apt update -y

sudo apt install apt-transport-https ca-certificates curl software-properties-common -y

curl -fsSL httpsdownload.docker.comlinuxubuntugpg  sudo apt-key add -

sudo add-apt-repository deb [arch=amd64] httpsdownload.docker.comlinuxubuntu bionic stable -y

sudo apt update -y

apt-cache policy docker-ce -y

sudo apt install docker-ce -y

#sudo systemctl status docker

sudo chmod 777 varrundocker.sock