import QtQuick 2.8
import QtQuick.Controls 2.2

ListView {
    id: list

    function modelItem() { return model ? model.get(currentIndex) : undefined }

    anchors.fill: parent
    spacing: 6
    clip: true
    highlightMoveDuration: 1
    highlight: Rectangle {
        width: list.width
        color: theme.highlightColor
        radius: 5
        y: list.currentItem ? list.currentItem.y : -1
        Behavior on y {
            SpringAnimation {
                spring: 2.5
                damping: 0.3
            }
        }
    }
}
