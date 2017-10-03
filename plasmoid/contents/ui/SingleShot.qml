import QtQuick 2.0

Item {
    Component {
        id: compCaller
        Timer {}
    }
    function singleShot(interval, callback) {
        var caller = compCaller.createObject(null, { "interval": interval })
        caller.triggered.connect(function ()
        {
            callback()
            caller.destroy()
        })
        caller.start()
    }
 
}
