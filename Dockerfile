# syntax=docker/dockerfile:1
# check=error=true

# Make sure RUBY_VERSION matches .ruby-version
ARG RUBY_VERSION=3.3.4
FROM docker.io/library/ruby:$RUBY_VERSION-slim AS base

# Rails app lives here
WORKDIR /rails

# Runtime deps (add psql here so it's available at runtime for db:prepare)
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
      curl \
      libjemalloc2 \
      libvips \
      sqlite3 \
      postgresql-client \
    && rm -rf /var/lib/apt/lists/* /var/cache/apt/archives

# Production env
ENV RAILS_ENV="production" \
    BUNDLE_DEPLOYMENT="1" \
    BUNDLE_PATH="/usr/local/bundle" \
    BUNDLE_WITHOUT="development"

# ---------- Build stage ----------
FROM base AS build

# Build deps for native gems
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y build-essential git pkg-config && \
    rm -rf /var/lib/apt/lists/* /var/cache/apt/archives

# Install gems
COPY Gemfile Gemfile.lock ./
RUN bundle install && \
    rm -rf ~/.bundle/ "${BUNDLE_PATH}"/ruby/*/cache "${BUNDLE_PATH}"/ruby/*/bundler/gems/*/.git && \
    bundle exec bootsnap precompile --gemfile

# Copy app code
COPY . .

# Precompile bootsnap
RUN bundle exec bootsnap precompile app/ lib/

# Precompile assets for production without requiring real master key
ENV SECRET_KEY_BASE_DUMMY=1
RUN ./bin/rails assets:precompile
# (No need to unset; container process won't inherit this)

# ---------- Final stage ----------
FROM base

# Copy gems and app from build stage
COPY --from=build "${BUNDLE_PATH}" "${BUNDLE_PATH}"
COPY --from=build /rails /rails

# Non-root runtime user
RUN groupadd --system --gid 1000 rails && \
    useradd rails --uid 1000 --gid 1000 --create-home --shell /bin/bash && \
    chown -R rails:rails db log storage tmp
USER 1000:1000

# Rails 8 entrypoint runs db:prepare, etc.
ENTRYPOINT ["/rails/bin/docker-entrypoint"]

# Document the port (Render will set $PORT)
EXPOSE 3000

# Start Rails; bind to Render's assigned port
CMD ["./bin/rails", "server", "-b", "0.0.0.0", "-p", "$PORT"]
