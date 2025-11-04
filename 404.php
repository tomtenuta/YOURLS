<?php
// Send proper 404 header and prevent caches from storing this redirect target
http_response_code(404);
header('Content-Type: text/html; charset=utf-8');
header('Cache-Control: no-store, no-cache, must-revalidate, max-age=0');
header('Pragma: no-cache');

// Load YOURLS to reuse shared assets, branding, and layout
require_once( dirname(__FILE__).'/includes/load-yourls.php' );

// Standard head (loads CSS/JS, favicon) and layout wrapper
yourls_html_head('index', 'Not Found');

// Header/logo and basic menu for consistency with other public pages
yourls_html_logo();
yourls_html_menu();
?>
<main role="main" class="sub_wrap">
  <h2>404 — Not Found</h2>
  <p>The requested short link doesn’t exist, has been removed, or is private.</p>
  <p>This service only responds to valid short URLs created within the system.</p>
  <p><a href="<?php echo yourls_admin_url('index.php'); ?>">Go to the admin interface</a></p>
</main>
<?php
// Footer and close markup
yourls_html_footer();
?>
