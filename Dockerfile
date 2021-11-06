ARG TF_VERSION=1.0.3
ARG PYTHON_VERSION=3.8.6

ARG USER_NAME=vscode
ARG USER_UID=1000
ARG USER_GID=${USER_UID}


FROM hashicorp/terraform:$TF_VERSION AS terraform


FROM python:$PYTHON_VERSION-alpine

RUN pip install -U pip ply \
 && apk add --update --no-cache graphviz ttf-freefont sudo

COPY --from=terraform /bin/terraform /bin/terraform
COPY ./docker-entrypoint.sh /bin/docker-entrypoint.sh

RUN chmod 777 /bin/docker-entrypoint.sh

WORKDIR /src
COPY . .

RUN pip install -e .
RUN echo $(timeout 15 blast-radius --serve --port 5001; test $? -eq 124) > /output.txt

RUN adduser --uid ${USER_UID} --disabled-password ${USER_NAME} \
    && echo '%wheel ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers.d/wheel \
    && adduser ${USER_NAME} wheel

WORKDIR /data
RUN chown -R ${USER_UID}:${USER_GID} /data

ENTRYPOINT ["/usr/bin/sudo", "/bin/docker-entrypoint.sh"]

USER ${USER_NAME}
EXPOSE 5000

CMD ["blast-radius", "--serve"]
