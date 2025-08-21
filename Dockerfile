FROM ruby:3.0.3

# System packages
# - build-essential, libpq-dev, postgresql-client: Rails & PG
# - nodejs, yarn: asset pipeline / importmap helpers
# - libvips & libvips-dev: required for image_processing(vips) / Active Storage variants
# - imagemagick: optional (nice to have if you switch to MiniMagick later)
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    libpq-dev \
    postgresql-client \
    git \
    nano \
    nodejs \
    yarn \
    libvips \
    libvips-dev \
    imagemagick \
  && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Bundler
RUN gem install bundler:2.3.7

WORKDIR /usr/src/app

# (Optional best practice for caching:
# COPY Gemfile Gemfile.lock ./
# RUN bundle config set without 'development test' && bundle install --jobs 4 --retry 3
# COPY . .)

ENTRYPOINT ["./entrypoint.sh"]

EXPOSE 3000

CMD ["bundle", "exec", "rails", "s", "-b", "0.0.0.0"]