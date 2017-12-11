import QtQuick 2.8

QtObject {

    property bool debug: false
    property string currentHost
    readonly property string hostUrl: "http://%1/MCWS/v1/".arg(currentHost)

    signal connectionError(var msg, var cmd)
    signal commandError(var msg, var cmd)

    function getResponse(cmd, callback)
    {
        var xhr = new XMLHttpRequest

        xhr.onreadystatechange = function()
        {
            if (xhr.readyState === XMLHttpRequest.DONE) {

                // check for null return, connect failure
                var resp = xhr.responseXML
                if (resp === null) {
                    connectionError("Unable to connect", cmd)
                    return
                }

                var doc = resp.documentElement;

                // print resp status with cmd
                if (xhr.statusText !== "OK") {
                    commandError(doc.attributes[1].value, cmd)
                    return
                }

                //
                if (typeof callback === "function")
                    callback(doc)
            }
        }

        if (debug)
            console.log(hostUrl + cmd)

        xhr.open("GET", hostUrl + cmd);
        xhr.send();
    }

    function runQuery(cmdstr, callback)
    {
        getResponse(cmdstr, function(xml)
        {
            var values = {}
            for (var i = 0, len = xml.childNodes.length; i < len; ++i)
            {
                var node = xml.childNodes[i]
                if (node.nodeName === "Item")
                {
                    values[node.attributes[0].value.toLowerCase()] = node.childNodes[0].data
                }
            }
            // if callback is set, then call it with the data object
            // otherwise emit the object
            if (typeof callback === "function")
                callback(values)

        })

    }

    function exec(cmdstr)
    {
        getResponse(cmdstr)
    }

}
