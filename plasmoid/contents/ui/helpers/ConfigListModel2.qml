import QtQuick 2.9

BaseListModel {
    property string configKey: ''
    property string outputStr: ''
    property bool autoSave: false

    function setEnabled(index, val) {
        val = val === undefined ? true : val
        setProperty(index, 'enabled', val)
        save()
    }
    function flush() {
        plasmoid.configuration[configKey] = outputStr
        outputStr = ''
    }

    function save() {
        outputStr = JSON.stringify(toArray())
        if (autoSave)
            flush()
    }
    function load() {
        rowsInserted.disconnect(save)
        JSON.parse(plasmoid.configuration[configKey]).forEach(function(obj) {
            append(obj)
        })
        rowsInserted.connect(save)
    }

    onRowsMoved: save()
    onRowsRemoved: save()

    Component.onCompleted: load()
}
