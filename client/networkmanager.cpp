#include "networkmanager.h"
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>
#include <QUrlQuery>
#include <QFileInfo>
#include <QMimeDatabase>
#include <QNetworkProxy>
#include <QBuffer>
#include <QDebug>
#include <QClipboard>
#include <QGuiApplication>

NetworkManager::NetworkManager(QObject *parent)
    : QObject(parent)
    , m_networkManager(new QNetworkAccessManager(this))
    , m_isLoggedIn(false)
    , m_apiBaseUrl("https://server.tortu.cyou/spotify/")
{
    m_networkManager->setProxy(QNetworkProxy::NoProxy);
}

void NetworkManager::setIsLoggedIn(bool val)
{
    if (m_isLoggedIn != val) {
        m_isLoggedIn = val;
        emit isLoggedInChanged();
    }
}

QNetworkRequest NetworkManager::createRequest(const QString &endpoint)
{
    QNetworkRequest request(QUrl(m_apiBaseUrl + endpoint));
    request.setHeader(QNetworkRequest::ContentTypeHeader, "application/json");
    request.setRawHeader("Connection", "close");
    if (!m_token.isEmpty()) {
        request.setRawHeader("Authorization", "Bearer " + m_token.toUtf8());
    }
    return request;
}

void NetworkManager::login(const QString &username, const QString &password)
{
    QJsonObject jsonObj;
    jsonObj["username"] = username;
    jsonObj["password"] = password;
    
    QNetworkRequest request = createRequest("auth.php?action=login");
    QNetworkReply *reply = m_networkManager->post(request, QJsonDocument(jsonObj).toJson());
    
    connect(reply, &QNetworkReply::finished, this, [this, reply]() {
        handleLoginReply(reply);
    });
}

void NetworkManager::handleLoginReply(QNetworkReply *reply)
{
    reply->deleteLater();
    if (reply->error() != QNetworkReply::NoError) {
        QString errStr = reply->readAll();
        QJsonDocument doc = QJsonDocument::fromJson(errStr.toUtf8());
        QString errMsg = doc.isObject() ? doc.object().value("error").toString() : reply->errorString();
        emit loginFailed(errMsg.isEmpty() ? reply->errorString() : errMsg);
        return;
    }
    
    QByteArray data = reply->readAll();
    QJsonDocument doc = QJsonDocument::fromJson(data);
    if (doc.isObject()) {
        QJsonObject obj = doc.object();
        m_token = obj.value("token").toString();
        m_username = obj.value("user").toObject().value("username").toString();
        m_avatarUrl = obj.value("user").toObject().value("avatar_url").toString();
        setIsLoggedIn(true);
        emit tokenChanged();
        emit usernameChanged();
        emit avatarUrlChanged();
        emit loginSuccess(m_username);
    } else {
        emit loginFailed("Invalid response from server");
    }
}

void NetworkManager::registerUser(const QString &username, const QString &password)
{
    QJsonObject jsonObj;
    jsonObj["username"] = username;
    jsonObj["password"] = password;
    
    QNetworkRequest request = createRequest("auth.php?action=register");
    QNetworkReply *reply = m_networkManager->post(request, QJsonDocument(jsonObj).toJson());
    
    connect(reply, &QNetworkReply::finished, this, [this, reply]() {
        reply->deleteLater();
        if (reply->error() != QNetworkReply::NoError) {
            QString errStr = reply->readAll();
            QJsonDocument doc = QJsonDocument::fromJson(errStr.toUtf8());
            QString errMsg = doc.isObject() ? doc.object().value("error").toString() : reply->errorString();
            emit registerFailed(errMsg.isEmpty() ? reply->errorString() : errMsg);
            return;
        }
        emit registerSuccess();
    });
}

void NetworkManager::logout()
{
    QNetworkRequest request = createRequest("auth.php?action=logout");
    QNetworkReply *reply = m_networkManager->post(request, QByteArray());
    
    connect(reply, &QNetworkReply::finished, this, [this, reply]() {
        reply->deleteLater();
        m_token.clear();
        m_username.clear();
        setIsLoggedIn(false);
        emit tokenChanged();
        emit usernameChanged();
    });
}

void NetworkManager::fetchTracks(const QString &searchQuery)
{
    QString endpoint = "tracks.php";
    if (!searchQuery.isEmpty()) {
        QUrlQuery query;
        query.addQueryItem("q", searchQuery);
        endpoint += "?" + query.toString();
    }
    
    QNetworkRequest request = createRequest(endpoint);
    QNetworkReply *reply = m_networkManager->get(request);
    
    connect(reply, &QNetworkReply::finished, this, [this, reply]() {
        handleTracksReply(reply);
    });
}

void NetworkManager::fetchFavorites()
{
    QNetworkRequest request = createRequest("tracks.php?favorites=1");
    QNetworkReply *reply = m_networkManager->get(request);
    
    connect(reply, &QNetworkReply::finished, this, [this, reply]() {
        handleTracksReply(reply);
    });
}

void NetworkManager::handleTracksReply(QNetworkReply *reply)
{
    reply->deleteLater();
    if (reply->error() != QNetworkReply::NoError) {
        qWarning() << "Fetch tracks error:" << reply->errorString();
        emit tracksLoaded(QVariantList());
        return;
    }
    
    QByteArray data = reply->readAll();
    QJsonDocument doc = QJsonDocument::fromJson(data);
    if (doc.isArray()) {
        emit tracksLoaded(doc.array().toVariantList());
    } else {
        emit tracksLoaded(QVariantList());
    }
}

void NetworkManager::toggleFavorite(int trackId)
{
    QJsonObject jsonObj;
    jsonObj["track_id"] = trackId;
    
    QNetworkRequest request = createRequest("favorites.php");
    QNetworkReply *reply = m_networkManager->post(request, QJsonDocument(jsonObj).toJson());
    
    connect(reply, &QNetworkReply::finished, this, [this, reply, trackId]() {
        handleFavoriteReply(reply, trackId);
    });
}

void NetworkManager::handleFavoriteReply(QNetworkReply *reply, int trackId)
{
    reply->deleteLater();
    if (reply->error() != QNetworkReply::NoError) {
        qWarning() << "Toggle favorite error:" << reply->errorString();
        return;
    }
    
    QByteArray data = reply->readAll();
    QJsonDocument doc = QJsonDocument::fromJson(data);
    if (doc.isObject()) {
        QJsonObject obj = doc.object();
        bool isFavorite = obj.value("is_favorite").toInt() == 1;
        emit favoriteToggled(trackId, isFavorite);
    }
}

void NetworkManager::uploadTrack(const QString &title, const QString &artist, const QString &album, const QString &lyrics, const QString &audioPath, const QString &coverPath)
{
    QHttpMultiPart *multiPart = new QHttpMultiPart(QHttpMultiPart::FormDataType);
    
    // Title
    QHttpPart titlePart;
    titlePart.setHeader(QNetworkRequest::ContentDispositionHeader, QVariant("form-data; name=\"title\""));
    titlePart.setBody(title.toUtf8());
    multiPart->append(titlePart);
    
    // Artist
    QHttpPart artistPart;
    artistPart.setHeader(QNetworkRequest::ContentDispositionHeader, QVariant("form-data; name=\"artist\""));
    artistPart.setBody(artist.toUtf8());
    multiPart->append(artistPart);
    
    // Album
    QHttpPart albumPart;
    albumPart.setHeader(QNetworkRequest::ContentDispositionHeader, QVariant("form-data; name=\"album\""));
    albumPart.setBody(album.toUtf8());
    multiPart->append(albumPart);
    
    // Lyrics
    QHttpPart lyricsPart;
    lyricsPart.setHeader(QNetworkRequest::ContentDispositionHeader, QVariant("form-data; name=\"lyrics\""));
    lyricsPart.setBody(lyrics.toUtf8());
    multiPart->append(lyricsPart);
    
    // Audio File
    QString cleanAudioPath = audioPath;
    if (cleanAudioPath.startsWith("file://")) {
        cleanAudioPath = QUrl(cleanAudioPath).toLocalFile();
    }
    QFile *audioFile = new QFile(cleanAudioPath);
    if (!audioFile->open(QIODevice::ReadOnly)) {
        emit uploadFailed("Cannot open audio file: " + cleanAudioPath);
        delete multiPart;
        delete audioFile;
        return;
    }
    
    QHttpPart audioFilePart;
    QMimeDatabase mimeDb;
    QString audioMime = mimeDb.mimeTypeForFile(cleanAudioPath).name();
    audioFilePart.setHeader(QNetworkRequest::ContentTypeHeader, QVariant(audioMime));
    audioFilePart.setHeader(QNetworkRequest::ContentDispositionHeader,
        QVariant(QString("form-data; name=\"audio\"; filename=\"%1\"").arg(QFileInfo(cleanAudioPath).fileName())));
    audioFilePart.setBodyDevice(audioFile);
    audioFile->setParent(multiPart); // Delete file with multipart
    multiPart->append(audioFilePart);
    
    // Cover File (Optional)
    if (!coverPath.isEmpty()) {
        QString cleanCoverPath = coverPath;
        if (cleanCoverPath.startsWith("file://")) {
            cleanCoverPath = QUrl(cleanCoverPath).toLocalFile();
        }
        QFile *coverFile = new QFile(cleanCoverPath);
        if (coverFile->open(QIODevice::ReadOnly)) {
            QHttpPart coverFilePart;
            QString coverMime = mimeDb.mimeTypeForFile(cleanCoverPath).name();
            coverFilePart.setHeader(QNetworkRequest::ContentTypeHeader, QVariant(coverMime));
            coverFilePart.setHeader(QNetworkRequest::ContentDispositionHeader,
                QVariant(QString("form-data; name=\"cover\"; filename=\"%1\"").arg(QFileInfo(cleanCoverPath).fileName())));
            coverFilePart.setBodyDevice(coverFile);
            coverFile->setParent(multiPart);
            multiPart->append(coverFilePart);
        } else {
            delete coverFile;
        }
    }
    
    // Create request
    QNetworkRequest request(QUrl(m_apiBaseUrl + "upload.php"));
    if (!m_token.isEmpty()) {
        request.setRawHeader("Authorization", "Bearer " + m_token.toUtf8());
    }
    
    QNetworkReply *reply = m_networkManager->post(request, multiPart);
    multiPart->setParent(reply); // Delete multipart with reply
    
    connect(reply, &QNetworkReply::uploadProgress, this, [this](qint64 bytesSent, qint64 bytesTotal) {
        emit uploadProgress(bytesSent, bytesTotal);
    });
    
    connect(reply, &QNetworkReply::finished, this, [this, reply]() {
        handleUploadReply(reply);
    });
}

void NetworkManager::handleUploadReply(QNetworkReply *reply)
{
    reply->deleteLater();
    if (reply->error() != QNetworkReply::NoError) {
        QString errStr = reply->readAll();
        QJsonDocument doc = QJsonDocument::fromJson(errStr.toUtf8());
        QString errMsg = doc.isObject() ? doc.object().value("error").toString() : reply->errorString();
        emit uploadFailed(errMsg.isEmpty() ? reply->errorString() : errMsg);
        return;
    }
    emit uploadSuccess();
}

void NetworkManager::fetchPlaylists(const QString &searchQuery)
{
    if (searchQuery.isEmpty()) {
        QNetworkRequest request = createRequest("playlists.php");
        QNetworkReply *reply = m_networkManager->get(request);
        connect(reply, &QNetworkReply::finished, this, [this, reply]() {
            handlePlaylistsReply(reply);
        });
    } else {
        QUrlQuery query;
        query.addQueryItem("q", searchQuery);
        QNetworkRequest request = createRequest("playlists.php?" + query.toString());
        QNetworkReply *reply = m_networkManager->get(request);
        connect(reply, &QNetworkReply::finished, this, [this, reply]() {
            reply->deleteLater();
            if (reply->error() != QNetworkReply::NoError) {
                qWarning() << "Search playlists error:" << reply->errorString();
                emit searchPlaylistsLoaded(QVariantList());
                return;
            }
            QByteArray data = reply->readAll();
            QJsonDocument doc = QJsonDocument::fromJson(data);
            if (doc.isArray()) {
                emit searchPlaylistsLoaded(doc.array().toVariantList());
            } else {
                emit searchPlaylistsLoaded(QVariantList());
            }
        });
    }
}

void NetworkManager::handlePlaylistsReply(QNetworkReply *reply)
{
    reply->deleteLater();
    if (reply->error() != QNetworkReply::NoError) {
        qWarning() << "Fetch playlists error:" << reply->errorString();
        emit playlistsLoaded(QVariantList());
        return;
    }
    
    QByteArray data = reply->readAll();
    QJsonDocument doc = QJsonDocument::fromJson(data);
    if (doc.isArray()) {
        emit playlistsLoaded(doc.array().toVariantList());
    } else {
        emit playlistsLoaded(QVariantList());
    }
}

void NetworkManager::createPlaylist(const QString &name, const QString &coverPath)
{
    if (coverPath.isEmpty()) {
        QJsonObject jsonObj;
        jsonObj["name"] = name;
        QNetworkRequest request = createRequest("playlists.php");
        QNetworkReply *reply = m_networkManager->post(request, QJsonDocument(jsonObj).toJson());
        connect(reply, &QNetworkReply::finished, this, [this, reply]() {
            handleCreatePlaylistReply(reply);
        });
        return;
    }

    QHttpMultiPart *multiPart = new QHttpMultiPart(QHttpMultiPart::FormDataType);
    
    QHttpPart namePart;
    namePart.setHeader(QNetworkRequest::ContentDispositionHeader, QVariant("form-data; name=\"name\""));
    namePart.setBody(name.toUtf8());
    multiPart->append(namePart);

    QString cleanCoverPath = coverPath;
    if (cleanCoverPath.startsWith("file://")) {
        cleanCoverPath = QUrl(cleanCoverPath).toLocalFile();
    }
    
    QFile *coverFile = new QFile(cleanCoverPath);
    if (!coverFile->open(QIODevice::ReadOnly)) {
        qWarning() << "Cannot open playlist cover file:" << cleanCoverPath;
        delete multiPart;
        delete coverFile;
        createPlaylist(name, "");
        return;
    }

    QMimeDatabase mimeDb;
    QString coverMime = mimeDb.mimeTypeForFile(cleanCoverPath).name();
    
    QHttpPart coverPart;
    coverPart.setHeader(QNetworkRequest::ContentTypeHeader, QVariant(coverMime));
    coverPart.setHeader(QNetworkRequest::ContentDispositionHeader,
        QVariant(QString("form-data; name=\"cover\"; filename=\"%1\"").arg(QFileInfo(cleanCoverPath).fileName())));
    coverPart.setBodyDevice(coverFile);
    coverFile->setParent(multiPart);
    multiPart->append(coverPart);

    QNetworkRequest request(QUrl(m_apiBaseUrl + "playlists.php"));
    if (!m_token.isEmpty()) {
        request.setRawHeader("Authorization", "Bearer " + m_token.toUtf8());
    }
    
    QNetworkReply *reply = m_networkManager->post(request, multiPart);
    multiPart->setParent(reply);
    
    connect(reply, &QNetworkReply::finished, this, [this, reply]() {
        handleCreatePlaylistReply(reply);
    });
}

void NetworkManager::handleCreatePlaylistReply(QNetworkReply *reply)
{
    reply->deleteLater();
    if (reply->error() != QNetworkReply::NoError) {
        qWarning() << "Create playlist error:" << reply->errorString();
        return;
    }
    
    QByteArray data = reply->readAll();
    QJsonDocument doc = QJsonDocument::fromJson(data);
    if (doc.isObject()) {
        QJsonObject obj = doc.object();
        QJsonObject plObj = obj.value("playlist").toObject();
        int id = plObj.value("id").toInt();
        QString name = plObj.value("name").toString();
        emit playlistCreated(id, name);
    }
}

void NetworkManager::copyToClipboard(const QString &text)
{
    QClipboard *clipboard = QGuiApplication::clipboard();
    if (clipboard) {
        clipboard->setText(text);
    }
}

void NetworkManager::deletePlaylist(int playlistId)
{
    QJsonObject jsonObj;
    jsonObj["playlist_id"] = playlistId;
    
    QNetworkRequest request = createRequest("playlists.php");
    QBuffer *buffer = new QBuffer(this);
    buffer->setData(QJsonDocument(jsonObj).toJson());
    buffer->open(QIODevice::ReadOnly);
    
    QNetworkReply *reply = m_networkManager->sendCustomRequest(request, "DELETE", buffer);
    buffer->setParent(reply);
    
    connect(reply, &QNetworkReply::finished, this, [this, reply, playlistId]() {
        handleDeletePlaylistReply(reply, playlistId);
    });
}

void NetworkManager::handleDeletePlaylistReply(QNetworkReply *reply, int playlistId)
{
    reply->deleteLater();
    if (reply->error() != QNetworkReply::NoError) {
        qWarning() << "Delete playlist error:" << reply->errorString();
        return;
    }
    emit playlistDeleted(playlistId);
}

void NetworkManager::addTrackToPlaylist(int playlistId, int trackId)
{
    QJsonObject jsonObj;
    jsonObj["playlist_id"] = playlistId;
    jsonObj["track_id"] = trackId;
    
    QNetworkRequest request = createRequest("playlists.php?action=add_track");
    QNetworkReply *reply = m_networkManager->post(request, QJsonDocument(jsonObj).toJson());
    
    connect(reply, &QNetworkReply::finished, this, [this, reply, playlistId, trackId]() {
        reply->deleteLater();
        if (reply->error() != QNetworkReply::NoError) {
            qWarning() << "Add track to playlist error:" << reply->errorString();
        } else {
            emit trackAddedToPlaylist(playlistId, trackId);
        }
    });
}

void NetworkManager::removeTrackFromPlaylist(int playlistId, int trackId)
{
    QJsonObject jsonObj;
    jsonObj["playlist_id"] = playlistId;
    jsonObj["track_id"] = trackId;
    
    QNetworkRequest request = createRequest("playlists.php?action=remove_track");
    QNetworkReply *reply = m_networkManager->post(request, QJsonDocument(jsonObj).toJson());
    
    connect(reply, &QNetworkReply::finished, this, [this, reply, playlistId, trackId]() {
        reply->deleteLater();
        if (reply->error() != QNetworkReply::NoError) {
            qWarning() << "Remove track from playlist error:" << reply->errorString();
        } else {
            emit trackRemovedFromPlaylist(playlistId, trackId);
        }
    });
}

void NetworkManager::fetchPlaylistTracks(int playlistId)
{
    QNetworkRequest request = createRequest(QString("playlists.php?playlist_id=%1").arg(playlistId));
    QNetworkReply *reply = m_networkManager->get(request);
    
    connect(reply, &QNetworkReply::finished, this, [this, reply, playlistId]() {
        handlePlaylistTracksReply(reply, playlistId);
    });
}

void NetworkManager::handlePlaylistTracksReply(QNetworkReply *reply, int playlistId)
{
    reply->deleteLater();
    if (reply->error() != QNetworkReply::NoError) {
        qWarning() << "Fetch playlist tracks error:" << reply->errorString();
        emit playlistTracksLoaded(playlistId, QVariantList());
        return;
    }
    
    QByteArray data = reply->readAll();
    QJsonDocument doc = QJsonDocument::fromJson(data);
    if (doc.isObject()) {
        QJsonObject obj = doc.object();
        QJsonArray tracksArr = obj.value("tracks").toArray();
        QJsonObject playlistObj = obj.value("playlist").toObject();
        emit playlistDetailsLoaded(playlistObj.toVariantMap());
        emit playlistTracksLoaded(playlistId, tracksArr.toVariantList());
    } else {
        emit playlistTracksLoaded(playlistId, QVariantList());
    }
}

void NetworkManager::setAvatarUrl(const QString &url)
{
    if (m_avatarUrl != url) {
        m_avatarUrl = url;
        emit avatarUrlChanged();
    }
}

void NetworkManager::updateAvatar(const QString &avatarPath)
{
    QHttpMultiPart *multiPart = new QHttpMultiPart(QHttpMultiPart::FormDataType);
    
    QString cleanPath = avatarPath;
    if (cleanPath.startsWith("file://")) {
        cleanPath = QUrl(cleanPath).toLocalFile();
    }
    
    QFile *file = new QFile(cleanPath);
    if (!file->open(QIODevice::ReadOnly)) {
        qWarning() << "Cannot open avatar file:" << cleanPath;
        delete multiPart;
        delete file;
        return;
    }
    
    QMimeDatabase mimeDb;
    QString mime = mimeDb.mimeTypeForFile(cleanPath).name();
    
    QHttpPart part;
    part.setHeader(QNetworkRequest::ContentTypeHeader, QVariant(mime));
    part.setHeader(QNetworkRequest::ContentDispositionHeader,
        QVariant(QString("form-data; name=\"avatar\"; filename=\"%1\"").arg(QFileInfo(cleanPath).fileName())));
    part.setBodyDevice(file);
    file->setParent(multiPart);
    multiPart->append(part);
    
    QNetworkRequest request = createRequest("auth.php?action=update_avatar");
    request.setHeader(QNetworkRequest::ContentTypeHeader, QVariant()); // Clear Content-Type to let MultiPart set it
    
    QNetworkReply *reply = m_networkManager->post(request, multiPart);
    multiPart->setParent(reply);
    
    connect(reply, &QNetworkReply::finished, this, [this, reply]() {
        reply->deleteLater();
        if (reply->error() != QNetworkReply::NoError) {
            qWarning() << "Update avatar failed:" << reply->errorString();
            return;
        }
        QByteArray data = reply->readAll();
        QJsonDocument doc = QJsonDocument::fromJson(data);
        if (doc.isObject()) {
            QString newUrl = doc.object().value("avatar_url").toString();
            setAvatarUrl(newUrl);
        }
    });
}
