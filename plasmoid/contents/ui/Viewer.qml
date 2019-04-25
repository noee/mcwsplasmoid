import QtQuick 2.8
import QtQuick.Controls 2.5
import org.kde.kirigami 2.5 as Kirigami

ListView {
    id: list

    property bool useHighlight: true

    function modelItem() { return model ? model.get(currentIndex) : undefined }

    Component {
        id: hl
        Rectangle {
                width: list.width
                color: Kirigami.Theme.highlightColor
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

    anchors.fill: parent
    spacing: 6
    clip: true
    highlightMoveDuration: 1
    highlight: useHighlight ? hl : null
}
