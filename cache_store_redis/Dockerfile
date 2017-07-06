FROM 522104923602.dkr.ecr.eu-west-1.amazonaws.com/sageone/ruby:20170623

# Create application directory and set it as the WORKDIR.
ENV APP_HOME /code
RUN mkdir -p $APP_HOME
WORKDIR $APP_HOME

COPY . $APP_HOME

RUN bundle install --system --binstubs
