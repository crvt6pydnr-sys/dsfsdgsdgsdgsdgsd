#include <QtGlobal>
#include "android_helper.h"

#ifdef Q_OS_ANDROID

#include <QJniObject>
#include <QJniEnvironment>
#include <jni.h>

static void (*s_playCallback)() = nullptr;
static void (*s_pauseCallback)() = nullptr;
static void (*s_nextCallback)() = nullptr;
static void (*s_prevCallback)() = nullptr;

extern "C" JNIEXPORT void JNICALL Java_cyou_tortu_client_MediaService_onPlayClicked(JNIEnv *, jclass) {
    if (s_playCallback) s_playCallback();
}

extern "C" JNIEXPORT void JNICALL Java_cyou_tortu_client_MediaService_onPauseClicked(JNIEnv *, jclass) {
    if (s_pauseCallback) s_pauseCallback();
}

extern "C" JNIEXPORT void JNICALL Java_cyou_tortu_client_MediaService_onNextClicked(JNIEnv *, jclass) {
    if (s_nextCallback) s_nextCallback();
}

extern "C" JNIEXPORT void JNICALL Java_cyou_tortu_client_MediaService_onPrevClicked(JNIEnv *, jclass) {
    if (s_prevCallback) s_prevCallback();
}

void initAndroidAudioSession(void (*playCallback)(), void (*pauseCallback)(), void (*nextCallback)(), void (*prevCallback)()) {
    s_playCallback = playCallback;
    s_pauseCallback = pauseCallback;
    s_nextCallback = nextCallback;
    s_prevCallback = prevCallback;

    // Register natives dynamically
    QJniEnvironment env;
    jclass clazz = env->FindClass("cyou/tortu/client/MediaService");
    if (clazz) {
        JNINativeMethod methods[] = {
            {(char *)"onPlayClicked", (char *)"()V", (void *)Java_cyou_tortu_client_MediaService_onPlayClicked},
            {(char *)"onPauseClicked", (char *)"()V", (void *)Java_cyou_tortu_client_MediaService_onPauseClicked},
            {(char *)"onNextClicked", (char *)"()V", (void *)Java_cyou_tortu_client_MediaService_onNextClicked},
            {(char *)"onPrevClicked", (char *)"()V", (void *)Java_cyou_tortu_client_MediaService_onPrevClicked}
        };
        env->RegisterNatives(clazz, methods, sizeof(methods) / sizeof(methods[0]));
        env->DeleteLocalRef(clazz);
    }
}

void updateAndroidNowPlayingInfo(const QString &title, const QString &artist, bool isPlaying, qint64 duration, qint64 position) {
    QJniObject activity = QJniObject::queryActivity();
    if (!activity.isValid()) return;

    QJniObject jTitle = QJniObject::fromString(title);
    QJniObject jArtist = QJniObject::fromString(artist);

    QJniObject::callStaticMethod<void>(
        "cyou/tortu/client/MediaService",
        "updateState",
        "(Landroid/content/Context;Ljava/lang/String;Ljava/lang/String;ZJJ)V",
        activity.object(),
        jTitle.object<jstring>(),
        jArtist.object<jstring>(),
        isPlaying,
        (jlong)duration,
        (jlong)position
    );
}

#endif // Q_OS_ANDROID
