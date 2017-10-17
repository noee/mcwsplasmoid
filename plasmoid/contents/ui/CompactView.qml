import QtQuick 2.8
import QtQuick.Layouts 1.3
import QtQuick.Controls 2.2 as QtControls

import org.kde.plasma.core 2.1 as PlasmaCore
import org.kde.plasma.components 2.0 as PlasmaComponents
import org.kde.plasma.extras 2.0 as PlasmaExtras
import org.kde.plasma.plasmoid 2.0

RowLayout {
        anchors.fill: parent
        spacing: 1
        PlasmaComponents.ToolButton {
            iconSource: "media-skip-backward"
            flat: false
            visible: mcws.isConnected
            enabled: mcws.model.get(currentZone).playingnowposition !== "0"
            onClicked: mcws.previous(currentZone)
        }
        PlasmaComponents.ToolButton {
            iconSource: {
                if (mcws.isConnected)
                    mcws.model.get(currentZone).state === mcws.statePlaying ? "media-playback-pause" : "media-playback-start"
                else
                    "media-playback-start"
            }
            flat: false
            visible: mcws.isConnected
            onClicked: mcws.play(currentZone)
        }
        PlasmaComponents.ToolButton {
            iconSource: "media-skip-forward"
            flat: false
            visible: mcws.isConnected
            enabled: mcws.model.get(currentZone).nextfilekey !== "-1"
            onClicked: mcws.next(currentZone)
        }
        PlasmaComponents.Label {
            Layout.fillWidth: true
            text: trayText
            font.pointSize: theme.defaultFont.pointSize-1.5
            MouseArea {
                anchors.fill: parent
                onClicked: plasmoid.expanded = !plasmoid.expanded
            }
        }
    }
