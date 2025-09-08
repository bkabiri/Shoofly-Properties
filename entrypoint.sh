#!/bin/bash
set -e

# Remove a potentially pre-existing server.pid for Rails.
rm -f /usr/src/app/tmp/pids/server.pid

echo "bundle check/install…"
bundle check || bundle install --jobs 4

# No assets:precompile here – we precompiled during the image build.

exec "$@"