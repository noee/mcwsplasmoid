import QtQuick 2.8
import QtQuick.Controls 2.4
import QtQuick.Layouts 1.3
import '../helpers'

ColumnLayout {

    property alias cfg_updateInterval: updateInterval.value
    property alias cfg_hostConfig: configMcws.hostConfig
    property alias cfg_autoConnect: autoConnect.checked

    ConfigMcws { id: configMcws }

    Item { Layout.fillHeight: true }

    GroupSeparator { text: 'Options' }

    RowLayout {
        CheckBox {
            id: autoConnect
            Layout.fillWidth: true
            text: 'Maintain Host Connection'
        }
        Label {
            text: i18n('Update interval:')
            Layout.alignment: Qt.AlignRight
        }
        FloatSpinner {
            id: updateInterval
            decimals: 1
        }

    }
}
