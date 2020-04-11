FROM alpine

RUN apk add bash fzf tmux

COPY ./session-sauce.plugin.zsh /src/

WORKDIR src
ENV SESS_PROJECT_ROOT=/
ENTRYPOINT bash
