import QtQuick 2.8
//import "../code/utils.js" as Utils

QtObject {

    property var callback
    property bool debug: false
    property string currentHost
    readonly property string hostUrl: "http://%1/MCWS/v1/".arg(currentHost)

    signal dataReady(var data)

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
                var a = xhr.responseXML.documentElement;
                for (var i = 0; i < a.childNodes.length; ++i) {
                    var node = a.childNodes[i]
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
        xhr.open("GET", cmd);
        xhr.send();
    }

}
