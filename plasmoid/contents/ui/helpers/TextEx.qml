import QtQuick 2.9
import QtQuick.Controls 2.5
import org.kde.kirigami 2.8 as Kirigami

Kirigami.ActionTextField {
    id: root

    rightActions: [
        Kirigami.Action {
            iconName: "edit-clear"
            visible: root.text.length !== 0
            onTriggered: {
                root.text = ""
                root.accepted()
            }
        }
    ]
}
