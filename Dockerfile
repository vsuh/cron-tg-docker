FROM python:3-slim


EXPOSE 7800

ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    WORKDIR="/workspaces/cron-tg-docker" \
    TMPARC="/tmp/app.tgz" \
    TAG="v1.3.13"


WORKDIR ${WORKDIR}

#ADD --checksum=sha256:d8724a09c2f6d08bc1bcf072a05c9e45b87d43db940c3d90e6aefc4ed60525de https://github.com/vsuh/reminder-tgm/archive/refs/tags/v1.0.1.tar.gz ${TMPARC}
ADD https://github.com/vsuh/reminder-tgm/archive/refs/tags/${TAG}.tar.gz ${TMPARC} 
RUN tar xzf ${TMPARC} --strip-components=1 -C ${WORKDIR} && rm ${TMPARC}

RUN python3 -m venv venv && . ./venv/bin/activate 
RUN pip install --root-user-action ignore -q --upgrade pip && pip install --root-user-action ignore -q -r requirements.txt


RUN adduser -u 5678 --disabled-password --gecos "" appuser && chown -R appuser /workspaces
USER appuser

# Создаем необходимые директории и устанавливаем права
RUN mkdir -p log db && \
    chown -R appuser:appuser log db && \
    chmod 755 log db

# Делаем скрипты исполняемыми
RUN chmod +x web_prod.sh rund_prod.sh start.sh

RUN ls -la

CMD ["./start.sh"]

