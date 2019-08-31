FROM ubuntu:16.04

RUN export DEBIAN_FRONTEND=noninteractive \
    && apt-get update && apt-get -y dist-upgrade \
    && apt-get -y install git libffi-dev libsasl2-dev python-dev \
        sudo libldap2-dev libssl-dev python-pip python-setuptools \
        mysql-client uwsgi uwsgi-plugin-python virtualenv nginx \ 
    && rm -rf /var/cache/apt/archives/*

RUN useradd -m -s /bin/bash oncall

COPY src /home/oncall/source/src
COPY setup.py /home/oncall/source/setup.py
COPY MANIFEST.in /home/oncall/source/MANIFEST.in

WORKDIR /home/oncall

RUN chown -R oncall:oncall /home/oncall/source /var/log/nginx /var/lib/nginx \
    && sudo -Hu oncall mkdir -p /home/oncall/var/log/uwsgi /home/oncall/var/log/nginx /home/oncall/var/run /home/oncall/var/relay \
    && sudo -Hu oncall virtualenv /home/oncall/env \
    && sudo -Hu oncall /bin/bash -c 'source /home/oncall/env/bin/activate && cd /home/oncall/source && pip install .'

RUN sudo -Hu oncall virtualenv /home/oncall/env \
    && sudo -Hu oncall /bin/bash -c 'git clone https://github.com/phamvuong/oncall-admin.git /home/oncall/oncall-admin && \
    source /home/oncall/env/bin/activate && cd /home/oncall/oncall-admin && pip install .'

COPY . /home/oncall
COPY ops/config/systemd /etc/systemd/system
COPY ops/daemons /home/oncall/daemons
COPY ops/daemons/uwsgi-docker.yaml /home/oncall/daemons/uwsgi.yaml
COPY db /home/oncall/db
COPY configs /home/oncall/config
COPY ops/entrypoint.py /home/oncall/entrypoint.py

EXPOSE 8080
EXPOSE 16652

CMD ["sudo", "-EHu", "oncall", "bash", "-c", "source /home/oncall/env/bin/activate && python /home/oncall/entrypoint.py && make -C /home/oncall/oncall-admin/"]
