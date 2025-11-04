<?php

/*
 * Public front page for YOURLS, copied into /var/www/html/index.php by Dockerfile
 */

require_once( dirname(__FILE__).'/includes/load-yourls.php' );

$page = YOURLS_SITE . '/sample-public-front-page.php' ;

if ( isset( $_REQUEST['url'] ) && $_REQUEST['url'] != 'http://' ) {
    $url     = $_REQUEST['url'];
    $keyword = isset( $_REQUEST['keyword'] ) ? $_REQUEST['keyword'] : '' ;
    $title   = isset( $_REQUEST['title'] ) ?  $_REQUEST['title'] : '' ;
    $text    = isset( $_REQUEST['text'] ) ?  $_REQUEST['text'] : '' ;

    $return  = yourls_add_new_link( $url, $keyword, $title );

    $shorturl = isset( $return['shorturl'] ) ? $return['shorturl'] : '';
    $message  = isset( $return['message'] ) ? $return['message'] : '';
    $title    = isset( $return['title'] ) ? $return['title'] : '';
    $status   = isset( $return['status'] ) ? $return['status'] : '';

    if( isset( $_GET['jsonp'] ) && $_GET['jsonp'] == 'yourls' ) {
        $short = $return['shorturl'] ? $return['shorturl'] : '';
        $message = "Short URL (Ctrl+C to copy)";
        header('Content-type: application/json');
        echo yourls_apply_filter( 'bookmarklet_jsonp', "yourls_callback({'short_url':'$short','message':'$message'});" );
        die();
    }
}

yourls_html_head();
echo "<h1>YOURLS - Your Own URL Shortener</h1>\n";
yourls_html_menu();

if ( isset( $_REQUEST['url'] ) && $_REQUEST['url'] != 'http://' ) {
    if( isset( $message ) ) {
        echo "<h2>$message</h2>";
    }
    if( isset($status) && $status == 'success' ) {
        yourls_share_box( $url, $shorturl, $title, $text );
        echo "<script>init_clipboard();</script>\n";
    }
} else {
    $site = YOURLS_SITE;
    echo <<<HTML
    <h2>Enter a new URL to shorten</h2>
    <form method="post" action="">
    <p><label>URL: <input type="text" class="text" name="url" value="http://" /></label></p>
    <p><label>Optional custom short URL: $site/<input type="text" class="text" name="keyword" /></label></p>
    <p><label>Optional title: <input type="text" class="text" name="title" /></label></p>
    <p><input type="submit" class="button primary" value="Shorten" /></p>
    </form>
HTML;
}

echo "<h2>Bookmarklets</h2>";
echo "<p>Use the admin UI for advanced features. This public page is minimal by design.</p>";

yourls_html_footer();


