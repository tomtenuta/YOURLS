<?php
/**
 * Public Front Page for Cntently URL Shortener
 * 
 * A branded, modern interface that aligns with the admin UI structure
 * while providing a clean public-facing experience.
 */

require_once( dirname(__FILE__).'/includes/load-yourls.php' );

// Start session to track simple UI state across requests
if ( session_status() !== PHP_SESSION_ACTIVE ) {
	session_start();
}

// Handle form submission
$return = null;
$url = '';
$keyword = '';
$title = '';
$text = '';

if ( isset( $_REQUEST['url'] ) && $_REQUEST['url'] != '' && $_REQUEST['url'] != 'https://' ) {
	// Mark that user clicked shorten in this session
	$_SESSION['shorten_clicked'] = true;

    $url     = $_REQUEST['url'];
    $keyword = isset( $_REQUEST['keyword'] ) ? $_REQUEST['keyword'] : '';
    $title   = isset( $_REQUEST['title'] ) ? $_REQUEST['title'] : '';
    $text    = isset( $_REQUEST['text'] ) ? $_REQUEST['text'] : '';
    
    $return  = yourls_add_new_link( $url, $keyword, $title );
    
    $shorturl = isset( $return['shorturl'] ) ? $return['shorturl'] : '';
    $message  = isset( $return['message'] ) ? $return['message'] : '';
    $status   = isset( $return['status'] ) ? $return['status'] : '';

    // Soft-handle duplicate long URL: log gentle note and reuse existing short URL
    if ( $status === 'fail' && isset($return['code']) && $return['code'] === 'error:url' && !empty($shorturl) ) {
        if ( function_exists('yourls_debug_log') ) {
            yourls_debug_log( 'Notice: Duplicate long URL submitted; returning existing short link for ' . yourls_trim_long_string($url) );
        }
        $status = 'success';
        $message = 'Reusing existing short link';
    }
    
    // Handle JSONP callback for bookmarklet
    if( isset( $_GET['jsonp'] ) && $_GET['jsonp'] == 'yourls' ) {
        $short = $return['shorturl'] ? $return['shorturl'] : '';
        $message = "Short URL (Ctrl+C to copy)";
        header('Content-type: application/json');
        echo yourls_apply_filter( 'bookmarklet_jsonp', "yourls_callback({'short_url':'$short','message':'$message'});" );
        die();
    }
}

// Start the HTML output with proper context
yourls_html_head( 'index', 'Cntently URL Shortener' );

// Custom styles for the public page
?>
<style>
/* Public page header */
.public-header {
    background: transparent;
    border-bottom: 1px solid #E4EEFF;
}

.public-header .container {
    max-width: 1100px;
    margin: 0 auto;
    padding: 24px 30px;
    display: flex;
    align-items: center;
    justify-content: space-between;
}

.public-header .brand {
    display: flex;
    flex-direction: column;
}

.public-header .brand-name {
    color: #4E8EFE;
    font-size: 28px;
    font-weight: 600;
    text-decoration: none;
    line-height: 1;
}

.public-header .brand-tagline {
    color: #6B7280;
    font-size:16px;
    margin-top: 6px;
}

.public-header .logo img {
    height: 100px;
    width: auto;
    display: block;
}

/* Public page specific styles */
main.public-container {
    max-width: 800px;
    margin: 40px auto;
    padding: 0 20px;
}


.shortener-form {
    background: #FFFFFF;
    padding: 40px;
    border-radius: 12px;
    box-shadow: 0 2px 8px rgba(78, 142, 254, 0.1);
    border: 1px solid #E4EEFF;
    margin-bottom: 40px;
}

.form-group {
    margin-bottom: 25px;
}

.form-group label {
    display: block;
    margin-bottom: 8px;
    color: #333;
    font-weight: 500;
    font-size: 14px;
}

.form-group .hint {
    color: #999;
    font-size: 12px;
    margin-top: 5px;
}

.form-group input[type="text"],
.form-group input[type="url"] {
    width: 100%;
    padding: 12px 15px;
    border: 2px solid #E4EEFF;
    border-radius: 8px;
    font-size: 16px;
    transition: all 0.3s ease;
    box-sizing: border-box;
}

.form-group input[type="text"]:focus,
.form-group input[type="url"]:focus {
    border-color: #4E8EFE;
    outline: none;
    box-shadow: 0 0 0 3px rgba(78, 142, 254, 0.1);
}

.optional-fields {
    margin-top: 30px;
    padding-top: 30px;
    border-top: 1px solid #E4EEFF;
}

.optional-fields-toggle {
    color: #4E8EFE;
    cursor: pointer;
    text-decoration: none;
    font-size: 14px;
    display: inline-flex;
    align-items: center;
    margin-bottom: 20px;
}

.optional-fields-toggle:before {
    content: '▶';
    margin-right: 8px;
    transition: transform 0.3s;
}

.optional-fields-toggle.expanded:before {
    transform: rotate(90deg);
}

.optional-fields-content {
    display: none;
}

.optional-fields-content.show {
    display: block;
}

.submit-button {
    background: #4E8EFE;
    color: white !important;
    padding: 14px 40px;
    border: none;
    border-radius: 8px;
    font-size: 16px;
    font-weight: 600;
    cursor: pointer;
    transition: all 0.3s ease;
    display: inline-block;
}

.submit-button:hover {
    background: #79A9FF;
    transform: translateY(-1px);
    box-shadow: 0 4px 12px rgba(78, 142, 254, 0.3);
}

.success-box {
    background: #E4EEFF;
    border: 2px solid #4E8EFE;
    border-radius: 12px;
    padding: 30px;
    margin-bottom: 40px;
    animation: slideDown 0.4s ease;
}

@keyframes slideDown {
    from {
        opacity: 0;
        transform: translateY(-20px);
    }
    to {
        opacity: 1;
        transform: translateY(0);
    }
}

.success-box h2 {
    color: #4E8EFE;
    margin-top: 0;
    margin-bottom: 20px;
    font-size: 1.5em;
}

.short-url-display {
    background: white;
    border: 2px solid #79A9FF;
    border-radius: 8px;
    padding: 15px;
    display: flex;
    align-items: center;
    justify-content: space-between;
    margin-bottom: 20px;
}

.short-url-display input {
    border: none;
    background: none;
    font-size: 16px;
    color: #4E8EFE;
    font-weight: 600;
    flex: 1;
    padding: 0;
    margin-right: 10px;
}

.copy-button {
    background: #4E8EFE;
    color: white;
    border: none;
    padding: 8px 20px;
    border-radius: 6px;
    cursor: pointer;
    font-size: 14px;
    transition: all 0.3s ease;
    white-space: nowrap;
}

.copy-button:hover {
    background: #79A9FF;
}

.copy-button.copied {
    background: #28a745;
}

.original-url {
    color: #666;
    font-size: 14px;
    word-break: break-all;
}

.features-section {
    margin-top: 60px;
    padding-top: 40px;
    border-top: 1px solid #E4EEFF;
}

.features-grid {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
    gap: 30px;
    margin-top: 30px;
}

.feature-card {
    text-align: center;
    padding: 20px;
    background: #F9FBFF;
    border-radius: 8px;
    border: 1px solid #E4EEFF;
}

.feature-icon {
    font-size: 2em;
    margin-bottom: 15px;
    color: #4E8EFE;
}

.feature-title {
    color: #333;
    font-weight: 600;
    margin-bottom: 10px;
}

.feature-desc {
    color: #666;
    font-size: 14px;
    line-height: 1.5;
}

/* Hide default YOURLS menu on public page */
ul#admin_menu {
    display: none;
}

/* Fade-out utility for success-box */
.fade-out {
    opacity: 0;
    transition: opacity 200ms ease;
}
</style>

<?php
// Detect protocol safely (includes proxy headers)
$protocol = 'http://';
if (
    (!empty($_SERVER['HTTPS']) && $_SERVER['HTTPS'] !== 'off')
    || (isset($_SERVER['HTTP_X_FORWARDED_PROTO']) && $_SERVER['HTTP_X_FORWARDED_PROTO'] === 'https')
) {
    $protocol = 'https://';
}

// Get the host and strip subdomains
$host = $_SERVER['HTTP_HOST'];

// Split host by dots
$host_parts = explode('.', $host);

// Handle domains like "sub.example.com" or "deep.sub.example.com"
if (count($host_parts) > 2) {
    // Keep only the last two parts (e.g., "example.com")
    $host = implode('.', array_slice($host_parts, -2));
}

// Handle edge cases for local dev (like "localhost" or "example.test")
if (strpos($host, '.') === false) {
    $host = $_SERVER['HTTP_HOST']; // fallback for single-level hosts
}

$base_url = $protocol . $host;
?>

<header class="public-header" role="banner">
    <div class="container">
        <div class="brand">
            <a class="brand-name" href="<?php echo $base_url; ?>/">With 🩵 from Contente</a>
            <span class="brand-tagline">Create short, memorable links in seconds</span>
        </div>
        <div class="logo" aria-hidden="false">
            <img src="<?php echo $base_url; ?>/user/logo.svg" alt="Cntently logo">
        </div>
    </div>
</header>



<main class="public-container" role="main">
    
    <?php if ( isset($return) && $status == 'success' ): ?>
        <div class="success-box">
            <h2>✅ Your link has been shortened!</h2>
            <div class="short-url-display">
                <input type="text" id="shorturl" value="<?php echo $shorturl; ?>" readonly>
                <button class="copy-button" onclick="copyToClipboard()">Copy Link</button>
            </div>
            <div class="original-url">
                <strong>Original URL:</strong> <?php echo htmlspecialchars($url); ?>
            </div>
        </div>
    <?php elseif ( isset($return) && $status == 'fail' ): ?>
        <div class="success-box" style="border-color: #dc3545; background: #ffe6e6;">
            <h2 style="color: #dc3545;">⚠️ <?php echo $message; ?></h2>
        </div>
    <?php endif; ?>

    
    <div class="shortener-form">
        <form method="post" action="">
            <div class="form-group">
                <label for="url">Enter your long URL *</label>
                <input type="url" id="url" name="url" class="text" placeholder="https://example.com/your-very-long-url" value="<?php echo isset($_REQUEST['url']) ? htmlspecialchars($_REQUEST['url']) : ''; ?>" required>
                <div class="hint">Paste the long URL you want to shorten</div>
            </div>
            
            <div class="optional-fields">
                <a href="#" class="optional-fields-toggle" onclick="toggleOptionalFields(event)">Advanced Options</a>
                
                <div class="optional-fields-content">
                    <div class="form-group">
                        <label for="keyword">Custom Short URL (optional)</label>
                        <div style="display: flex; align-items: center;">
                            <span style="color: #666; margin-right: 5px;"><?php echo YOURLS_SITE; ?>/</span>
                            <input type="text" id="keyword" name="keyword" style="flex: 1;" placeholder="custom-name" value="<?php echo isset($_REQUEST['keyword']) ? htmlspecialchars($_REQUEST['keyword']) : ''; ?>">
                        </div>
                        <div class="hint">Leave blank for automatic short URL generation</div>
                    </div>
                    
                    <div class="form-group">
                        <label for="title">Title (optional)</label>
                        <input type="text" id="title" name="title" placeholder="Page Title" value="<?php echo isset($_REQUEST['title']) ? htmlspecialchars($_REQUEST['title']) : ''; ?>">
                        <div class="hint">Add a descriptive title for your link</div>
                    </div>
                </div>
            </div>
            
            <button type="submit" class="submit-button">Shorten URL</button>
        </form>
    </div>
    
    <?php if ( empty($_SESSION['shorten_clicked']) ): ?>
    <div class="features-section">
        <h2 style="text-align: center; color: #333;">Why Choose Cntently?</h2>
        <div class="features-grid">
            <div class="feature-card">
                <div class="feature-icon">🚀</div>
                <div class="feature-title">Lightning Fast</div>
                <div class="feature-desc">Create short links instantly with our optimized infrastructure</div>
            </div>
            <!-- <div class="feature-card">
                <div class="feature-icon">📊</div>
                <div class="feature-title">Analytics</div>
                <div class="feature-desc">Track clicks and monitor your link performance</div>
            </div> -->
            <div class="feature-card">
                <div class="feature-icon">🔒</div>
                <div class="feature-title">Secure & Private</div>
                <div class="feature-desc">Your data is safe with enterprise-grade security</div>
            </div>
            <div class="feature-card">
                <div class="feature-icon">⚡</div>
                <div class="feature-title">Custom URLs</div>
                <div class="feature-desc">Create memorable custom short links for your brand</div>
            </div>
        </div>
    </div>
    <?php endif; ?>
    
</main>

<script>
function toggleOptionalFields(e) {
    e.preventDefault();
    const toggle = document.querySelector('.optional-fields-toggle');
    const content = document.querySelector('.optional-fields-content');
    
    toggle.classList.toggle('expanded');
    content.classList.toggle('show');
}

function copyToClipboard() {
    const input = document.getElementById('shorturl');
    const button = document.querySelector('.copy-button');
    const successBox = document.querySelector('.success-box');
    
    // Select the text
    input.select();
    input.setSelectionRange(0, 99999); // For mobile devices
    
    // Copy the text
    navigator.clipboard.writeText(input.value).then(function() {
        // Update button text
        button.textContent = 'Copied!';
        button.classList.add('copied');
        if (successBox) {
            successBox.classList.add('fade-out');
            setTimeout(function(){
                successBox.style.display = 'none';
            }, 220);
        }
        
        // Reset after 2 seconds
        setTimeout(function() {
            button.textContent = 'Copy Link';
            button.classList.remove('copied');
        }, 2000);
    }).catch(function(err) {
        // Fallback for older browsers
        document.execCommand('copy');
        button.textContent = 'Copied!';
        button.classList.add('copied');
        if (successBox) {
            successBox.classList.add('fade-out');
            setTimeout(function(){
                successBox.style.display = 'none';
            }, 220);
        }
        
        setTimeout(function() {
            button.textContent = 'Copy Link';
            button.classList.remove('copied');
        }, 2000);
    });
}

// Auto-focus the URL input field when page loads
document.addEventListener('DOMContentLoaded', function() {
    const urlInput = document.getElementById('url');
    if (urlInput && !urlInput.value) {
        urlInput.focus();
    }
});
</script>

<?php
// Output the footer (reusing admin structure)
yourls_html_footer();
?>