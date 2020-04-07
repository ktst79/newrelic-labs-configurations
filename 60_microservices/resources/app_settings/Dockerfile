FROM ruby:2.5.3

RUN apt-get update -qq && \
    apt-get install -y build-essential libpq-dev nodejs && \
    gem install bundler -v 1.17.3

ENV APP_ROOT /app
WORKDIR $APP_ROOT
ADD ./app_settings $APP_ROOT

RUN rm $APP_ROOT/Gemfile.lock
RUN touch $APP_ROOT/Gemfile.lock

RUN bundle _1.17.3_ install

ADD ./resources/app_settings/entrypoint.sh /bin/

ENTRYPOINT ["/bin/entrypoint.sh"]
