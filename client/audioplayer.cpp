#include "audioplayer.h"
#include <QUrl>

#ifdef Q_OS_MAC
#include "ios_helper.h"
#endif

#ifdef Q_OS_ANDROID
#include "android_helper.h"
#endif

static AudioPlayer *s_instance = nullptr;

static void globalPlayCallback() {
    if (s_instance) s_instance->play();
}

static void globalPauseCallback() {
    if (s_instance) s_instance->pause();
}

static void globalNextCallback() {
    if (s_instance) emit s_instance->nextTrackRequested();
}

static void globalPrevCallback() {
    if (s_instance) emit s_instance->prevTrackRequested();
}

AudioPlayer::AudioPlayer(QObject *parent)
    : QObject(parent)
    , m_player(new QMediaPlayer(this))
    , m_audioOutput(new QAudioOutput(this))
{
    m_player->setAudioOutput(m_audioOutput);
    m_audioOutput->setVolume(0.7);

    s_instance = this;

#ifdef Q_OS_MAC
    initAppleAudioSession();
    setupAppleRemoteCommands(globalPlayCallback, globalPauseCallback, globalNextCallback, globalPrevCallback);
#endif

#ifdef Q_OS_ANDROID
    initAndroidAudioSession(globalPlayCallback, globalPauseCallback, globalNextCallback, globalPrevCallback);
#endif

    connect(m_player, &QMediaPlayer::positionChanged, this, &AudioPlayer::positionChanged);
    
    connect(m_player, &QMediaPlayer::durationChanged, this, [this](qint64 duration) {
        emit durationChanged(duration);
        updateSystemMediaControls();
    });
    
    connect(m_player, &QMediaPlayer::playbackStateChanged, this, [this](QMediaPlayer::PlaybackState state) {
        emit playingChanged();
        updateSystemMediaControls();
    });

    connect(m_player, &QMediaPlayer::mediaStatusChanged, this, [this](QMediaPlayer::MediaStatus status) {
        if (status == QMediaPlayer::EndOfMedia) {
            emit finished();
        }
    });
}

AudioPlayer::~AudioPlayer()
{
    if (s_instance == this) {
        s_instance = nullptr;
    }
}

void AudioPlayer::setSource(const QString &source)
{
    if (m_source != source) {
        m_source = source;
        m_player->setSource(QUrl(m_source));
        emit sourceChanged();
        updateSystemMediaControls();
    }
}

bool AudioPlayer::isPlaying() const
{
    return m_player->playbackState() == QMediaPlayer::PlayingState;
}

void AudioPlayer::seek(qint64 position)
{
    m_player->setPosition(position);
    updateSystemMediaControls();
}

void AudioPlayer::setVolume(double volume)
{
    if (volume < 0.0) volume = 0.0;
    if (volume > 1.0) volume = 1.0;
    
    if (qAbs(m_audioOutput->volume() - volume) > 0.001) {
        m_audioOutput->setVolume(volume);
        emit volumeChanged(volume);
    }
}

void AudioPlayer::setTitle(const QString &title)
{
    if (m_title != title) {
        m_title = title;
        emit titleChanged();
        updateSystemMediaControls();
    }
}

void AudioPlayer::setArtist(const QString &artist)
{
    if (m_artist != artist) {
        m_artist = artist;
        emit artistChanged();
        updateSystemMediaControls();
    }
}

void AudioPlayer::play()
{
    m_player->play();
}

void AudioPlayer::pause()
{
    m_player->pause();
}

void AudioPlayer::stop()
{
    m_player->stop();
}

void AudioPlayer::updateSystemMediaControls()
{
#ifdef Q_OS_MAC
    double posSec = position() / 1000.0;
    double durSec = duration() / 1000.0;
    updateAppleNowPlayingInfo(m_title, m_artist, durSec, posSec, isPlaying());
#endif

#ifdef Q_OS_ANDROID
    updateAndroidNowPlayingInfo(m_title, m_artist, isPlaying(), duration(), position());
#endif
}
