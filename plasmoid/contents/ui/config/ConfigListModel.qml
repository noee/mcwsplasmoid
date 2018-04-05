import QtQuick 2.9
import '..'

Item {
    property alias items: lm
    property string configKey: ''
    property string outputStr: ''

    function setEnabled(index, val) {
        lm.setProperty(index, 'enabled', val)
        lm.save()
    }

    ListModel {
        id: lm

        onRowsMoved: save()
        onRowsRemoved: save()

        function save() {
            event.queueCall(100, function() {
                var arr = []
                for (var i=0; i<count; ++i)
                    arr.push(get(i))
                outputStr = JSON.stringify(arr)
            })
        }

        function load() {
            lm.rowsInserted.disconnect(lm.save)
            JSON.parse(plasmoid.configuration[configKey]).forEach(function(obj) {
                lm.append(obj)
            })
            lm.rowsInserted.connect(lm.save)
        }

        Component.onCompleted: event.queueCall(0, load)
    }
    SingleShot {
        id: event
    }
}
