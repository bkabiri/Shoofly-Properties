#!/bin/bash
set -e

# Clean old pid
rm -f /usr/src/app/tmp/pids/server.pid

echo "bundle check/install…"
bundle check || bundle install --jobs 4


# Precompile assets if manifest missing
if [ "${RAILS_ENV}" = "production" ]; then
  if ! ls public/assets/.sprockets-manifest* >/dev/null 2>&1; then
    echo "Assets manifest not found, precompiling…"
    bundle exec rails assets:precompile
  else
    echo "Assets manifest present, skipping precompile."
  fi
fi

# Hand off to CMD
exec "$@"