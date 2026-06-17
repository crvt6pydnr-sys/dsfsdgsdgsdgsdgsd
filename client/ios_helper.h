#ifndef IOS_HELPER_H
#define IOS_HELPER_H

#include <QString>

void initAppleAudioSession();
void setupAppleRemoteCommands(void (*playCallback)(), void (*pauseCallback)(), void (*nextCallback)(), void (*prevCallback)());
void updateAppleNowPlayingInfo(const QString &title, const QString &artist, double duration, double position, bool isPlaying);

#endif // IOS_HELPER_H
