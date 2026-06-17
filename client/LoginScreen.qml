import QtQuick
import QtQuick.Controls

Rectangle {
    id: loginScreen
    color: "#000000"
    anchors.fill: parent

    required property var networkManager

    property bool isRegisterMode: false
    property string statusMessage: ""
    property bool isErrorStatus: false

    Connections {
        target: networkManager
        
        function onLoginFailed(error) {
            statusMessage = error
            isErrorStatus = true
        }
        
        function onRegisterSuccess() {
            statusMessage = "Registration successful! You can now log in."
            isErrorStatus = false
            isRegisterMode = false
            usernameInput.text = ""
            passwordInput.text = ""
        }
        
        function onRegisterFailed(error) {
            statusMessage = error
            isErrorStatus = true
        }
    }

    Column {
        anchors.centerIn: parent
        width: 320
        spacing: 20

        // Tortu Logo / Title
        Image {
            source: "qrc:/Tortu/icons/logo.svg"
            width: 150
            height: 50
            fillMode: Image.PreserveAspectFit
            anchors.horizontalCenter: parent.horizontalCenter
        }

        Text {
            text: isRegisterMode ? "Sign up to start listening" : "Log in to Tortu"
            color: "#FFFFFF"
            font.bold: true
            font.pixelSize: 20
            font.family: "Outfit"
            anchors.horizontalCenter: parent.horizontalCenter
        }

        // Error/Status message
        Text {
            text: statusMessage
            color: isErrorStatus ? "#FF3B30" : "#1DB954"
            font.pixelSize: 13
            font.family: "Outfit"
            wrapMode: Text.WordWrap
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            visible: text !== ""
        }

        // Inputs Container
        Column {
            width: parent.width
            spacing: 12

            Column {
                width: parent.width
                spacing: 6
                Text {
                    text: "Username"
                    color: "#FFFFFF"
                    font.bold: true
                    font.pixelSize: 12
                }
                TextField {
                    id: usernameInput
                    width: parent.width
                    placeholderText: "Enter username"
                    color: "#FFFFFF"
                    font.pixelSize: 14
                    padding: 12
                    placeholderTextColor: "#727272"
                    background: Rectangle {
                        color: "#121212"
                        border.color: parent.activeFocus ? "#FFFFFF" : "#727272"
                        border.width: 1
                        radius: 4
                    }
                }
            }

            Column {
                width: parent.width
                spacing: 6
                Text {
                    text: "Password"
                    color: "#FFFFFF"
                    font.bold: true
                    font.pixelSize: 12
                }
                TextField {
                    id: passwordInput
                    width: parent.width
                    placeholderText: "Enter password"
                    echoMode: TextInput.Password
                    color: "#FFFFFF"
                    font.pixelSize: 14
                    padding: 12
                    placeholderTextColor: "#727272"
                    background: Rectangle {
                        color: "#121212"
                        border.color: parent.activeFocus ? "#FFFFFF" : "#727272"
                        border.width: 1
                        radius: 4
                    }
                }
            }
        }

        // Submit Button
        Button {
            width: parent.width
            height: 48
            background: Rectangle {
                color: parent.hovered ? "#1ed760" : "#1DB954"
                radius: 24
            }
            contentItem: Text {
                text: isRegisterMode ? "Sign Up" : "Log In"
                color: "#000000"
                font.bold: true
                font.pixelSize: 15
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }
            onClicked: {
                statusMessage = ""
                if (isRegisterMode) {
                    networkManager.registerUser(usernameInput.text, passwordInput.text)
                } else {
                    networkManager.login(usernameInput.text, passwordInput.text)
                }
            }
        }

        // Toggle Mode Button
        Button {
            width: parent.width
            height: 48
            background: Rectangle {
                color: "transparent"
                border.color: parent.hovered ? "#FFFFFF" : "#727272"
                border.width: 1
                radius: 24
            }
            contentItem: Text {
                text: isRegisterMode ? "Already have an account? Log In" : "Don't have an account? Sign Up"
                color: "#FFFFFF"
                font.bold: true
                font.pixelSize: 13
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }
            onClicked: {
                isRegisterMode = !isRegisterMode
                statusMessage = ""
            }
        }
    }
}
