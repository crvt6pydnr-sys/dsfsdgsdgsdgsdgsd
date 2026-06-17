import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs

Rectangle {
    id: mainScreen
    color: "#000000"
    anchors.fill: parent

    required property var networkManager
    required property var player

    property string activeTab: "search" // home, search, favorites, playlist_X
    property var currentTrack: null
    property bool showLyrics: false
    property var tracks: []
    property var playlists: []
    property var searchedPlaylists: []
    property string playlistCoverPath: ""
    property var activePlaylistDetails: null
    property bool isMobile: width < 650

    onActiveTabChanged: {
        activePlaylistDetails = null
    }

    function getCurrentPlaylist() {
        if (!activeTab.startsWith("playlist_")) return null;
        var plId = parseInt(activeTab.substring(9));
        for (var i = 0; i < playlists.length; i++) {
            if (playlists[i].id === plId) return playlists[i];
        }
        return null;
    }

    // Refresh track lists helper
    function refreshTracks() {
        if (activeTab === "home") {
            networkManager.fetchTracks()
        } else if (activeTab === "favorites") {
            networkManager.fetchFavorites()
        } else if (activeTab === "search") {
            networkManager.fetchTracks(searchField.text)
        } else if (activeTab.startsWith("playlist_")) {
            var plId = parseInt(activeTab.substring(9))
            networkManager.fetchPlaylistTracks(plId)
        }
    }

    function playNextTrack() {
        if (tracks.length === 0) return;
        var nextIdx = 0;
        if (currentTrack) {
            var currIdx = -1;
            for (var i = 0; i < tracks.length; i++) {
                if (tracks[i].id === currentTrack.id) {
                    currIdx = i;
                    break;
                }
            }
            if (currIdx !== -1) {
                nextIdx = (currIdx + 1) % tracks.length;
            }
        }
        playTrackAt(nextIdx);
    }

    // Prev track action
    function playPrevTrack() {
        if (tracks.length === 0) return;
        var prevIdx = 0;
        if (currentTrack) {
            var currIdx = -1;
            for (var i = 0; i < tracks.length; i++) {
                if (tracks[i].id === currentTrack.id) {
                    currIdx = i;
                    break;
                }
            }
            if (currIdx !== -1) {
                prevIdx = (currIdx - 1 + tracks.length) % tracks.length;
            }
        }
        playTrackAt(prevIdx);
    }

    // Play track at specific index of current tracks list
    function playTrackAt(idx) {
        if (idx >= 0 && idx < tracks.length) {
            var track = tracks[idx];
            mainScreen.currentTrack = track;
            player.source = track.audio_url;
            player.play();
        }
    }

    Connections {
        target: networkManager
        
        function onTracksLoaded(tracksList) {
            mainScreen.tracks = tracksList
        }

        function onPlaylistsLoaded(playlistsList) {
            mainScreen.playlists = playlistsList
        }

        function onSearchPlaylistsLoaded(playlistsList) {
            mainScreen.searchedPlaylists = playlistsList
        }

        function onPlaylistDetailsLoaded(playlistMap) {
            mainScreen.activePlaylistDetails = playlistMap
        }

        function onPlaylistCreated(id, name) {
            networkManager.fetchPlaylists()
        }

        function onPlaylistDeleted(id) {
            if (activeTab === "playlist_" + id) {
                activeTab = "search"
                networkManager.fetchTracks()
            }
            networkManager.fetchPlaylists()
        }

        function onPlaylistTracksLoaded(playlistId, tracksList) {
            if (activeTab === "playlist_" + playlistId) {
                mainScreen.tracks = tracksList
            }
        }

        function onTrackAddedToPlaylist(playlistId, trackId) {
            if (activeTab === "playlist_" + playlistId) {
                networkManager.fetchPlaylistTracks(playlistId)
            }
        }

        function onTrackRemovedFromPlaylist(playlistId, trackId) {
            if (activeTab === "playlist_" + playlistId) {
                networkManager.fetchPlaylistTracks(playlistId)
            }
        }
        
        function onFavoriteToggled(trackId, isFavorite) {
            // Update current track if it was favorited
            if (currentTrack && currentTrack.id === trackId) {
                var updatedTrack = currentTrack
                updatedTrack.is_favorite = isFavorite ? 1 : 0
                currentTrack = null // Trigger UI update
                currentTrack = updatedTrack
            }
            // Update list items locally
            var updatedTracks = []
            for (var i = 0; i < tracks.length; i++) {
                var item = tracks[i]
                if (item.id === trackId) {
                    item.is_favorite = isFavorite ? 1 : 0;
                }
                updatedTracks.push(item)
            }
            tracks = updatedTracks
        }
    }

    Connections {
        target: player
        function onFinished() {
            mainScreen.playNextTrack()
        }
    }

    Component.onCompleted: {
        networkManager.fetchTracks()
        networkManager.fetchPlaylists()
    }

    // Context Menu for Tracks
    Menu {
        id: trackContextMenu
        property var targetTrack: null

        MenuItem {
            text: trackContextMenu.targetTrack ? (trackContextMenu.targetTrack.is_favorite ? "Remove from Favorites" : "Add to Favorites") : ""
            onTriggered: {
                if (trackContextMenu.targetTrack) {
                    networkManager.toggleFavorite(trackContextMenu.targetTrack.id)
                }
            }
        }

        Menu {
            id: addToPlaylistMenu
            title: "Add to Playlist"
            visible: mainScreen.playlists.length > 0
            
            Instantiator {
                model: mainScreen.playlists
                onObjectAdded: (index, object) => addToPlaylistMenu.insertItem(index, object)
                onObjectRemoved: (index, object) => addToPlaylistMenu.removeItem(object)
                
                delegate: MenuItem {
                    property int playlistId: modelData.id
                    property string playlistName: modelData.name
                    text: playlistName
                    onTriggered: {
                        if (trackContextMenu.targetTrack) {
                            networkManager.addTrackToPlaylist(playlistId, trackContextMenu.targetTrack.id)
                        }
                    }
                }
            }
        }

        MenuItem {
            text: "Remove from Playlist"
            visible: mainScreen.activeTab.startsWith("playlist_")
            onTriggered: {
                if (trackContextMenu.targetTrack && mainScreen.activeTab.startsWith("playlist_")) {
                    var plId = parseInt(mainScreen.activeTab.substring(9))
                    networkManager.removeTrackFromPlaylist(plId, trackContextMenu.targetTrack.id)
                    timerPlaylistRefresh.start()
                }
            }
        }
    }

    // Context Menu for Playlists
    Menu {
        id: playlistContextMenu
        property var targetPlaylist: null

        MenuItem {
            text: "Delete Playlist"
            visible: playlistContextMenu.targetPlaylist && (playlistContextMenu.targetPlaylist.creator === networkManager.username || !playlistContextMenu.targetPlaylist.creator)
            onTriggered: {
                if (playlistContextMenu.targetPlaylist) {
                    networkManager.deletePlaylist(playlistContextMenu.targetPlaylist.id)
                }
            }
        }
    }

    Timer {
        id: timerPlaylistRefresh
        interval: 300
        onTriggered: mainScreen.refreshTracks()
    }

    Row {
        id: mainRow
        width: parent.width
        height: parent.height - playerBar.height - (isMobile ? 60 : 0)

        // 1. SIDEBAR (Left)
        Rectangle {
            id: sidebar
            width: isMobile ? 0 : 240
            height: parent.height
            color: "#000000"
            visible: !isMobile

            Column {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 20

                // Tortu Brand Logo (SVG)
                Image {
                    source: "qrc:/Tortu/icons/logo.svg"
                    width: 120
                    height: 40
                    fillMode: Image.PreserveAspectFit
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                // Menu items
                Column {
                    width: parent.width
                    spacing: 8

                    // Home Button
                    Button {
                        id: homeBtn
                        width: parent.width
                        height: 36
                        background: Rectangle { color: "transparent" }
                        contentItem: Row {
                            spacing: 16
                            Image {
                                source: "qrc:/Tortu/icons/home.svg"
                                width: 20; height: 20
                                anchors.verticalCenter: parent.verticalCenter
                            }
                            Text {
                                text: "Home"
                                color: activeTab === "home" ? "#FFFFFF" : (parent.parent.hovered ? "#FFFFFF" : "#B3B3B3")
                                font.bold: activeTab === "home"
                                font.pixelSize: 14
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }
                        onClicked: {
                            activeTab = "home"
                            networkManager.fetchTracks()
                        }
                    }

                    // Search Button
                    Button {
                        id: searchBtn
                        width: parent.width
                        height: 36
                        background: Rectangle { color: "transparent" }
                        contentItem: Row {
                            spacing: 16
                            Image {
                                source: "qrc:/Tortu/icons/search.svg"
                                width: 20; height: 20
                                anchors.verticalCenter: parent.verticalCenter
                            }
                            Text {
                                text: "Search"
                                color: activeTab === "search" ? "#FFFFFF" : (parent.parent.hovered ? "#FFFFFF" : "#B3B3B3")
                                font.bold: activeTab === "search"
                                font.pixelSize: 14
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }
                        onClicked: {
                            activeTab = "search"
                            networkManager.fetchTracks(searchField.text)
                        }
                    }

                    // Favorites Button
                    Button {
                        id: favsBtn
                        width: parent.width
                        height: 36
                        background: Rectangle { color: "transparent" }
                        contentItem: Row {
                            spacing: 16
                            Image {
                                source: "qrc:/Tortu/icons/heart-filled.svg"
                                width: 20; height: 20
                                anchors.verticalCenter: parent.verticalCenter
                            }
                            Text {
                                text: "Liked Songs"
                                color: activeTab === "favorites" ? "#FFFFFF" : (parent.parent.hovered ? "#FFFFFF" : "#B3B3B3")
                                font.bold: activeTab === "favorites"
                                font.pixelSize: 14
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }
                        onClicked: {
                            activeTab = "favorites"
                            networkManager.fetchFavorites()
                        }
                    }

                    // Upload Button (Moved here!)
                    Button {
                        id: uploadBtn
                        width: parent.width
                        height: 36
                        background: Rectangle { color: "transparent" }
                        contentItem: Row {
                            spacing: 16
                            Image {
                                source: "qrc:/Tortu/icons/upload.svg"
                                width: 20; height: 20
                                anchors.verticalCenter: parent.verticalCenter
                            }
                            Text {
                                text: "Upload Track"
                                color: activeTab === "upload" ? "#FFFFFF" : (parent.parent.hovered ? "#FFFFFF" : "#B3B3B3")
                                font.bold: activeTab === "upload"
                                font.pixelSize: 14
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }
                        onClicked: uploadOverlay.visible = true
                    }
                }

                // Divider line
                Rectangle {
                    width: parent.width
                    height: 1
                    color: "#282828"
                }

                // Playlists Header
                Row {
                    width: parent.width
                    Text {
                        text: "PLAYLISTS"
                        color: "#B3B3B3"
                        font.bold: true
                        font.pixelSize: 11
                        width: parent.width - 24
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Button {
                        width: 24
                        height: 24
                        anchors.verticalCenter: parent.verticalCenter
                        background: Rectangle { color: "transparent" }
                        contentItem: Text {
                            text: "+"
                            color: "#B3B3B3"
                            font.pixelSize: 20
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                        onClicked: createPlaylistOverlay.visible = true
                    }
                }

                // Scrollable Playlists list
                ScrollView {
                    id: playlistsScroll
                    width: parent.width
                    height: sidebar.height - 340 // dynamically sized
                    clip: true
                    ScrollBar.vertical.policy: ScrollBar.AsNeeded

                    Column {
                        width: playlistsScroll.width - 8
                        spacing: 4

                        Repeater {
                            model: mainScreen.playlists
                            delegate: Rectangle {
                                id: sidebarPlaylistBtn
                                width: parent.width
                                height: 36
                                color: sidebarPlaylistMouseArea.containsMouse ? "#1A1A1A" : "transparent"
                                radius: 0
                                
                                MouseArea {
                                    id: sidebarPlaylistMouseArea
                                    anchors.fill: parent
                                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                                    hoverEnabled: true
                                    onClicked: (mouse) => {
                                        if (mouse.button === Qt.RightButton) {
                                            playlistContextMenu.targetPlaylist = modelData
                                            playlistContextMenu.popup()
                                        } else {
                                            activeTab = "playlist_" + modelData.id
                                            networkManager.fetchPlaylistTracks(modelData.id)
                                        }
                                    }
                                }
                                
                                Row {
                                    spacing: 8
                                    anchors.fill: parent
                                    anchors.leftMargin: 8
                                    anchors.rightMargin: 8
                                    
                                    // Small cover image / icon
                                    Rectangle {
                                        width: 24
                                        height: 24
                                        radius: 0
                                        color: "#282828"
                                        clip: true
                                        anchors.verticalCenter: parent.verticalCenter
                                        
                                        Image {
                                            id: sideCoverImg
                                            anchors.fill: parent
                                            source: modelData.cover_url ? modelData.cover_url : ""
                                            fillMode: Image.PreserveAspectCrop
                                            visible: modelData.cover_url !== null && status === Image.Ready
                                        }
                                        
                                        Image {
                                            source: "qrc:/Tortu/icons/library.svg"
                                            width: 12
                                            height: 12
                                            anchors.centerIn: parent
                                            visible: !modelData.cover_url || sideCoverImg.status !== Image.Ready
                                        }
                                    }
                                    
                                    Text {
                                        text: modelData.name
                                        color: activeTab === "playlist_" + modelData.id ? "#1DB954" : (sidebarPlaylistMouseArea.containsMouse ? "#FFFFFF" : "#B3B3B3")
                                        font.bold: activeTab === "playlist_" + modelData.id
                                        font.pixelSize: 13
                                        elide: Text.ElideRight
                                        verticalAlignment: Text.AlignVCenter
                                        width: parent.width - 32
                                        anchors.verticalCenter: parent.verticalCenter
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        Rectangle {
            id: mainContent
            width: isMobile ? parent.width : (parent.width - sidebar.width - (showLyrics ? 300 : 0))
            height: parent.height
            color: "#121212"
            radius: 8
            clip: true

            Behavior on width {
                NumberAnimation { duration: 200 }
            }

            // Top navigation header bar
            Rectangle {
                id: topBar
                width: parent.width
                height: 64
                color: "#121212"
                anchors.top: parent.top
                z: 2

                Row {
                    anchors.fill: parent
                    anchors.leftMargin: 24
                    anchors.rightMargin: 24
                    spacing: 16

                    // Search input
                    TextField {
                        id: searchField
                        width: isMobile ? (topBar.width - userBadge.width - 96) : 300
                        height: 40
                        placeholderText: "What do you want to play?"
                        color: "#FFFFFF"
                        placeholderTextColor: "#727272"
                        anchors.verticalCenter: parent.verticalCenter
                        visible: activeTab === "search"
                        
                        background: Rectangle {
                            color: "#242424"
                            radius: 20
                            border.color: parent.activeFocus ? "#FFFFFF" : "transparent"
                            border.width: 1
                        }
                        
                        onTextChanged: {
                            networkManager.fetchTracks(text)
                            networkManager.fetchPlaylists(text)
                        }
                    }

                    // Mobile Upload button
                    Button {
                        id: uploadBtnMobile
                        width: 32
                        height: 32
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.right: userBadge.left
                        anchors.rightMargin: 12
                        visible: isMobile
                        background: Rectangle { color: "transparent" }
                        contentItem: Image {
                            source: "qrc:/Tortu/icons/upload.svg"
                            width: 20; height: 20
                            anchors.centerIn: parent
                        }
                        onClicked: uploadOverlay.visible = true
                    }

                    // User Badge
                    Rectangle {
                        id: userBadge
                        height: 32
                        width: userText.contentWidth + 44
                        color: userBadgeMouseArea.containsMouse ? "#282828" : "#000000"
                        radius: 16
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.right: parent.right

                        MouseArea {
                            id: userBadgeMouseArea
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: userMenu.popup(0, userBadge.height)
                        }

                        // Dropdown Menu
                        Menu {
                            id: userMenu
                            y: userBadge.height
                            
                            MenuItem {
                                text: "Change Avatar"
                                onTriggered: userAvatarDialog.open()
                            }
                            
                            MenuItem {
                                text: "Log Out"
                                onTriggered: networkManager.logout()
                            }
                        }

                        // File Dialog for Avatar Upload
                        FileDialog {
                            id: userAvatarDialog
                            title: "Select Profile Picture"
                            nameFilters: ["Image files (*.png *.jpg *.jpeg *.webp)"]
                            onAccepted: {
                                networkManager.updateAvatar(selectedFile.toString())
                            }
                        }

                        Item {
                            anchors.fill: parent
                            
                            // Avatar Icon / Custom Image
                            Rectangle {
                                id: avatarRect
                                width: 24; height: 24; radius: 12; color: "#535353"
                                anchors.left: parent.left
                                anchors.leftMargin: 4
                                anchors.verticalCenter: parent.verticalCenter
                                clip: true
                                layer.enabled: true
                                
                                Image {
                                    id: avatarCustomImage
                                    anchors.fill: parent
                                    fillMode: Image.PreserveAspectCrop
                                    source: networkManager.avatarUrl ? networkManager.avatarUrl : ""
                                    visible: networkManager.avatarUrl !== "" && avatarCustomImage.status === Image.Ready
                                }
                                
                                Image {
                                    source: "qrc:/Tortu/icons/user.svg"
                                    width: 14; height: 14
                                    anchors.centerIn: parent
                                    visible: networkManager.avatarUrl === "" || avatarCustomImage.status !== Image.Ready
                                }
                            }
                            
                            Text {
                                id: userText
                                text: networkManager.username
                                color: "#FFFFFF"
                                font.bold: true
                                font.pixelSize: 12
                                anchors.left: avatarRect.right
                                anchors.leftMargin: 8
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.verticalCenterOffset: 1.5 // nudge nickname down
                            }
                        }
                    }
                }
            }

            // Scrollable tracklist view
            ScrollView {
                id: mainScroll
                anchors.top: topBar.bottom
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                clip: true

                Column {
                    width: mainScroll.width - 24
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 24

                    // Header banner
                    Rectangle {
                        width: parent.width
                        height: activeTab === "favorites" ? 180 : 120
                        color: activeTab === "favorites" ? "#1A4C30" : (activeTab.startsWith("playlist_") ? "#3C4B64" : "#282828")
                        radius: 0
                        visible: activeTab !== "playlists"

                        Row {
                            anchors.fill: parent
                            anchors.margins: 24
                            spacing: 24

                            // Icon for headers
                            Rectangle {
                                width: (activeTab === "home" || activeTab === "search") ? 0 : (parent.height - 48)
                                height: width
                                radius: 0
                                color: activeTab === "favorites" ? "#1DB954" : "#535353"
                                anchors.verticalCenter: parent.verticalCenter
                                clip: true
                                visible: activeTab !== "home" && activeTab !== "search"
                                
                                Image {
                                    id: headerCoverImage
                                    anchors.fill: parent
                                    fillMode: Image.PreserveAspectCrop
                                    source: {
                                        if (activeTab.startsWith("playlist_")) {
                                            var pl = mainScreen.getCurrentPlaylist();
                                            if (pl && pl.cover_url) return pl.cover_url;
                                            if (mainScreen.activePlaylistDetails && mainScreen.activePlaylistDetails.id === parseInt(activeTab.substring(9)) && mainScreen.activePlaylistDetails.cover_url) {
                                                return mainScreen.activePlaylistDetails.cover_url;
                                            }
                                        }
                                        return "";
                                    }
                                    visible: source !== "" && status === Image.Ready
                                }

                                Image {
                                    source: {
                                        if (activeTab === "favorites") return "qrc:/Tortu/icons/heart-filled-white.svg";
                                        if (activeTab === "search") return "qrc:/Tortu/icons/search.svg";
                                        return "qrc:/Tortu/icons/library.svg";
                                    }
                                    width: activeTab === "favorites" ? 64 : 56
                                    height: width
                                    anchors.centerIn: parent
                                    visible: !headerCoverImage.visible
                                }
                            }

                            Column {
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 8

                                Button {
                                    visible: isMobile && activeTab.startsWith("playlist_")
                                    width: 140
                                    height: 24
                                    background: Rectangle { color: "transparent" }
                                    contentItem: Text {
                                        text: "← Back to Playlists"
                                        color: "#1DB954"
                                        font.bold: true
                                        font.pixelSize: 12
                                    }
                                    onClicked: {
                                        activeTab = "playlists"
                                        networkManager.fetchPlaylists()
                                    }
                                }

                                Text {
                                    text: activeTab.startsWith("playlist_") ? "PLAYLIST" : "COLLECTION"
                                    color: "#FFFFFF"
                                    font.pixelSize: 11
                                    font.bold: true
                                    visible: activeTab !== "home" && activeTab !== "search"
                                }
                                Row {
                                    spacing: 16
                                    Text {
                                        text: {
                                            if (activeTab === "favorites") return "Liked Songs";
                                            if (activeTab === "search") return "Search Results";
                                            if (activeTab.startsWith("playlist_")) {
                                                var plId = parseInt(activeTab.substring(9));
                                                for (var i = 0; i < playlists.length; i++) {
                                                    if (playlists[i].id === plId) return playlists[i].name;
                                                }
                                                if (mainScreen.activePlaylistDetails && mainScreen.activePlaylistDetails.id === plId) {
                                                    return mainScreen.activePlaylistDetails.name;
                                                }
                                                return "Playlist";
                                            }
                                            return "Library Hub";
                                        }
                                        color: "#FFFFFF"
                                        font.bold: true
                                        font.pixelSize: activeTab === "favorites" ? 48 : 32
                                        font.family: "Outfit"
                                        anchors.verticalCenter: parent.verticalCenter
                                    }
                                }
                                Text {
                                    text: tracks.length + " songs"
                                    color: "#B3B3B3"
                                    font.pixelSize: 13
                                    visible: activeTab !== "home" && activeTab !== "search"
                                }
                            }
                        }
                    }

                    // Matching Playlists Search Results
                    Column {
                        width: parent.width
                        spacing: 12
                        visible: activeTab === "search" && mainScreen.searchedPlaylists && mainScreen.searchedPlaylists.length > 0
                        
                        Text {
                            text: "Matching Playlists"
                            color: "#FFFFFF"
                            font.bold: true
                            font.pixelSize: 18
                            font.family: "Outfit"
                        }
                        
                        Flow {
                            width: parent.width
                            spacing: 16
                            
                            Repeater {
                                model: mainScreen.searchedPlaylists
                                delegate: Rectangle {
                                    width: 160
                                    height: 210
                                    color: searchPlaylistMouseArea.containsMouse ? "#282828" : "#181818"
                                    radius: 0
                                    border.color: "#282828"
                                    border.width: 1
                                    
                                    MouseArea {
                                        id: searchPlaylistMouseArea
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                                        onClicked: (mouse) => {
                                            if (mouse.button === Qt.RightButton) {
                                                playlistContextMenu.targetPlaylist = modelData
                                                playlistContextMenu.popup()
                                            } else {
                                                activeTab = "playlist_" + modelData.id
                                                networkManager.fetchPlaylistTracks(modelData.id)
                                            }
                                        }
                                    }
                                    
                                    Column {
                                        anchors.fill: parent
                                        anchors.margins: 12
                                        spacing: 8
                                        
                                        // Playlist Cover
                                        Rectangle {
                                            width: 136
                                            height: 136
                                            radius: 0
                                            color: "#282828"
                                            clip: true
                                            
                                            Image {
                                                id: searchPlCoverImage
                                                anchors.fill: parent
                                                fillMode: Image.PreserveAspectCrop
                                                source: modelData.cover_url ? modelData.cover_url : ""
                                                visible: modelData.cover_url !== null && status === Image.Ready
                                            }
                                            
                                            Image {
                                                source: "qrc:/Tortu/icons/library.svg"
                                                width: 56; height: 56
                                                anchors.centerIn: parent
                                                visible: !modelData.cover_url || searchPlCoverImage.status !== Image.Ready
                                            }
                                        }
                                        
                                        Text {
                                            text: modelData.name
                                            color: "#FFFFFF"
                                            font.bold: true
                                            font.pixelSize: 13
                                            elide: Text.ElideRight
                                            width: parent.width
                                        }
                                        
                                        Text {
                                            text: modelData.creator ? "By " + modelData.creator : "Playlist"
                                            color: "#B3B3B3"
                                            font.pixelSize: 11
                                            elide: Text.ElideRight
                                            width: parent.width
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // Tracks list header table
                    Item {
                        width: parent.width
                        height: 36
                        visible: tracks.length > 0 && !isMobile && activeTab !== "playlists"

                        Row {
                            id: headerRow
                            anchors.fill: parent
                            anchors.leftMargin: 16
                            anchors.rightMargin: 16
                            spacing: 16

                            Text { id: hIdx; text: "#"; color: "#B3B3B3"; width: 24; font.bold: true; font.pixelSize: 11 }
                            Item { id: hCvr; width: 40 } // Spacer for cover column
                            Text { id: hTitle; text: "Title"; color: "#B3B3B3"; width: parent.width * 0.4; font.bold: true; font.pixelSize: 11 }
                            Text { id: hAlb; text: "Album"; color: "#B3B3B3"; width: parent.width * 0.25; font.bold: true; font.pixelSize: 11 }
                            Item {
                                width: Math.max(1, parent.width - (hIdx.width + hCvr.width + hTitle.width + hAlb.width + hStatus.width + hTime.width + 6 * parent.spacing))
                                height: 1
                            }
                            Text { id: hStatus; text: "Status"; color: "#B3B3B3"; width: 32; font.bold: true; font.pixelSize: 11; horizontalAlignment: Text.AlignHCenter }
                            Text { id: hTime; text: "Time"; color: "#B3B3B3"; width: 40; font.bold: true; font.pixelSize: 11; horizontalAlignment: Text.AlignRight }
                        }
                    }

                    // ListView of Tracks
                    ListView {
                        id: tracksList
                        width: parent.width
                        height: count * 56
                        interactive: false // Managed by ScrollView
                        model: mainScreen.tracks
                        visible: activeTab !== "playlists"
                        delegate: TrackRow {
                            width: parent.width
                            trackData: modelData
                            isPlayingNow: currentTrack !== null && currentTrack.id === modelData.id && player.playing
                            
                            onPlayClicked: {
                                if (currentTrack && currentTrack.id === modelData.id) {
                                    if (player.playing) {
                                        player.pause()
                                    } else {
                                        player.play()
                                    }
                                } else {
                                    mainScreen.currentTrack = modelData
                                    player.source = modelData.audio_url
                                    player.play()
                                }
                            }

                            onFavoriteClicked: {
                                networkManager.toggleFavorite(modelData.id)
                            }

                            onRightClicked: (mx, my) => {
                                trackContextMenu.targetTrack = modelData
                                trackContextMenu.popup()
                            }
                        }
                    }

                    // Empty state
                    Column {
                        width: parent.width
                        spacing: 12
                        visible: tracks.length === 0 && activeTab !== "playlists"
                        anchors.horizontalCenter: parent.horizontalCenter
                        
                        Text {
                            text: "No songs here yet"
                            color: "#FFFFFF"
                            font.bold: true
                            font.pixelSize: 18
                            horizontalAlignment: Text.AlignHCenter
                            width: parent.width
                        }

                        Text {
                            text: activeTab === "favorites" ? "Songs you like will appear here!" : "Click 'Upload Track' to upload your first song!"
                            color: "#B3B3B3"
                            font.pixelSize: 14
                            horizontalAlignment: Text.AlignHCenter
                            width: parent.width
                        }
                    }

                    // PLAYLISTS VIEW FOR MOBILE
                    Column {
                        width: parent.width
                        spacing: 16
                        visible: activeTab === "playlists"

                        Row {
                            width: parent.width
                            Text {
                                text: "Your Playlists"
                                color: "#FFFFFF"
                                font.bold: true
                                font.pixelSize: 22
                                font.family: "Outfit"
                                width: parent.width - 32
                            }
                            Button {
                                width: 32
                                height: 32
                                anchors.verticalCenter: parent.verticalCenter
                                background: Rectangle { color: "transparent" }
                                contentItem: Text {
                                    text: "+"
                                    color: "#FFFFFF"
                                    font.pixelSize: 24
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                }
                                onClicked: createPlaylistOverlay.visible = true
                            }
                        }

                        Column {
                            width: parent.width
                            spacing: 12

                            Repeater {
                                model: mainScreen.playlists
                                delegate: Rectangle {
                                    width: parent.width
                                    height: 64
                                    color: "#181818"
                                    radius: 8
                                    border.color: "#282828"
                                    border.width: 1

                                    MouseArea {
                                        anchors.fill: parent
                                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                                        onClicked: (mouse) => {
                                            if (mouse.button === Qt.RightButton) {
                                                playlistContextMenu.targetPlaylist = modelData
                                                playlistContextMenu.popup()
                                            } else {
                                                activeTab = "playlist_" + modelData.id
                                                networkManager.fetchPlaylistTracks(modelData.id)
                                            }
                                        }
                                    }

                                    Row {
                                        spacing: 12
                                        anchors.fill: parent
                                        anchors.margins: 8

                                        Rectangle {
                                            width: 48
                                            height: 48
                                            radius: 4
                                            color: "#282828"
                                            clip: true
                                            anchors.verticalCenter: parent.verticalCenter

                                            Image {
                                                id: mobilePlaylistCover
                                                anchors.fill: parent
                                                source: modelData.cover_url ? modelData.cover_url : ""
                                                fillMode: Image.PreserveAspectCrop
                                                visible: modelData.cover_url !== null && status === Image.Ready
                                            }
                                            Image {
                                                source: "qrc:/Tortu/icons/library.svg"
                                                width: 20; height: 20
                                                anchors.centerIn: parent
                                                visible: !modelData.cover_url || mobilePlaylistCover.status !== Image.Ready
                                            }
                                        }

                                        Column {
                                            anchors.verticalCenter: parent.verticalCenter
                                            spacing: 4

                                            Text {
                                                text: modelData.name
                                                color: "#FFFFFF"
                                                font.bold: true
                                                font.pixelSize: 14
                                            }
                                            Text {
                                                text: modelData.creator ? "By " + modelData.creator : "Playlist"
                                                color: "#B3B3B3"
                                                font.pixelSize: 11
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        // 3. LYRICS PANEL (Right)
        Rectangle {
            id: lyricsPanel
            width: showLyrics ? 300 : 0
            height: parent.height
            color: "#181818"
            border.color: "#282828"
            border.width: 1
            visible: showLyrics
            clip: true

            Behavior on width {
                NumberAnimation { duration: 200 }
            }

            Column {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 16

                Row {
                    width: parent.width
                    Text {
                        text: "Lyrics"
                        color: "#FFFFFF"
                        font.bold: true
                        font.pixelSize: 18
                        width: parent.width - 30
                    }
                    Button {
                        width: 30
                        height: 30
                        background: Rectangle { color: "transparent" }
                        contentItem: Image {
                            width: 12
                            height: 12
                            anchors.centerIn: parent
                            source: "qrc:/Tortu/icons/close.svg"
                        }
                        onClicked: showLyrics = false
                    }
                }

                ScrollView {
                    id: lyricsScroll
                    width: parent.width
                    height: parent.height - 80
                    clip: true

                    Text {
                        text: (currentTrack && currentTrack.lyrics) ? currentTrack.lyrics : "No lyrics available for this song."
                        color: (currentTrack && currentTrack.lyrics) ? "#1DB954" : "#B3B3B3"
                        font.bold: true
                        font.pixelSize: 16
                        wrapMode: Text.WordWrap
                        width: lyricsScroll.width - 16
                        lineHeight: 1.4
                    }
                }
            }
        }
    }

    // 4. PLAYER BAR (Bottom)
    Rectangle {
        id: playerBar
        width: parent.width
        height: isMobile ? 64 : 90
        color: "#181818"
        anchors.bottom: isMobile ? bottomNavBar.top : parent.bottom
        border.color: "#282828"
        border.width: 1

        Rectangle {
            width: parent.width
            height: 2
            color: "#282828"
            anchors.top: parent.top
            visible: isMobile

            Rectangle {
                width: (player.duration > 0) ? (player.position / player.duration) * parent.width : 0
                height: parent.height
                color: "#1DB954"
            }
        }

        Row {
            anchors.fill: parent
            anchors.leftMargin: 16
            anchors.rightMargin: 16
            visible: !isMobile

            Rectangle {
                width: parent.width * 0.28
                height: parent.height
                color: "transparent"

                Row {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 12
                    visible: currentTrack !== null

                    Rectangle {
                        id: coverRect
                        width: 56
                        height: 56
                        radius: 0
                        color: "#282828"
                        clip: true

                        Image {
                            id: barCoverImage
                            anchors.fill: parent
                            source: (currentTrack && currentTrack.cover_url) ? currentTrack.cover_url : ""
                            fillMode: Image.PreserveAspectCrop
                            visible: currentTrack && currentTrack.cover_url !== null && barCoverImage.status === Image.Ready
                        }
                        
                        Image {
                            source: "qrc:/Tortu/icons/library.svg"
                            width: 20; height: 20
                            anchors.centerIn: parent
                            visible: !currentTrack || !currentTrack.cover_url || barCoverImage.status !== Image.Ready
                        }
                    }

                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 150
                        spacing: 2

                        Text {
                            text: currentTrack ? currentTrack.title : ""
                            color: "#FFFFFF"
                            font.bold: true
                            font.pixelSize: 14
                            elide: Text.ElideRight
                            width: parent.width
                        }

                        Text {
                            text: currentTrack ? currentTrack.artist : ""
                            color: "#B3B3B3"
                            font.pixelSize: 11
                            elide: Text.ElideRight
                            width: parent.width
                        }
                    }

                    Button {
                        width: 32
                        height: 32
                        anchors.verticalCenter: parent.verticalCenter
                        background: Rectangle { color: "transparent" }
                        contentItem: Image {
                            width: 16
                            height: 16
                            anchors.centerIn: parent
                            source: (currentTrack && currentTrack.is_favorite) ? "qrc:/Tortu/icons/heart-filled.svg" : "qrc:/Tortu/icons/heart.svg"
                        }
                        onClicked: {
                            if (currentTrack) {
                                networkManager.toggleFavorite(currentTrack.id)
                            }
                        }
                    }
                }
            }

            Column {
                width: parent.width * 0.44
                height: parent.height
                anchors.verticalCenter: parent.verticalCenter
                anchors.verticalCenterOffset: 12
                spacing: 8
                
                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 24
                    
                    Button {
                        width: 32
                        height: 32
                        background: Rectangle { color: "transparent" }
                        contentItem: Image {
                            source: "qrc:/Tortu/icons/shuffle.svg"
                            width: 16; height: 16
                            anchors.centerIn: parent
                        }
                    }
                    Button {
                        width: 32
                        height: 32
                        background: Rectangle { color: "transparent" }
                        contentItem: Image {
                            source: "qrc:/Tortu/icons/skip-prev.svg"
                            width: 16; height: 16
                            anchors.centerIn: parent
                        }
                        onClicked: mainScreen.playPrevTrack()
                    }
                    
                    Button {
                        id: playPauseBtn
                        width: 36
                        height: 36
                        background: Rectangle {
                            color: "#FFFFFF"
                            radius: 18
                        }
                        contentItem: Image {
                            source: player.playing ? "qrc:/Tortu/icons/pause-black.svg" : "qrc:/Tortu/icons/play-black.svg"
                            width: 14; height: 14
                            anchors.centerIn: parent
                        }
                        onClicked: {
                            if (player.source !== "") {
                                if (player.playing) {
                                    player.pause()
                                } else {
                                    player.play()
                                }
                            }
                        }
                    }

                    Button {
                        width: 32
                        height: 32
                        background: Rectangle { color: "transparent" }
                        contentItem: Image {
                            source: "qrc:/Tortu/icons/skip-next.svg"
                            width: 16; height: 16
                            anchors.centerIn: parent
                        }
                        onClicked: mainScreen.playNextTrack()
                    }
                    Button {
                        width: 32
                        height: 32
                        background: Rectangle { color: "transparent" }
                        contentItem: Image {
                            source: "qrc:/Tortu/icons/repeat.svg"
                            width: 16; height: 16
                            anchors.centerIn: parent
                        }
                    }
                }

                Row {
                    width: parent.width
                    spacing: 8

                    function formatMs(ms) {
                        if (isNaN(ms) || ms < 0) return "0:00";
                        var t = Math.floor(ms / 1000);
                        var s = t % 60;
                        var m = Math.floor(t / 60);
                        return m + ":" + (s < 10 ? "0" + s : s);
                    }

                    Text {
                        text: parent.formatMs(player.position)
                        color: "#B3B3B3"
                        font.pixelSize: 11
                        anchors.verticalCenter: parent.verticalCenter
                        width: 32
                    }

                    Slider {
                        id: seekSlider
                        width: parent.width - 80
                        height: 16
                        anchors.verticalCenter: parent.verticalCenter
                        from: 0
                        to: player.duration > 0 ? player.duration : 100
                        value: player.position
                        
                        background: Rectangle {
                            x: seekSlider.leftPadding
                            y: seekSlider.topPadding + seekSlider.availableHeight / 2 - 2
                            width: seekSlider.availableWidth
                            height: 4
                            radius: 2
                            color: "#535353"

                            Rectangle {
                                width: seekSlider.visualPosition * parent.width
                                height: parent.height
                                color: seekSlider.hovered ? "#1DB954" : "#FFFFFF"
                                radius: 2
                            }
                        }

                        handle: Rectangle {
                            x: seekSlider.leftPadding + seekSlider.visualPosition * (seekSlider.availableWidth - width)
                            y: seekSlider.topPadding + seekSlider.availableHeight / 2 - height / 2
                            width: seekSlider.hovered ? 12 : 0
                            height: width
                            radius: width / 2
                            color: "#FFFFFF"
                        }

                        onMoved: {
                            player.position = value
                        }
                    }

                    Text {
                        text: parent.formatMs(player.duration)
                        color: "#B3B3B3"
                        font.pixelSize: 11
                        anchors.verticalCenter: parent.verticalCenter
                        width: 32
                        horizontalAlignment: Text.AlignRight
                    }
                }
            }

            Rectangle {
                width: parent.width * 0.28
                height: parent.height
                color: "transparent"

                Row {
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.right: parent.right
                    spacing: 12

                    Button {
                        id: lyricsBtn
                        width: 32
                        height: 32
                        background: Rectangle { color: "transparent" }
                        contentItem: Image {
                            source: "qrc:/Tortu/icons/lyrics.svg"
                            width: 16; height: 16
                            anchors.centerIn: parent
                        }
                        onClicked: showLyrics = !showLyrics
                    }

                    Image {
                        source: player.volume > 0 ? (player.volume > 0.5 ? "qrc:/Tortu/icons/volume-high.svg" : "qrc:/Tortu/icons/volume-medium.svg") : "qrc:/Tortu/icons/volume-mute.svg"
                        width: 16; height: 16
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Slider {
                        id: volumeSlider
                        width: 80
                        height: 16
                        anchors.verticalCenter: parent.verticalCenter
                        from: 0.0
                        to: 1.0
                        value: player.volume

                        background: Rectangle {
                            x: volumeSlider.leftPadding
                            y: volumeSlider.topPadding + volumeSlider.availableHeight / 2 - 2
                            width: volumeSlider.availableWidth
                            height: 4
                            radius: 2
                            color: "#535353"

                            Rectangle {
                                width: volumeSlider.visualPosition * parent.width
                                height: parent.height
                                color: volumeSlider.hovered ? "#1DB954" : "#FFFFFF"
                                radius: 2
                            }
                        }

                        handle: Rectangle {
                            x: volumeSlider.leftPadding + volumeSlider.visualPosition * (volumeSlider.availableWidth - width)
                            y: volumeSlider.topPadding + volumeSlider.availableHeight / 2 - height / 2
                            width: volumeSlider.hovered ? 10 : 0
                            height: width
                            radius: width / 2
                            color: "#FFFFFF"
                        }

                        onMoved: {
                            player.volume = value
                        }
                    }
                }
            }
        }

        Row {
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 12
            spacing: 12
            visible: isMobile
            
            Rectangle {
                width: 44
                height: 44
                radius: 4
                color: "#282828"
                clip: true
                anchors.verticalCenter: parent.verticalCenter
                
                Image {
                    id: mobileBarCover
                    anchors.fill: parent
                    source: (currentTrack && currentTrack.cover_url) ? currentTrack.cover_url : ""
                    fillMode: Image.PreserveAspectCrop
                    visible: currentTrack && currentTrack.cover_url !== null && mobileBarCover.status === Image.Ready
                }
                Image {
                    source: "qrc:/Tortu/icons/library.svg"
                    width: 16; height: 16
                    anchors.centerIn: parent
                    visible: !currentTrack || !currentTrack.cover_url || mobileBarCover.status !== Image.Ready
                }
            }
            
            Column {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - 200
                spacing: 2
                visible: currentTrack !== null
                
                Text {
                    text: currentTrack ? currentTrack.title : ""
                    color: "#FFFFFF"
                    font.bold: true
                    font.pixelSize: 13
                    elide: Text.ElideRight
                    width: parent.width
                }
                Text {
                    text: currentTrack ? currentTrack.artist : ""
                    color: "#B3B3B3"
                    font.pixelSize: 11
                    elide: Text.ElideRight
                    width: parent.width
                }
            }
            
            Item {
                width: parent.width - 200
                height: 1
                visible: currentTrack === null
            }
            
            Row {
                anchors.verticalCenter: parent.verticalCenter
                spacing: 4
                
                Button {
                    width: 36
                    height: 36
                    background: Rectangle { color: "transparent" }
                    contentItem: Image {
                        source: (currentTrack && currentTrack.is_favorite) ? "qrc:/Tortu/icons/heart-filled.svg" : "qrc:/Tortu/icons/heart.svg"
                        width: 18; height: 18
                        anchors.centerIn: parent
                    }
                    onClicked: {
                        if (currentTrack) {
                            networkManager.toggleFavorite(currentTrack.id)
                        }
                    }
                }
                
                Button {
                    width: 36
                    height: 36
                    background: Rectangle { color: "transparent" }
                    contentItem: Image {
                        source: player.playing ? "qrc:/Tortu/icons/pause.svg" : "qrc:/Tortu/icons/play.svg"
                        width: 20; height: 20
                        anchors.centerIn: parent
                    }
                    onClicked: {
                        if (player.source !== "") {
                            if (player.playing) {
                                player.pause()
                            } else {
                                player.play()
                            }
                        }
                    }
                }
                
                Button {
                    width: 36
                    height: 36
                    background: Rectangle { color: "transparent" }
                    contentItem: Image {
                        source: "qrc:/Tortu/icons/skip-next.svg"
                        width: 18; height: 18
                        anchors.centerIn: parent
                    }
                    onClicked: mainScreen.playNextTrack()
                }
            }
        }
    }

    // Dialog for Uploading tracks
    Rectangle {
        id: uploadOverlay
        anchors.fill: parent
        color: "#AA000000"
        visible: false
        z: 10

        MouseArea {
            anchors.fill: parent
        }

        UploadDialog {
            anchors.centerIn: parent
            networkManager: mainScreen.networkManager
            onClosed: {
                uploadOverlay.visible = false
                mainScreen.refreshTracks()
            }
        }
    }

    // Create Playlist Popup
    Rectangle {
        id: createPlaylistOverlay
        anchors.fill: parent
        color: "#AA000000"
        visible: false
        z: 11

        MouseArea { anchors.fill: parent }

        FileDialog {
            id: playlistCoverDialog
            title: "Select Playlist Cover Image"
            nameFilters: ["Image files (*.png *.jpg *.jpeg *.webp)"]
            onAccepted: {
                mainScreen.playlistCoverPath = selectedFile.toString()
            }
        }

        Rectangle {
            width: 400
            height: 270
            color: "#181818"
            radius: 12
            border.color: "#282828"
            border.width: 1
            anchors.centerIn: parent

            Column {
                anchors.fill: parent
                anchors.margins: 24
                spacing: 16

                Text {
                    text: "Create Playlist"
                    color: "#FFFFFF"
                    font.bold: true
                    font.pixelSize: 18
                }

                TextField {
                    id: playlistNameInput
                    width: parent.width
                    placeholderText: "Playlist name"
                    color: "#FFFFFF"
                    placeholderTextColor: "#727272"
                    background: Rectangle { color: "#242424"; radius: 4 }
                }

                Row {
                    width: parent.width
                    spacing: 12

                    Button {
                        text: "Choose Cover"
                        onClicked: playlistCoverDialog.open()
                    }

                    Text {
                        text: mainScreen.playlistCoverPath ? "Selected: " + mainScreen.playlistCoverPath.substring(mainScreen.playlistCoverPath.lastIndexOf('/') + 1) : "No cover selected"
                        color: "#B3B3B3"
                        font.pixelSize: 12
                        elide: Text.ElideRight
                        width: parent.width - 120
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 16

                    Button {
                        text: "Cancel"
                        onClicked: {
                            createPlaylistOverlay.visible = false
                            playlistNameInput.text = ""
                            mainScreen.playlistCoverPath = ""
                        }
                    }

                    Button {
                        id: playlistSubmitBtn
                        width: 100
                        height: 36
                        enabled: playlistNameInput.text !== ""
                        background: Rectangle {
                            color: playlistSubmitBtn.enabled ? "#1DB954" : "#535353"
                            radius: 18
                        }
                        contentItem: Text {
                            text: "Create"
                            color: playlistSubmitBtn.enabled ? "#000000" : "#B3B3B3"
                            font.bold: true
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                        onClicked: {
                            if (playlistNameInput.text !== "") {
                                networkManager.createPlaylist(playlistNameInput.text, mainScreen.playlistCoverPath)
                                createPlaylistOverlay.visible = false
                                playlistNameInput.text = ""
                                mainScreen.playlistCoverPath = ""
                            }
                        }
                    }
                }
            }
        }
    }

    // Share Notification Toast
    Rectangle {
        id: shareNotification
        width: 320
        height: 48
        color: "#1DB954"
        radius: 24
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: playerBar.height + (isMobile ? bottomNavBar.height : 0) + 20
        z: 100
        visible: false
        
        Text {
            id: shareNotificationText
            text: "Link copied to clipboard!"
            color: "#FFFFFF"
            font.bold: true
            font.pixelSize: 14
            anchors.centerIn: parent
        }
        
        Timer {
            id: shareNotificationTimer
            interval: 2000
            onTriggered: shareNotification.visible = false
        }
    }

    Rectangle {
        id: bottomNavBar
        width: parent.width
        height: 60
        color: "#181818"
        anchors.bottom: parent.bottom
        visible: isMobile
        border.color: "#282828"
        border.width: 1
        z: 10
        
        Row {
            anchors.fill: parent
            
            Button {
                width: parent.width / 4
                height: parent.height
                background: Rectangle { color: "transparent" }
                contentItem: Column {
                    spacing: 4
                    anchors.centerIn: parent
                    Image {
                        source: "qrc:/Tortu/icons/home.svg"
                        width: 20; height: 20
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                    Text {
                        text: "Home"
                        color: activeTab === "home" ? "#FFFFFF" : "#B3B3B3"
                        font.pixelSize: 10
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                }
                onClicked: {
                    activeTab = "home"
                    networkManager.fetchTracks()
                }
            }
            
            Button {
                width: parent.width / 4
                height: parent.height
                background: Rectangle { color: "transparent" }
                contentItem: Column {
                    spacing: 4
                    anchors.centerIn: parent
                    Image {
                        source: "qrc:/Tortu/icons/search.svg"
                        width: 20; height: 20
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                    Text {
                        text: "Search"
                        color: activeTab === "search" ? "#FFFFFF" : "#B3B3B3"
                        font.pixelSize: 10
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                }
                onClicked: {
                    activeTab = "search"
                    networkManager.fetchTracks(searchField.text)
                }
            }
            
            Button {
                width: parent.width / 4
                height: parent.height
                background: Rectangle { color: "transparent" }
                contentItem: Column {
                    spacing: 4
                    anchors.centerIn: parent
                    Image {
                        source: "qrc:/Tortu/icons/heart-filled.svg"
                        width: 20; height: 20
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                    Text {
                        text: "Favorites"
                        color: activeTab === "favorites" ? "#FFFFFF" : "#B3B3B3"
                        font.pixelSize: 10
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                }
                onClicked: {
                    activeTab = "favorites"
                    networkManager.fetchFavorites()
                }
            }
            
            Button {
                width: parent.width / 4
                height: parent.height
                background: Rectangle { color: "transparent" }
                contentItem: Column {
                    spacing: 4
                    anchors.centerIn: parent
                    Image {
                        source: "qrc:/Tortu/icons/library.svg"
                        width: 20; height: 20
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                    Text {
                        text: "Playlists"
                        color: (activeTab === "playlists" || activeTab.startsWith("playlist_")) ? "#FFFFFF" : "#B3B3B3"
                        font.pixelSize: 10
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                }
                onClicked: {
                    activeTab = "playlists"
                    networkManager.fetchPlaylists()
                }
            }
        }
    }
}
