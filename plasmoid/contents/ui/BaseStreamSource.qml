import QtQuick 2.9
import 'helpers'

Item {

    property alias poller: poller
    property var listDelegate
    property string logo: 'controls/default.png'

    property BaseListModel channels: BaseListModel{}
    property BaseListModel tracks: BaseListModel{}

    signal trackChanged(var track)

    Timer {
        id: poller; repeat: true; interval: 30000
    }
}
