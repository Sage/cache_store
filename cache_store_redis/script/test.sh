#!/bin/sh

echo start rspec tests
docker-compose up -d

docker exec -it testrunner bash -c "bundle install && bundle exec rspec $*" \
&& docker exec -it testrunner_jruby bash -c "cd code && rm -rf Gemfile.lock && jruby -S bundle install && jruby -S rspec $*"