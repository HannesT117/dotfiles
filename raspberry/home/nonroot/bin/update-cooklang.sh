mkdir ~/tmp && cd $_

wget https://github.com/cooklang/cookcli/releases/latest/download/cook-arm-unknown-linux-musleabihf.tar.gz
tar -xzf cook-arm-unknown-linux-musleabihf.tar.gz
mv cook ~/dotfiles/raspberry/home/nonroot/bin/

systemctl --user restart cooklang.service

rm -r ~/tmp
