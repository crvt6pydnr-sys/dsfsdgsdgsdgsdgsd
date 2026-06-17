import QtQuick
import QtQuick.Controls

Rectangle {
    id: root
    width: parent.width
    height: 56
    color: hovered ? "#2A2A2A" : "transparent"
    radius: 0

    property bool hovered: false
    property var trackData
    property bool isPlayingNow: false

    signal playClicked()
    signal favoriteClicked()
    signal rightClicked(real mouseX, real mouseY)

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onEntered: root.hovered = true
        onExited: root.hovered = false
        onClicked: (mouse) => {
            if (mouse.button === Qt.RightButton) {
                root.rightClicked(mouse.x, mouse.y)
            } else {
                root.playClicked()
            }
        }
    }

    Row {
        anchors.fill: parent
        anchors.leftMargin: 16
        anchors.rightMargin: 16
        spacing: 16

        // 1. Play Index / Play Icon
        Rectangle {
            id: idxItem
            width: 24
            height: 24
            color: "transparent"
            anchors.verticalCenter: parent.verticalCenter

            Image {
                width: 12
                height: 12
                anchors.centerIn: parent
                source: root.isPlayingNow ? "qrc:/Tortu/icons/pause.svg" : "qrc:/Tortu/icons/play.svg"
                visible: root.hovered
            }

            Text {
                text: (index + 1)
                color: root.isPlayingNow ? "#1DB954" : "#B3B3B3"
                font.bold: true
                font.pixelSize: 13
                anchors.centerIn: parent
                visible: !root.hovered
            }
        }

        // 2. Track Cover Image
        Rectangle {
            id: cvrItem
            width: 40
            height: 40
            radius: 0
            color: "#282828"
            anchors.verticalCenter: parent.verticalCenter
            clip: true

            Image {
                id: trackImage
                anchors.fill: parent
                source: trackData.cover_url ? trackData.cover_url : ""
                fillMode: Image.PreserveAspectCrop
                visible: trackData.cover_url !== null && trackImage.status === Image.Ready
            }

            // Fallback icon (SVG library icon)
            Image {
                width: 18
                height: 18
                anchors.centerIn: parent
                source: "qrc:/Tortu/icons/library.svg"
                visible: !trackData.cover_url || trackImage.status !== Image.Ready
            }
        }

        // 3. Track Info (Title & Artist)
        Column {
            id: titleCol
            width: parent.width * 0.4
            anchors.verticalCenter: parent.verticalCenter
            spacing: 4

            Text {
                text: trackData.title
                color: root.isPlayingNow ? "#1DB954" : "#FFFFFF"
                font.bold: true
                font.pixelSize: 14
                elide: Text.ElideRight
            }

            Text {
                text: trackData.artist
                color: "#B3B3B3"
                font.pixelSize: 12
                elide: Text.ElideRight
            }
        }

        // 4. Album name
        Text {
            id: albText
            text: trackData.album ? trackData.album : "-"
            color: "#B3B3B3"
            font.pixelSize: 13
            anchors.verticalCenter: parent.verticalCenter
            elide: Text.ElideRight
            width: parent.width * 0.25
        }

        // Spacer to push items to the right
        Item {
            width: Math.max(1, parent.width - (idxItem.width + cvrItem.width + titleCol.width + albText.width + favBtn.width + timeText.width + 6 * parent.spacing))
            height: 1
        }

        // 5. Favorite Heart Button
        Button {
            id: favBtn
            width: 32
            height: 32
            anchors.verticalCenter: parent.verticalCenter
            background: Rectangle { color: "transparent" }
            contentItem: Image {
                width: 16
                height: 16
                anchors.centerIn: parent
                source: trackData.is_favorite ? "qrc:/Tortu/icons/heart-filled.svg" : "qrc:/Tortu/icons/heart.svg"
            }
            onClicked: root.favoriteClicked()
        }

        // 6. Track Duration
        Text {
            id: timeText
            text: {
                var sec = trackData.duration % 60;
                var min = Math.floor(trackData.duration / 60);
                return min + ":" + (sec < 10 ? "0" + sec : sec);
            }
            color: "#B3B3B3"
            font.pixelSize: 13
            anchors.verticalCenter: parent.verticalCenter
            width: 40
            horizontalAlignment: Text.AlignRight
        }
    }
}
