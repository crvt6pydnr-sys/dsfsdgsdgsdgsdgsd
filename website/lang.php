<?php
$lang = 'ru';
if (isset($_GET['lang'])) {
    $lang = $_GET['lang'] === 'en' ? 'en' : 'ru';
    setcookie('lang', $lang, time() + 3600 * 24 * 30, '/');
} elseif (isset($_COOKIE['lang'])) {
    $lang = $_COOKIE['lang'] === 'en' ? 'en' : 'ru';
} else {
    $browser_lang = substr($_SERVER['HTTP_ACCEPT_LANGUAGE'] ?? '', 0, 2);
    if ($browser_lang === 'en') {
        $lang = 'en';
    }
}

$translations = [
    'ru' => [
        'title' => 'Tortu — Слушай, Делись, Ищи',
        'subtitle' => 'Современный, легкий и открытый музыкальный плеер',
        'desc' => 'Tortu — это альтернативный клиент для прослушивания музыки с поддержкой плейлистов, поиска и возможностью загрузки собственных треков. Проект создан для удобного обмена музыкой с друзьями без лишних ограничений.',
        'features' => 'Основные возможности',
        'feat1_title' => 'Поиск и воспроизведение',
        'feat1_desc' => 'Ищите треки по названию, исполнителю или альбому во всей базе музыки.',
        'feat2_title' => 'Плейлисты',
        'feat2_desc' => 'Создавайте собственные плейлисты и управляйте ими. Только автор может удалять свои плейлисты.',
        'feat3_title' => 'Облако и Загрузка',
        'feat3_desc' => 'Загружайте новые песни с текстом и обложкой в единое облако Tortu.',
        'downloads' => 'Скачать Tortu',
        'download_win' => 'Скачать для Windows (x64)',
        'download_deb' => 'Скачать .deb (Ubuntu/Debian)',
        'download_rpm' => 'Скачать .rpm (Fedora/RHEL/Nobara)',
        'download_mac' => 'Скачать .dmg (macOS)',
        'telegram' => 'Наш Telegram-канал',
        'disclaimer' => 'Отказ от ответственности',
        'dmca' => 'Правообладателям (DMCA)',
        'privacy' => 'Политика конфиденциальности',
        'copyright' => '© ' . date('Y') . ' Tortu. Все права защищены.',
        'lang_switch' => 'English',
        'lang_code' => 'en',
        'back_home' => 'На главную',
        'vps_notice' => 'Клиент работает автономно и подключается напрямую к серверу API.',
        
        'disclaimer_title' => 'Отказ от ответственности',
        'disclaimer_p1' => 'Приложение Tortu является открытым программным обеспечением. Разработчики предоставляют программу "как есть", без каких-либо явных или подразумеваемых гарантий.',
        'disclaimer_p2' => 'Разработчики не несут ответственности за загружаемый пользователями контент, а также за любые прямые или косвенные убытки, связанные с использованием приложения.',
        'disclaimer_p3' => 'Пользователи самостоятельно несут ответственность за соблюдение авторских прав и местного законодательства при воспроизведении, прослушивании и загрузке медиафайлов.',
        
        'dmca_title' => 'Правообладателям (DMCA)',
        'dmca_p1' => 'Проект Tortu уважает права интеллектуальной собственности и ожидает того же от своих пользователей.',
        'dmca_p2' => 'Мы не осуществляем предварительную модерацию загружаемого пользователями контента. Если вы являетесь правообладателем и считаете, что файлы, размещенные в сети Tortu, нарушают ваши авторские права, вы можете отправить жалобу.',
        'dmca_p3' => 'Для подачи жалобы свяжитесь с нами через наш Telegram-канал или отправьте претензию на электронный адрес: dmca@tortu.cyou. Пожалуйста, укажите точные ссылки на материалы и приложите документы, подтверждающие ваши права.',
        
        'privacy_title' => 'Политика конфиденциальности',
        'privacy_p1' => 'Мы не собираем, не храним и не передаем третьим лицам персональные данные пользователей.',
        'privacy_p2' => 'При регистрации и использовании приложения сохраняется только минимальная информация (логин, зашифрованный хэш пароля и созданные плейлисты), необходимая для обеспечения работы облачного функционала.',
        'privacy_p3' => 'Ваши пароли надежно хэшируются и не могут быть прочитаны администрацией или третьими лицами.'
    ],
    'en' => [
        'title' => 'Tortu — Listen, Share, Search',
        'subtitle' => 'Modern, lightweight, and open music player',
        'desc' => 'Tortu is an alternative music streaming client with playlist support, full search, and options to upload your own tracks. The project is created to easily share music with friends without unnecessary limits.',
        'features' => 'Key Features',
        'feat1_title' => 'Search & Playback',
        'feat1_desc' => 'Search for tracks by title, artist, or album across the entire music database.',
        'feat2_title' => 'Playlists',
        'feat2_desc' => 'Create and manage your own playlists. Only the playlist author is allowed to delete it.',
        'feat3_title' => 'Cloud & Uploads',
        'feat3_desc' => 'Upload new tracks with lyrics and album cover directly to the Tortu cloud.',
        'downloads' => 'Download Tortu',
        'download_win' => 'Download for Windows (x64)',
        'download_deb' => 'Download .deb (Ubuntu/Debian)',
        'download_rpm' => 'Download .rpm (Fedora/RHEL/Nobara)',
        'download_mac' => 'Download .dmg (macOS)',
        'telegram' => 'Our Telegram Channel',
        'disclaimer' => 'Disclaimer',
        'dmca' => 'Copyright Holders (DMCA)',
        'privacy' => 'Privacy Policy',
        'copyright' => '© ' . date('Y') . ' Tortu. All rights reserved.',
        'lang_switch' => 'Русский',
        'lang_code' => 'ru',
        'back_home' => 'Back Home',
        'vps_notice' => 'The client works standalone and connects directly to the API server.',
        
        'disclaimer_title' => 'Disclaimer',
        'disclaimer_p1' => 'The Tortu application is open-source software. The developers provide the program "as is" without any express or implied warranties.',
        'disclaimer_p2' => 'The developers are not responsible for the content uploaded by users, nor for any direct or indirect damage related to the use of the application.',
        'disclaimer_p3' => 'Users are solely responsible for complying with copyrights and local laws when playing, listening, or uploading media files.',
        
        'dmca_title' => 'Copyright Holders (DMCA)',
        'dmca_p1' => 'The Tortu project respects intellectual property rights and expects its users to do the same.',
        'dmca_p2' => 'We do not pre-moderate user-uploaded content. If you are a copyright holder and believe that files hosted on the Tortu network violate your copyrights, you may submit a complaint.',
        'dmca_p3' => 'To file a complaint, contact us via our Telegram channel or send a claim to: dmca@tortu.cyou. Please provide the exact links to the materials and attach proof of your rights.',
        
        'privacy_title' => 'Privacy Policy',
        'privacy_p1' => 'We do not collect, store, or share users\' personal data with third parties.',
        'privacy_p2' => 'When registering and using the application, only minimal information (username, encrypted password hash, and created playlists) is stored to run the cloud features.',
        'privacy_p3' => 'Your passwords are securely hashed and cannot be read by the administration or third parties.'
    ]
];

$t = $translations[$lang];
?>
