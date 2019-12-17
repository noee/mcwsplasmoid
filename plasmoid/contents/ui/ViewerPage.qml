import QtQuick 2.9
import QtQuick.Controls 2.4

Page {

    property alias viewer: viewer

    signal viewEntered()

    Viewer {
        anchors.fill: parent
        id: viewer
        spacing: 1
    }
}
