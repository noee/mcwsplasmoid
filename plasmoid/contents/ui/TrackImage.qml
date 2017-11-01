import QtQuick 2.8
import QtQuick.Controls 2.2
import QtGraphicalEffects 1.0

Item {
    height: 32
    width: height
    property alias image: img
    property bool animateLoad: false
    Image {
        id: img
        sourceSize.height: parent.height
        sourceSize.width: parent.width
        opacity: .8
        layer.enabled: true
        layer.effect: DropShadow {
            transparentBorder: true
            horizontalOffset: 2
            verticalOffset: 2
            color: "#80000000"
        }

        NumberAnimation on opacity {
            id: load
            to: .8
            duration: 400
        }
        onStatusChanged: {
            if (status === Image.Error)
                source = "default.png"
            if (animateLoad)
                if (status === Image.Ready) //source.toString() !== "" &&
                {
                    opacity = 0
                    load.start()
                }
        }
    }

}
