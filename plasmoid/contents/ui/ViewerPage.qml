import QtQuick 2.12
import org.kde.plasma.components 3.0 as PComp

PComp.Page {

    property alias viewer: viewer

    signal viewEntered()

    Viewer {
        id: viewer
        anchors.fill: parent
    }
}
