# Шаг 1: Используем современную, легковесную и поддерживаемую версию Debian 11 (Bullseye)
FROM debian:bullseye-slim

# Устанавливаем переменную, чтобы избежать интерактивных диалогов при установке пакетов
ARG DEBIAN_FRONTEND=noninteractive

# Шаг 2: Выполняем все команды установки и очистки в одном слое для оптимизации размера образа
RUN \
    # Обновляем список пакетов
    apt-get update -y && \
    # Устанавливаем базовые зависимости И инструменты для сборки (build-essential, python2-dev)
    apt-get install -y --no-install-recommends \
      ca-certificates jq tor net-tools cron nano mc python2 python-is-python2 supervisor unzip wget \
      build-essential python2-dev libssl-dev \
    && \
    # Устанавливаем PIP для Python 2
    wget https://bootstrap.pypa.io/pip/2.7/get-pip.py -O /tmp/get-pip.py && \
    python2 /tmp/get-pip.py && \
    # --- ИЗМЕНЕНИЕ ЗДЕСЬ ---
    # Устанавливаем доступную СТАРУЮ ВЕРСИЮ пакета apsw из списка, который показала ошибка
    pip2 install apsw==3.9.2.post1 m2crypto==0.35.2 && \
    # --- Теперь идут оригинальные шаги установки AceStream ---
    mkdir -p /mnt/media/playlists && \
    wget -O /tmp/acestream.tar.gz http://dl.acestream.org/linux/acestream_3.1.16_debian_8.7_x86_64.tar.gz && \
    tar --strip-components=1 -C /usr/share -vzxf /tmp/acestream.tar.gz && \
    # --- Финальная очистка ---
    # Удаляем инструменты для сборки, которые больше не нужны, чтобы уменьшить размер образа
    apt-get purge -y --auto-remove build-essential python2-dev libssl-dev && \
    # Очищаем кэш apt и временные файлы
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/*

# Шаг 3: Копируем файлы конфигурации и скрипты в образ
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY ace.hls_parser.sh /mnt/media/playlists/ace.hls_parser.sh
COPY torrc /etc/tor/torrc
COPY start.sh /usr/bin/start.sh

# Шаг 4: Устанавливаем права на выполнение для скриптов
RUN chmod +x /mnt/media/playlists/ace.hls_parser.sh && \
    chmod +x /usr/bin/start.sh

# Открываем порты
EXPOSE 8621 62062 9944 9903 6878
# Указываем, что эта папка может использоваться как том (volume)
VOLUME /mnt/media/playlists
# Устанавливаем рабочую директорию
WORKDIR /
# Шаг 5: Указываем команду, которая будет запускаться при старте контейнера
ENTRYPOINT ["/usr/bin/start.sh"]
