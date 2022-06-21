FROM centos:centos8

# Передаём id пользователя в систему:

ENV USER_ID=1000

# Переключаюсь на суперпользователя:

USER root

# Устанавливаю рабочий каталог и копирую все нужные файлы:

WORKDIR /tmp
COPY ./sources .

# Создаю пользователя с тем же UID, что и в системе:

RUN groupadd user && useradd --create-home user -g user && \
    sed -i "s/user:x:1000:1000/user:x:${USER_ID}:${USER_ID}/g" /etc/passwd && \
    cp systemctlpatch/systemctl.py /usr/bin/systemctl

# Обновляю список репозиториев

RUN cd /etc/yum.repos.d/ && sed -i 's/mirrorlist/#mirrorlist/g' /etc/yum.repos.d/CentOS-* && \
    sed -i 's|#baseurl=http://mirror.centos.org|baseurl=http://vault.centos.org|g' /etc/yum.repos.d/CentOS-*


# Устанавливаю весь необходимый софт:

RUN yum update -y && yum install boost-devel \
    lsb gcc-c++ wget automake autoconf unzip \
    sqlite-devel mc nano php-devel libxml2-devel

# Устанавливаю php-devel 7.4.30:

# Устанавливаю КриптоПРО:

RUN chmod a+x /usr/bin/systemctl && cd /tmp/linux-amd64_rpm && chmod +x install.sh && ./install.sh && \
    rpm -i lsb-cprocsp-devel-5.0.12500-6.noarch.rpm && cd /tmp/cades_linux && \
    rpm -i cprocsp-pki-phpcades-64-2.0.14589-1.amd64.rpm && rpm -i cprocsp-pki-cades-64-2.0.14589-1.amd64.rpm && \
    cp /tmp/php7_sources/php-7.2.24.tar.gz /opt && cd /opt && tar -xvzf php-7.2.24.tar.gz && mv php-7.2.24 php && \
    rm /opt/php-7.2.24.tar.gz && cd /opt/php/ && ./configure --prefix=/opt/php --enable-fpm && \
    rm /opt/cprocsp/src/phpcades/Makefile.unix && cp /tmp/Makefile.unix /opt/cprocsp/src/phpcades/ && \
    ##### update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-6 10 && \
    cp /tmp/php7_support.patch/php7_support.patch /opt/cprocsp/src/phpcades && \
    cd /opt/cprocsp/src/phpcades && patch -p0 < ./php7_support.patch && \
    eval `/opt/cprocsp/src/doxygen/CSP/../setenv.sh --64` && make -f Makefile.unix && \
    cp /opt/cprocsp/src/phpcades/libphpcades.so $(php -i | grep 'extension_dir => ' | awk '{print $3}')/phpcades.so && \
    ln -s /opt/cprocsp/src/phpcades/libphpcades.so $(php -i | grep 'extension_dir => ' | awk '{print $3}')/libcppcades.so && \
    #echo 'extension=phpcades.so' >> /etc/php/7.4/cli/php.ini && cd /tmp/php7_sources && \
    #echo 'error_log=/var/log/phpfpm_errors.log' >> /etc/php/7.4/cli/php.ini && \
    #rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* && service php7.4-fpm start

# Переключаюсь на созданного пользователя и открываю рабочий порт:

USER user

EXPOSE 8888

# CMD ["php-fpm"]
