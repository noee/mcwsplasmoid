import QtQuick 2.9
import QtQuick.Controls 2.4

Page {

    property alias viewer: viewer

    signal viewEntered()

    Viewer {
        id: viewer
        anchors.fill: parent
    }
}
