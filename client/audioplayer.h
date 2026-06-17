#ifndef AUDIOPLAYER_H
#define AUDIOPLAYER_H

#include <QObject>
#include <QMediaPlayer>
#include <QAudioOutput>

class AudioPlayer : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString source READ source WRITE setSource NOTIFY sourceChanged)
    Q_PROPERTY(bool playing READ isPlaying NOTIFY playingChanged)
    Q_PROPERTY(qint64 position READ position WRITE seek NOTIFY positionChanged)
    Q_PROPERTY(qint64 duration READ duration NOTIFY durationChanged)
    Q_PROPERTY(double volume READ volume WRITE setVolume NOTIFY volumeChanged)

public:
    explicit AudioPlayer(QObject *parent = nullptr);

    QString source() const { return m_source; }
    void setSource(const QString &source);

    bool isPlaying() const;

    qint64 position() const { return m_player->position(); }
    void seek(qint64 position);

    qint64 duration() const { return m_player->duration(); }

    double volume() const { return m_audioOutput->volume(); }
    void setVolume(double volume);

    Q_INVOKABLE void play();
    Q_INVOKABLE void pause();
    Q_INVOKABLE void stop();

signals:
    void sourceChanged();
    void playingChanged();
    void positionChanged(qint64 position);
    void durationChanged(qint64 duration);
    void volumeChanged(double volume);
    void finished();

private:
    QMediaPlayer *m_player;
    QAudioOutput *m_audioOutput;
    QString m_source;
};

#endif // AUDIOPLAYER_H
