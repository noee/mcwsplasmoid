import QtQuick 2.8

QtObject {

    property bool debug: false
    property string currentHost
    readonly property string hostUrl: "http://%1/MCWS/v1/".arg(currentHost)
    readonly property var forEach: Array.prototype.forEach

    signal connectionError(var msg, var cmd)
    signal commandError(var msg, var cmd)

    function getResponseXml(cmd, callback)
    {
        var cmdstr = hostUrl + cmd
        var xhr = new XMLHttpRequest

        xhr.onreadystatechange = function()
        {
            if (xhr.readyState === XMLHttpRequest.DONE) {

                // check for null return, connect failure
                var resp = xhr.responseXML
                if (resp === null) {
                    connectionError("Unable to connect", cmdstr)
                    return
                }

                // print resp status with cmd
                if (xhr.statusText !== "OK") {
                    commandError(resp.documentElement.attributes[1].value, cmdstr)
                    return
                }

                if (typeof callback === "function")
                    callback(resp.documentElement.childNodes)
            }
        }

        if (debug)
            console.log(cmdstr)

        xhr.open("GET", cmdstr);
        xhr.send();
    }

    function getResponseObject(cmd, callback)
    {
        getResponseXml(cmd, function(nodes)
        {
            var obj = {}
            forEach.call(nodes, function(node)
            {
                if (node.nodeType === 1)
                    obj[node.attributes[0].value.toLowerCase()] = node.childNodes[0].data
            })

            if (typeof callback === "function")
                callback(obj)
        })

    }

    function exec(cmd)
    {
        getResponseXml(cmd)
    }

}
