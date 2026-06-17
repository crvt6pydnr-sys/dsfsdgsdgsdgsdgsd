#include "ios_helper.h"
#import <AVFoundation/AVFoundation.h>
#import <MediaPlayer/MediaPlayer.h>

void initAppleAudioSession() {
#if TARGET_OS_IPHONE
    AVAudioSession *session = [AVAudioSession sharedInstance];
    [session setCategory:AVAudioSessionCategoryPlayback error:nil];
    [session setActive:YES error:nil];
#endif
}

void setupAppleRemoteCommands(void (*playCallback)(), void (*pauseCallback)(), void (*nextCallback)(), void (*prevCallback)()) {
    MPRemoteCommandCenter *commandCenter = [MPRemoteCommandCenter sharedCommandCenter];
    
    [commandCenter.playCommand removeTarget:nil];
    [commandCenter.pauseCommand removeTarget:nil];
    [commandCenter.nextTrackCommand removeTarget:nil];
    [commandCenter.previousTrackCommand removeTarget:nil];
    
    [commandCenter.playCommand addTargetWithHandler:^MPRemoteCommandHandlerStatus(MPRemoteCommandEvent * _Nonnull event) {
        playCallback();
        return MPRemoteCommandHandlerStatusSuccess;
    }];
    
    [commandCenter.pauseCommand addTargetWithHandler:^MPRemoteCommandHandlerStatus(MPRemoteCommandEvent * _Nonnull event) {
        pauseCallback();
        return MPRemoteCommandHandlerStatusSuccess;
    }];
    
    [commandCenter.nextTrackCommand addTargetWithHandler:^MPRemoteCommandHandlerStatus(MPRemoteCommandEvent * _Nonnull event) {
        nextCallback();
        return MPRemoteCommandHandlerStatusSuccess;
    }];
    
    [commandCenter.previousTrackCommand addTargetWithHandler:^MPRemoteCommandHandlerStatus(MPRemoteCommandEvent * _Nonnull event) {
        prevCallback();
        return MPRemoteCommandHandlerStatusSuccess;
    }];
}

void updateAppleNowPlayingInfo(const QString &title, const QString &artist, double duration, double position, bool isPlaying) {
    NSMutableDictionary *nowPlayingInfo = [NSMutableDictionary dictionary];
    
    if (!title.isEmpty()) {
        nowPlayingInfo[MPMediaItemPropertyTitle] = title.toNSString();
    }
    if (!artist.isEmpty()) {
        nowPlayingInfo[MPMediaItemPropertyArtist] = artist.toNSString();
    }
    
    nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = @(duration);
    nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = @(position);
    nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = isPlaying ? @(1.0) : @(0.0);
    
    [MPNowPlayingInfoCenter defaultCenter].nowPlayingInfo = nowPlayingInfo;
}
