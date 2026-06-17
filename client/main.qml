import QtQuick
import QtQuick.Controls
import Tortu 1.0

ApplicationWindow {
    id: window
    width: 1200
    height: 800
    visible: true
    title: "Tortu"
    color: "#121212"

    NetworkManager {
        id: netManager

        onLoginSuccess: {
            console.log("Login success! Username: " + username)
            stackView.replace(mainScreenComponent)
        }

        onLoginFailed: (error) => {
            console.log("Login failed: " + error)
        }

        onIsLoggedInChanged: {
            if (!isLoggedIn) {
                stackView.replace(loginScreenComponent)
            }
        }
    }

    AudioPlayer {
        id: audioPlayer
    }

    StackView {
        id: stackView
        anchors.fill: parent
        initialItem: loginScreenComponent
    }

    Component {
        id: loginScreenComponent
        LoginScreen {
            networkManager: netManager
        }
    }

    Component {
        id: mainScreenComponent
        MainScreen {
            networkManager: netManager
            player: audioPlayer
        }
    }
}
