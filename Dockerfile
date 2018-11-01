FROM base/devel
MAINTAINER yantene <contact@yantene.net>

# ユーザ作成
RUN \
  useradd -m -g users -G wheel username;\
  echo 'username:P455w0rd' | /usr/bin/chpasswd
RUN \
  echo '%wheel ALL=(ALL) ALL' > /etc/sudoers.d/wheel;\
  chmod 0440 /etc/sudoers.d/wheel

# 必要最低限のパッケージインストール
RUN \
  pacman -Syy --noconfirm;\
  pacman -S --noconfirm git go wget zsh tmux

# ユーザに一時的に特権を与える
RUN \
  echo "username ALL=(ALL) ALL" > /etc/sudoers.d/temp;\
  chmod 0440 /etc/sudoers.d/temp

# yay のインストール
RUN \
  cd `sudo -u username mktemp -d`;\
  curl -L https://aur.archlinux.org/cgit/aur.git/snapshot/yay.tar.gz | sudo -u username tar zxf - --strip=1;\
  sudo -u username makepkg --noconfirm;\
  pacman -U --noconfirm ./yay*.pkg.tar.xz

# 普段の作業に必要なパッケージのインストール
RUN pacman -S --noconfirm neovim python-neovim python2-neovim hub tmux the_silver_searcher
RUN \
  cd `sudo -u username mktemp -d`;\
  curl -L https://aur.archlinux.org/cgit/aur.git/snapshot/peco.tar.gz | sudo -u username tar zxf - --strip=1;\
  sudo -u username makepkg --noconfirm;\
  pacman -U --noconfirm ./peco*.pkg.tar.xz

# ユーザから特権を剥奪する
RUN rm /etc/sudoers.d/temp

# 作業環境構築
RUN rm -f /home/username/.bash*
RUN \
  sudo -u username git clone https://github.com/yantene/config /home/username/.config;\
  sudo -u username ln -s /home/username/.config/zsh/.zshenv /home/username/.zshenv
RUN chsh -s /bin/zsh username
RUN \
  sed -i 's/^#\(ja_JP.UTF-8 UTF-8.*\)$/\1/g' /etc/locale.gen;\
  sed -i 's/^#\(en_US.UTF-8 UTF-8.*\)$/\1/g' /etc/locale.gen;\
  echo 'LANG=ja_JP.UTF-8' > /etc/locale.conf;\
  locale-gen
RUN ln -sf /usr/share/zone/info/Asia/Tokyo /etc/localtime

EXPOSE 22
ENTRYPOINT ["/usr/bin/su", "-", "username"]
