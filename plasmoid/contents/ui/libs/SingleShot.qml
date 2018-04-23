import QtQuick 2.0

Item {
    Component {
        id: compCaller
        Timer {}
    }
    function queueCall(delay, callback, params) {
        var caller = compCaller.createObject(null, { interval: delay, running: true })
        caller.triggered.connect(function ()
        {
            if (params !== undefined)
                callback.apply(null, params)
            else
                callback()
            caller.destroy()
        })
    }

}
