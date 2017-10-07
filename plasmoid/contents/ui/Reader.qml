import QtQuick 2.8
//import "../code/utils.js" as Utils

QtObject {

    property var callback
    property bool debug: false
    property string currentHost
    readonly property string hostUrl: "http://%1/MCWS/v1/".arg(currentHost)

    signal dataReady(var data)
    signal connectionError(var host, var msg)
    signal commandError(var msg, var cmd)

    function runQuery(cmdstr, model, ndx) {
        var cmd = hostUrl + cmdstr
        var useObj = model === undefined || ndx === undefined
        var values = {}
        if (debug)
            console.log("Load model direct: " + !useObj + ", " + cmd)

        var xhr = new XMLHttpRequest

        xhr.onreadystatechange = function()
        {
            if (xhr.readyState === XMLHttpRequest.DONE) {

                // check for null return, connect failure
                var resp = xhr.responseXML
                if (resp === null) {
                    connectionError(currentHost, "Unable to connect")
                    return
                }

                var doc = resp.documentElement;

                // print resp status with cmd
                if (doc.attributes[0].value !== "OK") {
                    console.log(doc.attributes[1].value + "\n" + cmd)
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
    }

    function exec(cmdstr) {
        var cmd = hostUrl + cmdstr
        if (debug)
            console.log(cmd)

        var xhr = new XMLHttpRequest

        xhr.onreadystatechange = function()
        {
            if (xhr.readyState === XMLHttpRequest.DONE) {

                // check for null return, connect failure
                var resp = xhr.responseXML
                if (resp === null) {
                    connectionError(currentHost, "Unable to connect")
                    return
                }

                var doc = resp.documentElement;

                // print resp status with cmd
                if (doc.attributes[0].value !== "OK") {
                    console.log(doc.attributes[1].value + "\n" + cmd)
                    commandError(doc.attributes[1].value, cmd)
                    return
                }
            }
        }

        xhr.open("GET", cmd);
        xhr.send();
    }

}
