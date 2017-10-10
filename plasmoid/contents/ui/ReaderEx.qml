import QtQuick 2.0

Item {

    property string currentHost
    property bool debug: false
    property var onCommandError
    property var onConnectionError

    Component {
        id: caller
        Reader {}
    }
    function runQuery(query, callback)
    {
        var rdr = caller.createObject(null, {"currentHost": currentHost, "debug": debug})

        rdr.connectionError.connect(function(msg, cmd)
        {
            if (typeof onConnectionError === "function")
                onConnectionError(msg, cmd)
            rdr.destroy()
        })

        rdr.commandError.connect(function(msg, cmd)
        {
            if (typeof onCommandError === "function")
                onCommandError(msg, cmd)
            rdr.destroy()
        })

        rdr.dataReady.connect(function(data)
        {
            if (typeof callback === "function")
                callback(data)
            rdr.destroy()
        })

        rdr.runQuery(query)
    }

}
