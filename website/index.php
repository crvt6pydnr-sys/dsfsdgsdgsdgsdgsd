<?php
require_once 'lang.php';
?>
<!DOCTYPE html>
<html lang="<?php echo $lang; ?>">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title><?php echo $t['title']; ?></title>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Outfit:wght@400;500;600;700&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="style.css">
</head>
<body>
    <div class="container">
        <header>
            <a href="index.php" class="logo-link">
                <svg class="logo-img" viewBox="0 0 531 178" fill="none" xmlns="http://www.w3.org/2000/svg" style="color: var(--md-sys-color-primary);">
                    <path d="M85.5 141.9L2.4 75.6C0.799998 74 -1.76579e-06 72.2 -1.76579e-06 70.2C-1.76579e-06 68.2 0.799998 66.6 2.4 65.4L83.4 0.900014C84 0.30001 84.7 0.400009 85.5 1.20001L100.2 19.5C100.8 20.7 100.9 21.5 100.5 21.9L40.5 70.5L102.6 120.9C103.2 121.5 103.2 122.3 102.6 123.3L87.6 141.6C86.8 142.4 86.1 142.5 85.5 141.9ZM128.634 72.9V2.90001H408.384V72.9L343.134 63.9V38.4H301.134V177.9H235.884V38.4H193.884V63.9L128.634 72.9ZM444.912 141.9C444.312 142.5 443.612 142.4 442.812 141.6L427.812 123.3C427.212 122.3 427.212 121.5 427.812 120.9L489.912 70.5L429.912 21.9C429.512 21.5 429.612 20.7 430.212 19.5L444.912 1.20001C445.712 0.400009 446.412 0.30001 447.012 0.900014L528.012 65.4C529.612 66.6 530.412 68.2 530.412 70.2C530.412 72.2 529.612 74 528.012 75.6L444.912 141.9Z" fill="currentColor"/>
                </svg>
            </a>
            <a href="?lang=<?php echo $t['lang_code']; ?>" class="lang-btn">
                <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                    <circle cx="12" cy="12" r="10"></circle>
                    <line x1="2" y1="12" x2="22" y2="12"></line>
                    <path d="M12 2a15.3 15.3 0 0 1 4 10 15.3 15.3 0 0 1-4 10 15.3 15.3 0 0 1-4-10 15.3 15.3 0 0 1 4-10z"></path>
                </svg>
                <span><?php echo $t['lang_switch']; ?></span>
            </a>
        </header>

        <section class="hero">
            <svg class="hero-logo" viewBox="0 0 531 178" fill="none" xmlns="http://www.w3.org/2000/svg" style="color: var(--md-sys-color-primary);">
                <path d="M85.5 141.9L2.4 75.6C0.799998 74 -1.76579e-06 72.2 -1.76579e-06 70.2C-1.76579e-06 68.2 0.799998 66.6 2.4 65.4L83.4 0.900014C84 0.30001 84.7 0.400009 85.5 1.20001L100.2 19.5C100.8 20.7 100.9 21.5 100.5 21.9L40.5 70.5L102.6 120.9C103.2 121.5 103.2 122.3 102.6 123.3L87.6 141.6C86.8 142.4 86.1 142.5 85.5 141.9ZM128.634 72.9V2.90001H408.384V72.9L343.134 63.9V38.4H301.134V177.9H235.884V38.4H193.884V63.9L128.634 72.9ZM444.912 141.9C444.312 142.5 443.612 142.4 442.812 141.6L427.812 123.3C427.212 122.3 427.212 121.5 427.812 120.9L489.912 70.5L429.912 21.9C429.512 21.5 429.612 20.7 430.212 19.5L444.912 1.20001C445.712 0.400009 446.412 0.30001 447.012 0.900014L528.012 65.4C529.612 66.6 530.412 68.2 530.412 70.2C530.412 72.2 529.612 74 528.012 75.6L444.912 141.9Z" fill="currentColor"/>
            </svg>
            <h1>Tortu</h1>
            <p class="subtitle"><?php echo $t['subtitle']; ?></p>
            <p class="description"><?php echo $t['desc']; ?></p>
            <div class="cta-group">
                <a href="#download" class="btn-primary">
                    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                        <path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"></path>
                        <polyline points="7 10 12 15 17 10"></polyline>
                        <line x1="12" y1="15" x2="12" y2="3"></line>
                    </svg>
                    <span><?php echo $t['downloads']; ?></span>
                </a>
                <a href="tg.php" target="_blank" class="btn-tonal">
                    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                        <path d="M21.13 2.82a2.52 2.52 0 0 0-2.82-.48L2.4 8.7a1.59 1.59 0 0 0-.14 2.9l6.39 2.86a.79.79 0 0 0 .91-.18l7.2-7.2a.39.39 0 0 1 .59.55l-7.2 7.2a.79.79 0 0 0-.18.91l2.86 6.39a1.59 1.59 0 0 0 2.9-.14l6.36-15.91a2.52 2.52 0 0 0-.48-2.82z"></path>
                    </svg>
                    <span>Telegram</span>
                </a>
            </div>
        </section>

        <h2 class="section-title"><?php echo $t['features']; ?></h2>
        <div class="grid-features">
            <div class="card">
                <div class="card-icon">
                    <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                        <circle cx="11" cy="11" r="8"></circle>
                        <line x1="21" y1="21" x2="16.65" y2="16.65"></line>
                    </svg>
                </div>
                <h3><?php echo $t['feat1_title']; ?></h3>
                <p><?php echo $t['feat1_desc']; ?></p>
            </div>
            <div class="card">
                <div class="card-icon">
                    <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                        <line x1="8" y1="6" x2="21" y2="6"></line>
                        <line x1="8" y1="12" x2="21" y2="12"></line>
                        <line x1="8" y1="18" x2="21" y2="18"></line>
                        <line x1="3" y1="6" x2="3.01" y2="6"></line>
                        <line x1="3" y1="12" x2="3.01" y2="12"></line>
                        <line x1="3" y1="18" x2="3.01" y2="18"></line>
                    </svg>
                </div>
                <h3><?php echo $t['feat2_title']; ?></h3>
                <p><?php echo $t['feat2_desc']; ?></p>
            </div>
            <div class="card">
                <div class="card-icon">
                    <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                        <path d="M21.2 15c.7-1.2 1-2.5.7-3.9-.6-3.1-3.1-5.4-6.3-5.5-3.2-.1-6 1.8-7 4.7-2.3.6-4 2.7-4 5.2 0 3 2.5 5.5 5.5 5.5h10.5c2.5 0 4.5-2 4.5-4.5 0-1-.3-1.9-.9-2.6z"></path>
                        <polyline points="16 16 12 12 8 16"></polyline>
                        <line x1="12" y1="12" x2="12" y2="21"></line>
                    </svg>
                </div>
                <h3><?php echo $t['feat3_title']; ?></h3>
                <p><?php echo $t['feat3_desc']; ?></p>
            </div>
        </div>

        <section class="download-box" id="download">
            <h2 class="section-title" style="margin-top: 0;"><?php echo $t['downloads']; ?></h2>
            <div class="download-grid">
                <a href="downloads/tortu-windows-x64.zip" class="btn-download">
                    <div class="download-info">
                        <span class="download-name"><?php echo $t['download_win']; ?></span>
                        <span class="download-sub">tortu-windows-x64.zip (~57.5 MB)</span>
                    </div>
                    <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                        <path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"></path>
                        <polyline points="7 10 12 15 17 10"></polyline>
                        <line x1="12" y1="15" x2="12" y2="3"></line>
                    </svg>
                </a>
                <a href="downloads/tortu-macos-x64.dmg" class="btn-download">
                    <div class="download-info">
                        <span class="download-name"><?php echo $t['download_mac']; ?></span>
                        <span class="download-sub">tortu-macos-x64.dmg</span>
                    </div>
                    <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                        <path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"></path>
                        <polyline points="7 10 12 15 17 10"></polyline>
                        <line x1="12" y1="15" x2="12" y2="3"></line>
                    </svg>
                </a>
                <a href="downloads/tortu-android.apk" class="btn-download">
                    <div class="download-info">
                        <span class="download-name"><?php echo $t['download_android']; ?></span>
                        <span class="download-sub">tortu-android.apk</span>
                    </div>
                    <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                        <path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"></path>
                        <polyline points="7 10 12 15 17 10"></polyline>
                        <line x1="12" y1="15" x2="12" y2="3"></line>
                    </svg>
                </a>
                <a href="downloads/tortu-ios.ipa" class="btn-download">
                    <div class="download-info">
                        <span class="download-name"><?php echo $t['download_ios']; ?></span>
                        <span class="download-sub">tortu-ios.ipa</span>
                    </div>
                    <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                        <path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"></path>
                        <polyline points="7 10 12 15 17 10"></polyline>
                        <line x1="12" y1="15" x2="12" y2="3"></line>
                    </svg>
                </a>
                <a href="downloads/tortu-1.0.0-Linux.deb" class="btn-download">
                    <div class="download-info">
                        <span class="download-name"><?php echo $t['download_deb']; ?></span>
                        <span class="download-sub">tortu-1.0.0-Linux.deb (~244 KB)</span>
                    </div>
                    <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                        <path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"></path>
                        <polyline points="7 10 12 15 17 10"></polyline>
                        <line x1="12" y1="15" x2="12" y2="3"></line>
                    </svg>
                </a>
                <a href="downloads/tortu-1.0.0-Linux.rpm" class="btn-download">
                    <div class="download-info">
                        <span class="download-name"><?php echo $t['download_rpm']; ?></span>
                        <span class="download-sub">tortu-1.0.0-Linux.rpm (~194 KB)</span>
                    </div>
                    <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                        <path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"></path>
                        <polyline points="7 10 12 15 17 10"></polyline>
                        <line x1="12" y1="15" x2="12" y2="3"></line>
                    </svg>
                </a>
            </div>
            <p class="vps-badge"><?php echo $t['vps_notice']; ?></p>
        </section>

        <footer>
            <div class="footer-links">
                <a href="disclaimer.php"><?php echo $t['disclaimer']; ?></a>
                <a href="dmca.php"><?php echo $t['dmca']; ?></a>
                <a href="privacy.php"><?php echo $t['privacy']; ?></a>
            </div>
            <p class="copyright"><?php echo $t['copyright']; ?></p>
        </footer>
    </div>
</body>
</html>
