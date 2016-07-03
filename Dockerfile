FROM ruby:2.2

RUN mkdir -p /app

COPY Gemfile* /app

WORKDIR /app

RUN bundle install
