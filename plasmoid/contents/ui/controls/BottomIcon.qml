import QtQuick 2.5
import QtQuick.Layouts 1.12
import org.kde.kirigami 2.8 as Kirigami

Kirigami.Icon {
    id: root
    source: 'kt-set-max-download-speed'

    Layout.preferredWidth: Kirigami.Units.iconSizes.small
    Layout.preferredHeight: Kirigami.Units.iconSizes.small

    signal clicked()

    MouseAreaEx {
        tipText: 'Bottom'
        onClicked: {
            root.clicked()
        }
    }
}

