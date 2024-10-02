#!/bin/bash

set -e

# Replace these with your bot token and chat ID
TELEGRAM_BOT_TOKEN="<YOUR_BOT_TOKEN>"
TELEGRAM_CHAT_ID="<YOUR_CHAT_ID>"

function send_telegram_alert {
    local message="$1"
    curl -s -X POST "https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/sendMessage" \
    -d chat_id="$TELEGRAM_CHAT_ID" \
    -d text="$message"
}

function error_exit {
    local message="$1"
    send_telegram_alert "🔴 Deployment failed: $message"
    exit 1
}

echo "✅ Deploying Application ..."

# Load nvm (if installed with nvm)
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

# Enter maintenance mode
if php artisan down; then
    echo "✅ Application is now in maintenance mode."
else
    error_exit "🚨 Failed to enter maintenance mode."
fi

# Update codebase
if git pull origin development; then
    echo "✅ Codebase updated from development."
else
    error_exit "🚨 Failed to update codebase."
fi

# Install dependencies
if composer install --no-interaction --prefer-dist --optimize-autoloader; then
    echo "✅ Composer dependencies installed."
else
    error_exit "🚨 Failed to install composer dependencies."
fi

# NPM Install
if npm install; then
    echo "✅ NPM Install"
else
    error_exit "🚨 Failed to run NPM Install."
fi

# NPM run Build
if npm run build; then
    echo "✅ Run vite build."
else
    error_exit "🚨 Failed to Build."
fi

# Cache icon
if php artisan icon:cache; then
    echo "✅ Cache Icon."
else
    error_exit "🚨 Failed to Cache Icon."
fi

# Cache view
if php artisan view:cache; then
    echo "✅ Cache Views."
else
    error_exit "🚨 Failed to Cache Views."
fi

# Cache config
if php artisan config:cache; then
    echo "✅ Cache configs."
else
    error_exit "🚨 Failed to Cache configs."
fi

# Cache route
if php artisan route:cache; then
    echo "✅ Cache routes."
else
    error_exit "🚨 Failed to Cache routes."
fi

# Cache event
if php artisan event:cache; then
    echo "✅ Cache events."
else
    error_exit "🚨 Failed to Cache events."
fi

# Regenerate autoload files
if composer dump-autoload; then
    echo "✅ Autoload files regenerated."
else
    error_exit "🚨 Failed to regenerate autoload files."
fi

# Run Migrate and Seeder
if php artisan migrate:fresh --seed; then
    echo "✅ Success Run Migration."
else
    error_exit "🚨 Failed to exit maintenance mode."
fi

# Exit maintenance mode
if php artisan up; then
    echo "✅ Application is now live."
else
    error_exit "🚨 Failed to exit maintenance mode."
fi

# Auto run pm2 queue
if pm2 start pm2-queue.yml; then
    echo "✅ PM2 queue started."
else
    error_exit "🚨 Failed to start PM2 queue."
fi

# Auto run pm2 reverb
if pm2 start pm2-reverb.yml; then
    echo "✅ PM2 reverb started."
else
    error_exit "🚨 Failed to start PM2 reverb."
fi

# Auto run pm2 horizon (commented out)
if pm2 start pm2-horizon.yml; then
    echo "✅ PM2 horizon started."
else
    error_exit "🚨 Failed to start PM2 horizon."
fi

# Auto save PM2 state
if pm2 save; then
    echo "✅ PM2 state saved."
else
    error_exit "🚨 Failed to save PM2 state."
fi

# Send success alert
send_telegram_alert "🟢 Deployment succeeded. The application is now live."

echo "✅ Application Deployed Successfully"
