import QtQuick 2.8
//import "../code/utils.js" as Utils

QtObject {

    property var callback
    property bool debug: false
    property string currentHost
    readonly property string hostUrl: "http://%1/MCWS/v1/".arg(currentHost)

    signal dataReady(var data)
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

        xhr.open("GET", cmd);
        xhr.send();
    }

    function runQuery(cmdstr, model, ndx)
    {
        var cmd = hostUrl + cmdstr
        var useObj = model === undefined || ndx === undefined
        var values = {}
        if (debug)
            console.log("Load model direct: " + !useObj + ", " + cmd)

        getResponse(cmd, function(xml)
        {
            for (var i = 0; i < xml.childNodes.length; ++i) {
                var node = xml.childNodes[i]
                if (node.nodeName === "Item") {
                    values[String(node.attributes[0].value).toLowerCase()] = node.childNodes[0].data
                    if (!useObj) {
                        model.setProperty(ndx, String(node.attributes[0].value).toLowerCase(), node.childNodes[0].data)
                    }
                }
            }
            // embed index into data struct
            if (ndx !== undefined & ndx >= 0) {
                values["index"] = ndx
            }
            if (typeof callback === "function")
                callback(values)
            else
                dataReady(values)

        })

        /*
        var xhr = new XMLHttpRequest
        xhr.onreadystatechange = function()
        {
            if (xhr.readyState === XMLHttpRequest.DONE) {

                console.log(xhr.getAllResponseHeaders())
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

                for (var i = 0; i < doc.childNodes.length; ++i) {
                    var node = doc.childNodes[i]
                    if (node.nodeName === "Item") {
                        values[String(node.attributes[0].value).toLowerCase()] = node.childNodes[0].data
                        if (!useObj) {
                            model.setProperty(ndx, String(node.attributes[0].value).toLowerCase(), node.childNodes[0].data)
                        }
                    }
                }
                // embed index into data struct
                if (ndx !== undefined & ndx >= 0) {
                    values["index"] = ndx
                }
                if (typeof callback === "function")
                    callback(values)
                else
                    dataReady(values)
            }
        }
        xhr.open("GET", cmd);
        xhr.send();
        */
    }

    function exec(cmdstr)
    {
        var cmd = hostUrl + cmdstr
        if (debug)
            console.log(cmd)
        getResponse(cmd)
    }

}
