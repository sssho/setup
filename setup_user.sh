#!/bin/bash

install_local_python() {
    local installdir=$1
    local version=$2

    local srcdir="${installdir}/src"
    local pythondir="${installdir}/python/$version"
    local target="$pythondir/bin/python3"

    [ -x "$target" ] && {
        echo "$target already installed"
        return 0
    }

    [ -d "$srcdir" ] || mkdir -p "$srcdir"
    cd "$srcdir" || return 1

    wget "https://www.python.org/ftp/python/$version/Python-$version.tgz"
    tar -xf "Python-$version.tgz"
    cd "./Python-$version" || return 1

    [ -d "$pythondir" ] || mkdir -p "$pythondir"
    ./configure --prefix="$pythondir"
    make && make install

    [ -x "$target" ] || return 1

    "$pythondir"/bin/pip3 install --upgrade pip
    "$pythondir"/bin/pip3 install virtualenv
}

setup_py_virtualenv() {
    local pythondir=$1
    local version=$2
    local venvname=$3

    local venvbin="$pythondir/$version/bin/virtualenv"

    [ -x "$venvbin" ] || {
        echo "$venvbin not found"
        return 1
    }

    # Create main venv
    local venv="$pythondir/$venvname"

    [ -d "$venv" ] && { echo "$venv already exists", return 0; }

    $venvbin "$venv" || {
        echo "$venv failed"
        return 1
    }

    # Install basic plugins
    "$venv/bin/pip3" install flake8 flake8-isort flake8-docstrings black pytest isort pylint mypy ipython

    local confdir="$HOME/.config/$USER"
    [ -d "$confdir" ] || mkdir -p "$confdir"

    local pyenvfile="$confdir/pyenvs"
    grep "$venv/bin/activate" "$pyenvfile" >&/dev/null || echo "$venv/bin/activate" >>"$pyenvfile"
}

install_local_go() {
    local installdir=$1

    local srcdir="${installdir}/src"
    local target="${installdir}/go/bin/go"

    [ -x "$target" ] && {
        echo "$target already installed"
        return 0
    }

    [ -d "$srcdir" ] || mkdir -p "$srcdir"

    wget -P "$srcdir" https://dl.google.com/go/go1.13.7.linux-amd64.tar.gz
    tar -C "$installdir" -xzf "${srcdir}/go1.13.7.linux-amd64.tar.gz"

    [ -x "$target" ] || return 1

    "$target" get golang.org/x/tools/cmd/goimports
    "$target" get -u golang.org/x/lint/golint
    GO111MODULE=on "$target" get mvdan.cc/sh/v3/cmd/shfmt
}

# Install rust and fd, ripgrep
install_local_rust() {
    local installdir=$1

    local srcdir="${installdir}/src"
    local target="${installdir}/bin/cargo"

    [ -x "$target" ] && {
        echo "$target already installed"
        return 0
    }

    [ -d "$srcdir" ] || mkdir -p "$srcdir"
    cd "$srcdir" || return 1

    wget https://static.rust-lang.org/dist/rust-1.41.0-x86_64-unknown-linux-gnu.tar.gz
    tar zxf rust-1.41.0-x86_64-unknown-linux-gnu.tar.gz
    cd ./rust-1.41.0-x86_64-unknown-linux-gnu || return 1
    ./install.sh --prefix="$installdir" --disable-ldconfig

    [ -x "$target" ] || return 1

    cargo install --root "$installdir" fd-find
    cargo install --root "$installdir" ripgrep
    cargo install --root "$installdir" bat
}

install_local_shellcheck() {
    local installdir=$1

    local srcdir="${installdir}/src"
    local bindir="${installdir}/bin"
    local target="${bindir}/shellcheck"

    [ -x "$target" ] && {
        echo "$target already installed"
        return 0
    }

    [ -d "$srcdir" ] || mkdir -p "$srcdir"
    cd "$srcdir" || return 1

    wget https://storage.googleapis.com/shellcheck/shellcheck-stable.linux.x86_64.tar.xz
    tar xf shellcheck-stable.linux.x86_64.tar.xz

    [ -d "$bindir" ] || mkdir -p "$bindir"
    cp ./shellcheck-stable/shellcheck "$bindir"

    [ -x "$target" ] || return 1
}

install_local_fzf() {
    local installdir="$1"/fzf
    local target="$installdir"/bin/fzf

    [ -x "$target" ] && {
        echo "$target already installed"
        return 0
    }

    [ -d "$installdir" ] && {
        echo "$installdir already exists"
        return 0
    }

    git clone --depth 1 https://github.com/junegunn/fzf.git -b 0.22.0 "$installdir"
    # XDG_CONFIG_HOME=~/.config "$installdir"/install --xdg --key-bindings --completion --no-update-rc
    "$installdir"/install --bin

    [ -x "$target" ] || return 1
}

install_local_vim() {
    local installdir=$1
    local pydir=$2

    local srcdir="${installdir}/src"
    local target="${installdir}/bin/vim"

    [ -x "$target" ] && {
        echo "$target already installed"
        return 0
    }

    [ -d "$srcdir" ] || mkdir -p "$srcdir"
    cd "$srcdir" || return 1

    local pybindir="${pydir}/bin"
    local pylibdir="${pydir}/lib"
    local pyconfdir="${pylibdir}/python3.6/config-3.6m-x86_64-linux-gnu"

    for d in "$installdir" "$pydir" "$pybindir" "$pylibdir" "$pyconfdir"; do
        if [ ! -e "$d" ]; then
            echo "$d not found"
            return 1
        fi
    done

    wget https://github.com/vim/vim/archive/v8.2.0241.tar.gz
    tar xf v8.2.0241.tar.gz
    cd vim-8.2.0241 || return 1

    # configure
    # --with-x, --enable-gui: to enable clipboard, clientserver
    # --enable-python3interp, --with-python3-config-dir: to enable python3
    PATH="${pybindir}:$PATH" \
        LDFLAGS="-L${pylibdir} -Xlinker -export-dynamic" \
        ./configure --prefix="$installdir" \
        --enable-fail-if-missing \
        --with-x \
        --enable-gui=auto \
        --enable-python3interp=yes \
        --with-python3-config-dir="$pyconfdir"

    make && make install

    [ -x "$target" ] || return 1
}

install_local_zplug() {
    local target="$1"/zplug

    [ -d "$target" ] && {
        echo "$target already installed"
        return 0
    }

    curl -sL --proto-redir -all,https https://raw.githubusercontent.com/zplug/installer/master/installer.zsh | ZPLUG_HOME="$target" zsh

    [ -d "$target" ] || return 1
}

install_local_vimplug() {
    local target="$HOME/.vim/autoload/plug.vim"

    [ -e "$target" ] && {
        echo "$target already installed"
        return 0
    }

    curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
        https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

    [ -e "$target" ] || return 1
}

install_local_ctags() {
    local installdir=$1

    local srcdir="${installdir}/src"
    local target="${installdir}/bin/ctags"

    [ -x "$target" ] && {
        echo "$target already installed"
        return 0
    }

    [ -d "$srcdir" ] || mkdir -p "$srcdir"
    cd "$srcdir" || return 1

    # Install jansson to enable ctags json feature
    wget http://www.digip.org/jansson/releases/jansson-2.12.tar.gz
    tar xf jansson-2.12.tar.gz

    (
        cd jansson-2.12 || return 1

        ./configure --prefix="$installdir"
        make && make install
    ) || return 1

    git clone https://github.com/universal-ctags/ctags.git --depth=1
    cd ./ctags || return 1

    ./autogen.sh
    JANSSON_CFLAGS=-I"$installdir/include" JANSSON_LIBS="-Wl,-rpath,$installdir/lib -L$installdir/lib -ljansson" ./configure --prefix="$installdir"
    make && make install

    [ -x "$target" ] || return 1
}

install_local_gtags() {
    local installdir=$1

    local srcdir="${installdir}/src"
    local target="${installdir}/bin/gtags"

    [ -x "$target" ] && {
        echo "$target already installed"
        return 0
    }

    [ -d "$srcdir" ] || mkdir -p "$srcdir"
    cd "$srcdir" || return 1

    wget http://tamacom.com/global/global-6.6.4.tar.gz
    tar zxf global-6.6.4.tar.gz

    cd ./global-6.6.4 || return 1

    local ctagsbin="$installdir/bin/ctags"

    [ -x "$ctagsbin" ] || {
        echo "$ctagsbin not found."
        return 1
    }

    ./configure --prefix="$installdir" --with-universal-ctags="$ctagsbin"
    make && make install

    [ -x "$target" ] || return 1
}

install_local_colordiff() {
    local installdir=$1
    local srcdir="$1"/src

    [ -d "$srcdir" ] || mkdir -p "$srcdir"
    cd "$srcdir" || return 1

    wget https://www.colordiff.org/colordiff-1.0.19.tar.gz
    tar xf colordiff-1.0.19.tar.gz
    cd colordiff-1.0.19 || return 1

    make install INSTALL_DIR="$installdir"/bin MAN_DIR="$installdir"/man/man1 ETC_DIR="$installdir"/etc/colordiff || return 1
}

readonly localdir="${HOME}/local"
readonly pyversion="3.6.10"

export PATH="$localdir/bin:$PATH"

install_local_python "$localdir" "$pyversion" || {
    echo "python install failed"
    exit 1
}

setup_py_virtualenv "$localdir/python" "$pyversion" "${pyversion}-main" || {
    echo "venv setup failed"
    exit 1
}

install_local_go "$localdir" || {
    echo "go install failed"
    exit 1
}

install_local_rust "$localdir" || {
    echo "rust install failed"
    exit 1
}

install_local_fzf "$localdir" || {
    echo "fzf install failed"
    exit 1
}

install_local_vim "$localdir" "$localdir/python/$pyversion" || {
    echo "vim install failed"
    exit 1
}

install_local_vimplug || {
    echo "vimplug install failed"
    exit 1
}

install_local_zplug "$localdir" || {
    echo "zplug install failed"
    exit 1
}

install_local_ctags "$localdir" || {
    echo "ctags install failed"
    exit 1
}

install_local_gtags "$localdir" || {
    echo "gtags install failed"
    exit 1
}

install_local_shellcheck "$localdir" || {
    echo "shellcheck install failed"
    exit 1
}

install_local_colordiff "$localdir" || {
    echo "colordiff install failed"
    exit 1
}
