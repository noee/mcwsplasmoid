import QtQuick 2.8
import QtQuick.Controls 2.2
import org.kde.plasma.plasmoid 2.0
import org.kde.plasma.core 2.0 as PlasmaCore

ListView {

    function getObj() {
        return model ? model.get(currentIndex) : null
    }

    add: Transition {
             NumberAnimation { properties: "x,y"; from: 100; duration: 800 }
         }
    populate: Transition {
              NumberAnimation { properties: "x,y"; duration: 800 }
          }
    anchors.fill: parent
    spacing: 6
    clip: true
    highlightMoveDuration: 1
    highlight: hlDel
    Component {
        id: hlDel
        Rectangle {
                id: hl
                width: parent.width
                color: PlasmaCore.ColorScope.highlightColor
                radius: 5
                y: hl.ListView.view.currentItem.y
                Behavior on y {
                    SpringAnimation {
                        spring: 3
                        damping: 0.2
                    }
                }
            }
    }
}
