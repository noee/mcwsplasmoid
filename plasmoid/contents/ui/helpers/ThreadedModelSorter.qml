import QtQuick 2.8
import 'utils.js' as Utils

WorkerScript {
    id: ws
    source: 'sorter.mjs'

    property var model

    signal start()
    signal done()

    function sort(role) {
        start()
        sendMessage({ 'lm': model, 'role': Utils.toRoleName(role) })
    }

    onMessage: {
        model.clear()
        messageObject.results.forEach((item) => { model.append(item)})
        done()
    }
}

