import QtQuick 2.9

Item {
    property alias items: lm
    property string configKey: ''
    property string outputStr: ''
    property var objectDef: []

    function setEnabled(index, val) {
        lm.setProperty(index, 'enabled', val)
        lm.save()
    }

    BaseListModel {
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
            clear()
            lm.rowsInserted.disconnect(lm.save)

            try {
                var arr = JSON.parse(plasmoid.configuration[configKey])
                arr.forEach((obj) => {
                    objectDef.forEach((prop) => {
                        if (!obj.hasOwnProperty(prop))
                            obj[prop] = ''
                    })
                    lm.append(obj)
                })
            }
            catch (err) {
                var obj = {}
                objectDef.forEach((prop) => {
                    if (prop.includes('host') || prop.includes('name'))
                        obj[prop] = 'Failed parse'
                    else if (prop.includes('enabled'))
                        obj[prop] = false
                    else
                        obj[prop] = '0'
                })
                lm.append(obj)
            }

            lm.rowsInserted.connect(lm.save)
        }

        Component.onCompleted: event.queueCall(load)
    }

    SingleShot { id: event }
}
