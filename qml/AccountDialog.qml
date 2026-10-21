import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Kos.Ui
LiquidDialog {
    id: dialog
    required property var account
    anchors.centerIn: parent
    width: 370; modal: true; title: qsTr("NetEase account")
    standardButtons: Dialog.Close
    onClosed: if (!account.authenticated) account.cancelLogin()
    contentItem: ColumnLayout {
        spacing: 14
        Label {
            Layout.fillWidth: true; wrapMode: Text.WordWrap; color: AppTheme.text
            text: dialog.account.authenticated ? qsTr("Signed in as %1").arg(dialog.account.nickname)
                : dialog.account.message || qsTr("Sign in with the NetEase Cloud Music mobile app. No password is shared with KMusic.")
        }
        Image {
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: 216; Layout.preferredHeight: 216
            visible: dialog.account.qrImage.length > 0
            source: dialog.account.qrImage; cache: false; smooth: false
        }
        BusyIndicator { Layout.alignment: Qt.AlignHCenter; visible: running; running: ["generating", "checking", "restoring"].indexOf(dialog.account.state) >= 0 }
        Label {
            Layout.fillWidth: true; wrapMode: Text.WordWrap; font.pixelSize: 11; color: AppTheme.mutedText
            text: dialog.account.storageMessage
            visible: text.length > 0
        }
        MusicActionButton {
            Layout.fillWidth: true
            visible: !dialog.account.authenticated && ["waiting", "scanned", "generating", "checking", "restoring"].indexOf(dialog.account.state) < 0
            objectName: "reviewAccountGenerate"
            text: qsTr("Generate sign-in code")
            onClicked: dialog.account.beginLogin()
        }
        MusicActionButton {
            objectName: "reviewAccountCancel"
            Layout.fillWidth: true; visible: ["waiting", "scanned", "generating", "checking"].indexOf(dialog.account.state) >= 0
            text: qsTr("Cancel sign-in")
            onClicked: { dialog.account.cancelLogin(); dialog.close() }
        }
        MusicActionButton {
            Layout.fillWidth: true; visible: dialog.account.state === "error"
            text: qsTr("Retry saved session"); onClicked: dialog.account.retrySession()
        }
        MusicActionButton {
            Layout.fillWidth: true; visible: dialog.account.authenticated || dialog.account.cleanupRequired; text: dialog.account.authenticated ? qsTr("Sign out on this device") : qsTr("Retry removing saved session")
            onClicked: dialog.account.logout()
        }
        Label {
            Layout.fillWidth: true; wrapMode: Text.WordWrap; font.pixelSize: 11; color: AppTheme.mutedText
            text: qsTr("Playback availability still depends on your subscription and each track’s rights. A successful sign-in does not unlock unavailable music.")
        }
    }
}
