<?php
require_once 'lang.php';
?>
<!DOCTYPE html>
<html lang="<?php echo $lang; ?>">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title><?php echo $t['dmca_title']; ?> — Tortu</title>
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

        <main class="legal-content">
            <h2><?php echo $t['dmca_title']; ?></h2>
            <p><?php echo $t['dmca_p1']; ?></p>
            <p><?php echo $t['dmca_p2']; ?></p>
            <p><?php echo $t['dmca_p3']; ?></p>
            <div style="margin-top: 32px;">
                <a href="index.php" class="btn-tonal">
                    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                        <line x1="19" y1="12" x2="5" y2="12"></line>
                        <polyline points="12 19 5 12 12 5"></polyline>
                    </svg>
                    <span><?php echo $t['back_home']; ?></span>
                </a>
            </div>
        </main>

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
