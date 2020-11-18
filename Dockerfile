FROM docker.artifactory.internal.amount.com/ruby:2.7-alpine

RUN apk add --update-cache build-base && \
    gem install ox && \
    apk del build-base && rm -rf /var/cache/apk/* && \
    gem info ox && ruby -e 'require "ox"'
