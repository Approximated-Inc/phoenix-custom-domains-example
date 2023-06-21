FROM gitpod/workspace-full:latest
# Docker build does not rebuild an image when a base image is changed, increase this counter to trigger it.
ENV TRIGGER_REBUILD=2
# Install PostgreSQL
RUN wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
RUN echo "deb http://apt.postgresql.org/pub/repos/apt/ `lsb_release -cs`-pgdg main" |sudo tee  /etc/apt/sources.list.d/pgdg.list
RUN sudo install-packages postgresql-13 postgresql-client-13

# Setup PostgreSQL server for user gitpod
ENV PATH="$PATH:/usr/lib/postgresql/13/bin"
ENV PGDATA="/workspace/.pgsql/data"
RUN mkdir -p ~/.pg_ctl/bin ~/.pg_ctl/sockets \
 && printf '#!/bin/bash\n[ ! -d $PGDATA ] && mkdir -p $PGDATA && initdb -D $PGDATA\npg_ctl -D $PGDATA -l ~/.pg_ctl/log -o "-k ~/.pg_ctl/sockets" start\n' > ~/.pg_ctl/bin/pg_start \
 && printf '#!/bin/bash\npg_ctl -D $PGDATA -l ~/.pg_ctl/log -o "-k ~/.pg_ctl/sockets" stop\n' > ~/.pg_ctl/bin/pg_stop \
 && chmod +x ~/.pg_ctl/bin/*
ENV PATH="$PATH:$HOME/.pg_ctl/bin"
ENV DATABASE_URL="postgresql://gitpod@localhost"
ENV PGHOSTADDR="127.0.0.1"
ENV PGDATABASE="postgres"

# This is a bit of a hack. At the moment we have no means of starting background
# tasks from a Dockerfile. This workaround checks, on each bashrc eval, if the
# PostgreSQL server is running, and if not starts it.
RUN printf "\n# Auto-start PostgreSQL server.\n[[ \$(pg_ctl status | grep PID) ]] || pg_start > /dev/null\n" >> ~/.bashrc

ENV DEBIAN_FRONTEND noninteractive

# for building erlang - not really needed using pre-compile erlang binaries (see below)
ENV KERL_CONFIGURE_OPTIONS="--disable-debug --without-javac"

# Install deps
RUN set -ex; \
    sudo apt-get update; \
    sudo apt-get -y install curl build-essential autoconf m4 inotify-tools gpg dirmngr gawk; \
    sudo apt-get clean; \
    sudo rm -rf /var/cache/apt/*; \
    sudo rm -rf /var/lib/apt/lists/*; \
    sudo rm -rf /tmp/*

# remove nvm and manage node via asdf
RUN set -ex; \
    rm -rf ~/.nvm; \
    rm ~/.bashrc.d/50-node; \
    git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch v0.8.1; \
    echo ". $HOME/.asdf/asdf.sh" >> $HOME/.bashrc; \
    echo ". $HOME/.asdf/completions/asdf.bash"  >> $HOME/.bashrc; \
    mkdir -p $HOME/.config/fish && echo "source ~/.asdf/asdf.fish" >> ~/.config/fish/config.fish; \
    mkdir -p $HOME/.config/fish/completions && ln -s $HOME/.asdf/completions/asdf.fish ~/.config/fish/completions; \
    echo ". $HOME/.asdf/asdf.sh" >> ~/.zshrc; \
    echo "fpath=(${ASDF_DIR}/completions $fpath)" >> ~/.zshrc; \
    echo "autoload -Uz compinit && compinit" >> ~/.zshrc;



# use erlang plugin fork to get pre-compiled binaries
#   - see: https://github.com/michallepicki/asdf-erlang-prebuilt-ubuntu-22.04
# install plugins and latest major version of erlang and elixir to save time in before stage of gitpod.yml
#   - these may be overruled by .tool-versions in before step of gitpod.yml
# run this inside of bash to make asdf available
RUN set -ex; \
    bash -c "set -ex; \
    . $HOME/.asdf/asdf.sh; \
    asdf plugin-add erlang https://github.com/michallepicki/asdf-erlang-prebuilt-ubuntu-22.04.git; \
    asdf plugin-add elixir https://github.com/asdf-vm/asdf-elixir.git; \
    asdf plugin add nodejs https://github.com/asdf-vm/asdf-nodejs.git; \
    asdf install erlang 25.3; \
    asdf install elixir 1.15.0-otp-25; \
    asdf install nodejs 14.17.6;"
