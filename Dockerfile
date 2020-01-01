FROM ruby:2.6.5-alpine3.10

RUN apk add --update alpine-sdk

WORKDIR /usr/src/morrow-mud

COPY Gemfile Gemfile.lock ./
RUN bundle install

COPY . /usr/src/morrow-mud

CMD ["/usr/src/morrow-mud/bin/run-server.rb"]
