FROM ghcr.io/yourls/yourls:latest

# Copy public front page and make it the default index
COPY index-custom.php /var/www/html/index.php

COPY 404.php /var/www/html/404.php

COPY user/ /var/www/html/user/

# COPY user/plugins/branding/plugin.php /var/www/html/user/plugins/branding/plugin.php

# COPY user/logo.svg /var/www/html/user/logo.svg
# COPY user/logo.png /var/www/html/user/logo.png
# COPY user/favicon.svg /var/www/html/user/favicon.svg