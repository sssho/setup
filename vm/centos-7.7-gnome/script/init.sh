#!/bin/bash

USERNAME=$1
UID=$2

yum -y update
yum -y groupinstall 'Development Tools'
yum -y groupinstall "GNOME Desktop"

# yum -y install epel-release

yum -y install xauth                  # to enable x11forwarding
yum -y install zlib-devel             # pythoh zgip
yum -y install openssl-devel          # python pip
yum -y install readline-devel         # python shell keybind
yum -y install libffi-devel           # python 3.7 ->
yum -y install bzip2-devel            # python
yum -y install sqlite-devel           # python ipython
yum -y install xz-devel               # python
yum -y install ncurses-devel          # zsh, tmux
yum -y install libevent-devel         # tmux
yum-builddep -y vim-X11               # vim (clipboard, clientserver)
yum -y install libXmu-devel           # xclip
yum -y install tree

sed -e 's/#\(PermitRootLogin\) yes/\1 no/' -e 's/#\(PubkeyAuthentication yes\)/\1/' -e 's/#\(AllowAgentForwarding yes\)/\1/' -i /etc/ssh/sshd_config
timedatectl set-timezone Asia/Tokyo

systemctl set-default graphical.target

install_xclip() {
    local installdir="/usr/local"
    local version="0.13"
    local srcname="xclip-${version}"
    local target="${installdir}/bin/xclip"

    [ -x "$target" ] && {
        echo "$target already installed"
        return 0
    }

    cd "$installdir/src" || return 1

    git clone https://github.com/astrand/xclip.git -b "$version" "$srcname"

    cd "./$srcname" || return 1
    autoreconf
    ./configure --prefix="$installdir"
    make && make install

    [ -x "$target" ] || return 1
}

install_zsh() {
    local installdir="/usr/local"
    local version="zsh-5.7.1"
    local target="${installdir}/bin/zsh"

    [ -x "$target" ] && {
        echo "$target already installed"
        return 0
    }

    cd "$installdir/src" || return 1

    git clone https://github.com/zsh-users/zsh.git -b "$version" "$version"
    cd "./$version" || return 1
    ./Util/preconfig
    ./configure --prefix="$installdir" --with-tcsetpgrp
    make && make install

    [ -x "$target" ] || return 1

    if ! grep "$target" /etc/shells >/dev/null; then
        echo "$target" >>/etc/shells
    fi
}

install_tmux() {
    local installdir="/usr/local"
    local target="${installdir}/bin/tmux"

    [ -x "$target" ] && {
        echo "$target already installed"
        return 0
    }

    cd "$installdir/src" || return 1

    wget https://github.com/tmux/tmux/releases/download/3.1b/tmux-3.1b.tar.gz
    tar xf tmux-3.1b.tar.gz
    cd tmux-3.1b || return 1
    ./configure --prefix="$installdir"
    make && make install

    [ -x "$target" ] || return 1
}

install_xclip || {
    echo "zclip install failed"
    exit 1
}

install_zsh || {
    echo "zsh install failed"
    exit 1
}

install_tmux || {
    echo "tmux install failed"
    exit 1
}

useradd "$USERNAME" -u "$UID" -s /usr/local/bin/zsh
echo hoge | passwd "$USERNAME" --stdin

shutdown -r now
