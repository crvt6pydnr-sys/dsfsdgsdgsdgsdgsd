#ifndef NETWORKMANAGER_H
#define NETWORKMANAGER_H

#include <QObject>
#include <QNetworkAccessManager>
#include <QNetworkReply>
#include <QVariantList>
#include <QHttpMultiPart>

class NetworkManager : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool isLoggedIn READ isLoggedIn WRITE setIsLoggedIn NOTIFY isLoggedInChanged)
    Q_PROPERTY(QString username READ username NOTIFY usernameChanged)
    Q_PROPERTY(QString token READ token NOTIFY tokenChanged)
    Q_PROPERTY(QString avatarUrl READ avatarUrl WRITE setAvatarUrl NOTIFY avatarUrlChanged)

public:
    explicit NetworkManager(QObject *parent = nullptr);

    bool isLoggedIn() const { return m_isLoggedIn; }
    void setIsLoggedIn(bool val);
    QString username() const { return m_username; }
    QString token() const { return m_token; }
    QString avatarUrl() const { return m_avatarUrl; }
    void setAvatarUrl(const QString &url);

    Q_INVOKABLE void login(const QString &username, const QString &password);
    Q_INVOKABLE void registerUser(const QString &username, const QString &password);
    Q_INVOKABLE void logout();
    Q_INVOKABLE void fetchTracks(const QString &searchQuery = "");
    Q_INVOKABLE void fetchFavorites();
    Q_INVOKABLE void toggleFavorite(int trackId);
    Q_INVOKABLE void uploadTrack(const QString &title, const QString &artist, const QString &album, const QString &lyrics, const QString &audioPath, const QString &coverPath);
    Q_INVOKABLE void updateAvatar(const QString &avatarPath);
    
    // Playlists
    Q_INVOKABLE void fetchPlaylists(const QString &searchQuery = "");
    Q_INVOKABLE void createPlaylist(const QString &name, const QString &coverPath = "");
    Q_INVOKABLE void deletePlaylist(int playlistId);
    Q_INVOKABLE void addTrackToPlaylist(int playlistId, int trackId);
    Q_INVOKABLE void removeTrackFromPlaylist(int playlistId, int trackId);
    Q_INVOKABLE void fetchPlaylistTracks(int playlistId);
    
    // Clipboard helper for sharing playlist links
    Q_INVOKABLE void copyToClipboard(const QString &text);

signals:
    void isLoggedInChanged();
    void usernameChanged();
    void tokenChanged();
    void avatarUrlChanged();
    
    void loginSuccess(const QString &username);
    void loginFailed(const QString &error);
    
    void registerSuccess();
    void registerFailed(const QString &error);
    
    void uploadSuccess();
    void uploadProgress(qint64 bytesSent, qint64 bytesTotal);
    void uploadFailed(const QString &error);
    
    void tracksLoaded(const QVariantList &tracks);
    void favoriteToggled(int trackId, bool isFavorite);
    
    // Playlist Signals
    void playlistsLoaded(const QVariantList &playlists);
    void searchPlaylistsLoaded(const QVariantList &playlists);
    void playlistCreated(int playlistId, const QString &name);
    void playlistDeleted(int playlistId);
    void playlistTracksLoaded(int playlistId, const QVariantList &tracks);
    void playlistDetailsLoaded(const QVariantMap &playlist);
    void trackAddedToPlaylist(int playlistId, int trackId);
    void trackRemovedFromPlaylist(int playlistId, int trackId);

private:
    QNetworkAccessManager *m_networkManager;
    bool m_isLoggedIn;
    QString m_username;
    QString m_token;
    QString m_avatarUrl;
    QString m_apiBaseUrl;

    QNetworkRequest createRequest(const QString &endpoint);
    void handleLoginReply(QNetworkReply *reply);
    void handleRegisterReply(QNetworkReply *reply);
    void handleTracksReply(QNetworkReply *reply);
    void handleFavoriteReply(QNetworkReply *reply, int trackId);
    void handleUploadReply(QNetworkReply *reply);
    
    // Playlist Handlers
    void handlePlaylistsReply(QNetworkReply *reply);
    void handleCreatePlaylistReply(QNetworkReply *reply);
    void handleDeletePlaylistReply(QNetworkReply *reply, int playlistId);
    void handlePlaylistTracksReply(QNetworkReply *reply, int playlistId);
};

#endif // NETWORKMANAGER_H
