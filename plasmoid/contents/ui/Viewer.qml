import QtQuick 2.8
import QtQuick.Controls 2.2

ListView {
    id: list

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
    highlight: Rectangle {
        width: list.width
        color: theme.highlightColor
        radius: 5
        y: list.currentItem !== null ? list.currentItem.y : -1
        Behavior on y {
            SpringAnimation {
                spring: 3
                damping: 0.25
            }
        }
    }
}
