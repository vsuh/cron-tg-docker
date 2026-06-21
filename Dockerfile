FROM python:3-slim

ARG TAG=v1.6.3

EXPOSE 7999

ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    WORKDIR="/workspaces/cron-tg-docker" \
    TMPARC="/tmp/app.tgz" \
    TAG=${TAG}


WORKDIR ${WORKDIR}


RUN apt-get update \
 && apt-get install -y --no-install-recommends openssh-client \
 && rm -rf /var/lib/apt/lists/*
 
ADD https://github.com/vsuh/reminder-tgm/archive/refs/tags/${TAG}.tar.gz ${TMPARC} 
RUN tar xzf ${TMPARC} --strip-components=1 -C ${WORKDIR} && rm ${TMPARC} && echo "Succ. unpacked repo tag=${TAG}"

RUN python3 -m venv .venv && . ./.venv/bin/activate 
RUN pip install --root-user-action ignore -q --upgrade pip && pip install --root-user-action ignore -q -r requirements.txt


RUN adduser -u 5678 --disabled-password --gecos "" appuser && chown -R appuser /workspaces
USER appuser

RUN mkdir -p log db && \
    chown -R appuser:appuser log db && \
    chmod 755 log db

RUN chmod +x web_prod.sh rund_prod.sh start.sh

RUN ls -la

CMD ["./start.sh"]
