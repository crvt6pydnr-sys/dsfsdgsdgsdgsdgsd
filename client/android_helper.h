#ifndef ANDROID_HELPER_H
#define ANDROID_HELPER_H

#include <QtGlobal>

#ifdef Q_OS_ANDROID

#include <QString>

void initAndroidAudioSession(void (*playCallback)(), void (*pauseCallback)(), void (*nextCallback)(), void (*prevCallback)());
void updateAndroidNowPlayingInfo(const QString &title, const QString &artist, bool isPlaying, qint64 duration, qint64 position);

#endif // Q_OS_ANDROID

#endif // ANDROID_HELPER_H
