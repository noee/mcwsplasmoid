import QtQuick 2.9
import QtQuick.Controls 2.4
import org.kde.plasma.core 2.0 as PlasmaCore

TextField {
    id: root

    property bool clearButtonShown: true
    selectByMouse: true

    PlasmaCore.IconItem {
        anchors {
            right: root.right
            rightMargin: 6
            verticalCenter: root.verticalCenter
        }
        //ltr confusingly refers to the direction of the arrow in the icon, not the text direction which it should be used in
        source: root.clearButtonShown ? (LayoutMirroring.enabled ? "edit-clear-locationbar-ltr" : "edit-clear-locationbar-rtl") : ""
        height: Math.max(root.height * 0.8, units.iconSizes.small)
        width: height
        opacity: (root.length > 0 && root.clearButtonShown && root.enabled) ? 1 : 0
        visible: opacity > 0
        Behavior on opacity {
            NumberAnimation {
                duration: units.longDuration
                easing.type: Easing.InOutQuad
            }
        }
        MouseArea {
            anchors.fill: parent
            onClicked: {
                root.text = ""
                root.forceActiveFocus()
            }
        }
    }


}
