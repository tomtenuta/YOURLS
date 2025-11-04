<?php
/*
Plugin Name: Random ShortURLs (Base36 / Base62)
Plugin URI: https://yourls.org/
Description: Assign random keywords to shorturls with selectable charset (Base-36 or Base-62) and configurable length.
Version: 1.4
Author: Ozh
Author URI: https://ozh.org/
*/

/* Release History:
*
* 1.0 Initial release
* 1.1 Added: don't increment sequential keyword counter & save one SQL query
*     Fixed: plugin now complies to character set defined in config.php
* 1.2 Adopted as YOURLS core plugin under a new name
*     Now configured via YOURLS options instead of editing plugin file
* 1.3 Force base-36 charset (0-9, a-z lowercase) regardless of YOURLS_URL_CONVERT; use random_int() when available
* 1.4 Add settings toggle to choose Base-36 (0–9,a–z) or Base-62 (0–9,a–z,A–Z); UI & validation improvements
*/

// No direct call
if( !defined( 'YOURLS_ABSPATH' ) ) die();

// Only register things if the old third-party plugin is not present
if( function_exists('ozh_random_keyword') ) {
    yourls_add_notice( "<b>Random ShortURLs</b> plugin cannot function unless <b>Random Keywords</b> is removed first." );
} else {
    yourls_add_filter( 'random_keyword', 'ozh_random_shorturl' );
    yourls_add_filter( 'get_next_decimal', 'ozh_random_shorturl_next_decimal' );
}

/**
 * Generate a random keyword using selected charset
 * - base36: 0123456789abcdefghijklmnopqrstuvwxyz
 * - base62: 0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ
 * This intentionally ignores YOURLS_URL_CONVERT and follows the plugin setting instead.
 */
function ozh_random_shorturl() {
    $mode = yourls_get_option( 'random_shorturls_charset', 'base36' );
    $possible = ($mode === 'base62')
        ? '0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ'
        : '0123456789abcdefghijklmnopqrstuvwxyz';

    $len = yourls_get_option( 'random_shorturls_length', 5 );
    $len = ( is_numeric( $len ) && $len > 0 ) ? intval( $len ) : 5;

    $maxIndex = strlen( $possible ) - 1;
    $str = '';

    for( $i = 0; $i < $len; $i++ ) {
        if ( function_exists( 'random_int' ) ) {
            $idx = random_int( 0, $maxIndex );
        } else {
            $idx = mt_rand( 0, $maxIndex );
        }
        $str .= $possible[ $idx ];
    }

    return $str;
}

// Don't increment sequential keyword tracker
function ozh_random_shorturl_next_decimal( $next ) {
    return ( $next - 1 );
}

// Plugin settings page etc.
yourls_add_action( 'plugins_loaded', 'ozh_random_shorturl_add_settings' );
function ozh_random_shorturl_add_settings() {
    yourls_register_plugin_page( 'random_shorturl_settings', 'Random ShortURLs Settings', 'ozh_random_shorturl_settings_page' );
}

function ozh_random_shorturl_settings_page() {
    // Handle form submit
    if( isset( $_POST['random_length'] ) || isset( $_POST['random_charset'] ) ) {
        yourls_verify_nonce( 'random_shorturl_settings' );
        ozh_random_shorturl_settings_update();
    }

    $random_length  = yourls_get_option('random_shorturls_length', 5);
    $random_charset = yourls_get_option('random_shorturls_charset', 'base36');
    $nonce          = yourls_create_nonce( 'random_shorturl_settings' );

    $is36 = ($random_charset === 'base36') ? 'checked' : '';
    $is62 = ($random_charset === 'base62') ? 'checked' : '';

    echo <<<HTML
        <main>
            <h2>Random ShortURLs Settings</h2>
            <form method="post">
                <input type="hidden" name="nonce" value="$nonce" />
                <p>
                    <label style="display:block;margin-bottom:6px;">Random Keyword Length</label>
                    <input type="number" name="random_length" min="1" max="128" value="$random_length" />
                </p>
                <p style="margin-top:16px;">
                    <label style="display:block;margin-bottom:6px;">Character Set</label>
                    <label style="display:block;">
                        <input type="radio" name="random_charset" value="base36" $is36 />
                        Base-36 (0–9, a–z)
                    </label>
                    <label style="display:block;margin-top:6px;">
                        <input type="radio" name="random_charset" value="base62" $is62 />
                        Base-62 (0–9, a–z, A–Z)
                    </label>
                    <small style="display:block;margin-top:8px;">
                        This setting overrides <code>YOURLS_URL_CONVERT</code> for plugin-generated keywords.
                    </small>
                </p>
                <p style="margin-top:16px;">
                    <input type="submit" value="Save" class="button" />
                </p>
            </form>
        </main>
HTML;
}

function ozh_random_shorturl_settings_update() {
    // Length
    if( isset($_POST['random_length']) ) {
        $random_length = $_POST['random_length'];
        if( is_numeric( $random_length ) ) {
            $val = max(1, min(128, intval( $random_length )));
            yourls_update_option( 'random_shorturls_length', $val );
            yourls_add_notice( 'Saved: Random keyword length set to ' . $val );
        } else {
            yourls_add_notice( "Error: Length given was not a number." );
        }
    }

    // Charset mode
    if( isset($_POST['random_charset']) ) {
        $mode = $_POST['random_charset'];
        if( $mode === 'base36' || $mode === 'base62' ) {
            yourls_update_option( 'random_shorturls_charset', $mode );
            $label = ($mode === 'base62') ? 'Base-62 (0–9, a–z, A–Z)' : 'Base-36 (0–9, a–z)';
            yourls_add_notice( 'Saved: Character set set to ' . $label );
        } else {
            yourls_add_notice( "Error: Invalid character set option." );
        }
    }
}
