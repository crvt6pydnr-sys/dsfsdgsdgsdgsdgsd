import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs

Rectangle {
    id: root
    width: 500
    height: 600
    color: "#181818"
    radius: 12
    border.color: "#282828"
    border.width: 1

    required property var networkManager
    signal closed()

    property string audioPath: ""
    property string coverPath: ""
    property real uploadPct: 0.0
    property bool isUploading: false
    property string statusText: ""

    Connections {
        target: networkManager

        function onUploadProgress(bytesSent, bytesTotal) {
            if (bytesTotal > 0) {
                uploadPct = bytesSent / bytesTotal
            }
        }

        function onUploadSuccess() {
            isUploading = false
            statusText = "Upload complete!"
            // Clear inputs
            titleInput.text = ""
            artistInput.text = ""
            albumInput.text = ""
            lyricsInput.text = ""
            audioPath = ""
            coverPath = ""
            timerClose.start()
        }

        function onUploadFailed(error) {
            isUploading = false
            statusText = "Upload failed: " + error
        }
    }

    Timer {
        id: timerClose
        interval: 1500
        onTriggered: {
            root.closed()
            statusText = ""
        }
    }

    // File Dialogs
    FileDialog {
        id: audioDialog
        title: "Select Audio File"
        nameFilters: ["Audio files (*.mp3 *.wav *.flac *.ogg *.opus *.m4a)"]
        onAccepted: {
            root.audioPath = selectedFile.toString()
            statusText = ""
        }
    }

    FileDialog {
        id: coverDialog
        title: "Select Cover Image"
        nameFilters: ["Image files (*.png *.jpg *.jpeg *.webp)"]
        onAccepted: {
            root.coverPath = selectedFile.toString()
        }
    }

    Column {
        anchors.fill: parent
        anchors.margins: 24
        spacing: 16

        // Header
        Row {
            width: parent.width
            Text {
                text: "Upload your track"
                color: "#FFFFFF"
                font.bold: true
                font.pixelSize: 20
                width: parent.width - 30
            }
            Button {
                width: 30
                height: 30
                background: Rectangle { color: "transparent" }
                contentItem: Image {
                    width: 14
                    height: 14
                    anchors.centerIn: parent
                    source: "qrc:/Tortu/icons/close.svg"
                }
                onClicked: root.closed()
            }
        }

        // Status
        Text {
            text: statusText
            color: statusText.startsWith("Upload complete") ? "#1DB954" : "#FF3B30"
            font.pixelSize: 13
            wrapMode: Text.WordWrap
            width: parent.width
            visible: text !== ""
        }

        // Form
        ScrollView {
            id: formScrollView
            width: parent.width
            height: 400
            clip: true
            ScrollBar.vertical.policy: ScrollBar.AsNeeded

            Column {
                width: formScrollView.width - 16
                spacing: 12

                // Title
                Column {
                    width: parent.width
                    spacing: 4
                    Text { text: "Title *"; color: "#B3B3B3"; font.bold: true; font.pixelSize: 11 }
                    TextField {
                        id: titleInput
                        width: parent.width
                        color: "#FFFFFF"
                        background: Rectangle { color: "#242424"; radius: 4 }
                    }
                }

                // Artist
                Column {
                    width: parent.width
                    spacing: 4
                    Text { text: "Artist *"; color: "#B3B3B3"; font.bold: true; font.pixelSize: 11 }
                    TextField {
                        id: artistInput
                        width: parent.width
                        color: "#FFFFFF"
                        background: Rectangle { color: "#242424"; radius: 4 }
                    }
                }

                // Album
                Column {
                    width: parent.width
                    spacing: 4
                    Text { text: "Album"; color: "#B3B3B3"; font.bold: true; font.pixelSize: 11 }
                    TextField {
                        id: albumInput
                        width: parent.width
                        color: "#FFFFFF"
                        background: Rectangle { color: "#242424"; radius: 4 }
                    }
                }

                // Audio Select
                Column {
                    width: parent.width
                    spacing: 4
                    Text { text: "Audio File *"; color: "#B3B3B3"; font.bold: true; font.pixelSize: 11 }
                    Row {
                        width: parent.width
                        spacing: 8
                        TextField {
                            text: root.audioPath.substring(root.audioPath.lastIndexOf('/') + 1)
                            readOnly: true
                            color: "#FFFFFF"
                            width: parent.width - 100
                            background: Rectangle { color: "#242424"; radius: 4 }
                            placeholderText: "No file selected"
                        }
                        Button {
                            text: "Browse..."
                            width: 92
                            onClicked: audioDialog.open()
                        }
                    }
                }

                // Cover Select
                Column {
                    width: parent.width
                    spacing: 4
                    Text { text: "Cover Image"; color: "#B3B3B3"; font.bold: true; font.pixelSize: 11 }
                    Row {
                        width: parent.width
                        spacing: 8
                        TextField {
                            text: root.coverPath.substring(root.coverPath.lastIndexOf('/') + 1)
                            readOnly: true
                            color: "#FFFFFF"
                            width: parent.width - 100
                            background: Rectangle { color: "#242424"; radius: 4 }
                            placeholderText: "No file selected"
                        }
                        Button {
                            text: "Browse..."
                            width: 92
                            onClicked: coverDialog.open()
                        }
                    }
                }

                // Lyrics
                Column {
                    width: parent.width
                    spacing: 4
                    Text { text: "Lyrics / Text"; color: "#B3B3B3"; font.bold: true; font.pixelSize: 11 }
                    TextArea {
                        id: lyricsInput
                        width: parent.width
                        height: 100
                        color: "#FFFFFF"
                        wrapMode: TextEdit.Wrap
                        background: Rectangle { color: "#242424"; radius: 4 }
                    }
                }
            }
        }

        // Upload Progress bar
        Rectangle {
            width: parent.width
            height: 6
            color: "#242424"
            radius: 3
            visible: isUploading

            Rectangle {
                width: parent.width * root.uploadPct
                height: parent.height
                color: "#1DB954"
                radius: 3
            }
        }

        // Footer Actions
        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 16
            
            Button {
                text: "Cancel"
                width: 100
                height: 36
                enabled: !isUploading
                onClicked: root.closed()
            }

            Button {
                id: uploadSubmitBtn
                width: 120
                height: 36
                enabled: !isUploading && titleInput.text !== "" && artistInput.text !== "" && root.audioPath !== ""
                background: Rectangle {
                    color: parent.enabled ? (parent.hovered ? "#1ed760" : "#1DB954") : "#535353"
                    radius: 18
                }
                contentItem: Text {
                    text: isUploading ? "Uploading..." : "Upload"
                    color: uploadSubmitBtn.enabled ? "#000000" : "#B3B3B3"
                    font.bold: true
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                onClicked: {
                    isUploading = true
                    statusText = "Uploading and compressing song on server..."
                    networkManager.uploadTrack(
                        titleInput.text,
                        artistInput.text,
                        albumInput.text,
                        lyricsInput.text,
                        root.audioPath,
                        root.coverPath
                    )
                }
            }
        }
    }
}
