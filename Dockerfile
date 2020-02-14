FROM archlinux/base
MAINTAINER yantene <contact@yantene.net>

# 必要最低限のパッケージインストール
RUN \
  pacman -Syy --noconfirm;\
  pacman -S --noconfirm base base-devel git go wget zsh

# ユーザ作成
RUN \
  useradd -m -g users -G wheel user;\
  echo 'user:password' | /usr/bin/chpasswd
RUN \
  echo '%wheel ALL=(ALL) ALL' > /etc/sudoers.d/wheel;\
  chmod 0440 /etc/sudoers.d/wheel

# ユーザに一時的に特権を与える
RUN \
  echo "user ALL=(ALL) ALL" > /etc/sudoers.d/temp;\
  chmod 0440 /etc/sudoers.d/temp

# yay のインストール
RUN \
  cd `sudo -u user mktemp -d`;\
  curl -L https://aur.archlinux.org/cgit/aur.git/snapshot/yay.tar.gz | sudo -u user tar zxf - --strip=1;\
  sudo -u user makepkg --noconfirm;\
  pacman -U --noconfirm ./yay*.pkg.tar.xz

# パッケージのインストール
RUN pacman -S --noconfirm \
  zsh-syntax-highlighting neovim python-neovim \
  hub tmux skim ripgrep exa bat \
  man-pages man-db htop \
  rsync whois dnsutils bind-tools lsof yarn \
  dropbear
RUN for pkgname in anyenv direnv ghq man-pages-ja; do\
    tmpdir=`sudo -u user mktemp -d`;\
    cd ${tmpdir};\
    curl -L https://aur.archlinux.org/cgit/aur.git/snapshot/${pkgname}.tar.gz | sudo -u user tar zxf - --strip=1;\
    sudo -u user makepkg --noconfirm;\
    pacman -U --noconfirm ./${pkgname}*.pkg.tar.xz;\
    rm -rf ${tmpdir};\
  done

# ユーザから特権を剥奪する
RUN rm /etc/sudoers.d/temp

# システム設定
RUN \
  echo 'ja_JP.UTF-8 UTF-8' > /etc/locale.gen;\
  echo 'en_US.UTF-8 UTF-8' >> /etc/locale.gen;\
  echo 'LANG=ja_JP.UTF-8' > /etc/locale.conf;\
  locale-gen
RUN ln -sf /usr/share/zoneinfo/Asia/Tokyo /etc/localtime
RUN sed -i 's/^#Color$/Color/' /etc/pacman.conf

# 作業環境構築
RUN chsh -s /bin/zsh user
RUN rm -f /home/user/.bash*
RUN \
  sudo -u user git clone https://github.com/yantene/config /home/user/.config;\
  sudo -u user ln -s /home/user/.config/zsh/.zshenv /home/user/.zshenv

# /home/user のアーカイブ作成 (ボリュームマウント時用)
RUN tar zcf /opt/home.tgz -C /home/user .config .zshenv

EXPOSE 22
ENTRYPOINT ["/usr/bin/dropbear", "-F", "-P", "/run/dropbear.pid", "-R"]

# e.g.
# docker run -d -p 2222:22 -v `pwd`:/mnt yantene/sandbox
# ssh -o 'StrictHostKeyChecking=no' -o 'UserKnownHostsFile=/dev/null' user@localhost -p 2222 # password: password
