FROM archlinux/base
MAINTAINER yantene <contact@yantene.net>

# 必要最低限のパッケージインストール
RUN \
  pacman -Syy --noconfirm;\
  pacman -S --noconfirm base-devel git go wget zsh

# ユーザ作成
RUN \
  useradd -m -g users -G wheel user;\
  echo 'user:P455w0rd' | /usr/bin/chpasswd
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

# 普段の作業に必要なパッケージのインストール
RUN pacman -S --noconfirm \
  neovim python-neovim \
  hub tmux skim ripgrep \
  dropbear
RUN \
  cd `sudo -u user mktemp -d`;\
  curl -L https://aur.archlinux.org/cgit/aur.git/snapshot/peco.tar.gz | sudo -u user tar zxf - --strip=1;\
  sudo -u user makepkg --noconfirm;\
  pacman -U --noconfirm ./peco*.pkg.tar.xz

# ユーザから特権を剥奪する
RUN rm /etc/sudoers.d/temp

# システム設定
RUN \
  sed -i 's/^#\(ja_JP.UTF-8 UTF-8.*\)$/\1/g' /etc/locale.gen;\
  sed -i 's/^#\(en_US.UTF-8 UTF-8.*\)$/\1/g' /etc/locale.gen;\
  echo 'LANG=ja_JP.UTF-8' > /etc/locale.conf;\
  locale-gen
RUN ln -sf /usr/share/zoneinfo/Asia/Tokyo /etc/localtime

# 作業環境構築
RUN chsh -s /bin/zsh user
RUN rm -f /home/user/.bash*
RUN \
  sudo -u user git clone https://github.com/yantene/config /home/user/.config;\
  sudo -u user ln -s /home/user/.config/zsh/.zshenv /home/user/.zshenv

EXPOSE 22
ENTRYPOINT ["/usr/bin/dropbear", "-F", "-P", "/run/dropbear.pid", "-R"]
