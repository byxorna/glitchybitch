FROM alpine
RUN apk update && apk add \
  ffmpeg \
  ruby ruby-irb ruby-rake ruby-io-console ruby-bigdecimal ruby-json ruby-bundler \
  libstdc++ tzdata bash ca-certificates && \
  echo 'gem: --no-document' > /etc/gemrc
COPY . /app
WORKDIR /app
RUN bundle install

VOLUME /output
