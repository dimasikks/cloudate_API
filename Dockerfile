FROM alpine:latest

ENV TZ=Europe/Moscow

RUN apk add --no-cache jq curl bash busybox tzdata