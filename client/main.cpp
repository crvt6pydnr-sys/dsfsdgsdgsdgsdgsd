#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QNetworkProxy>
#include "networkmanager.h"
#include "audioplayer.h"

int main(int argc, char *argv[])
{
    // Globally disable system proxies for all network requests (including QML Images)
    QNetworkProxy::setApplicationProxy(QNetworkProxy::NoProxy);

    QGuiApplication app(argc, argv);
    app.setApplicationName("Tortu");
    app.setOrganizationName("Antigravity");

    qmlRegisterType<NetworkManager>("Tortu", 1, 0, "NetworkManager");
    qmlRegisterType<AudioPlayer>("Tortu", 1, 0, "AudioPlayer");

    QQmlApplicationEngine engine;
    
    const QUrl url(u"qrc:/Tortu/main.qml"_qs);
    QObject::connect(&engine, &QQmlApplicationEngine::objectCreated,
                     &app, [url](QObject *obj, const QUrl &objUrl) {
        if (!obj && url == objUrl)
            QCoreApplication::exit(-1);
    }, Qt::QueuedConnection);
    
    engine.load(url);

    return app.exec();
}
