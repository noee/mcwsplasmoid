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

                if (xhr.getResponseHeader('Content-Type').indexOf('x-mediajukebox-mpl') === -1) {
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

                } else {
                    // MPL or other
                    if (typeof callback === "function")
                        callback(xhr.responseText)
                }

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
            // XML nodes, builds obj as single object with props = nodes
            if (typeof nodes === 'object')
            {
                var obj = {}
                forEach.call(nodes, function(node)
                {
                    if (node.nodeType === 1)
                        obj[node.attributes[0].value.toLowerCase().replace(/ /g,'')] = node.childNodes[0].data
                })
                if (typeof callback === "function")
                    callback(obj)
            // MPL string (multiple Items/multiple Fields for each item) builds an array of item objs
            } else if (typeof nodes === 'string')
            {
                var list = []
                var items = nodes.split('<Item>')
                items.shift()
                items.forEach(function(item)
                {
                    var fl = item.split('\r')
                    var fields = {}
                    fl.forEach(function(fldstr)
                    {
                        var l = /(?:<Field Name=)(.*?)(?:<\/Field>)/.exec(fldstr)
                        if (l !== null) {
                            var o = l.pop().split('>')
                            fields[o[0].replace(/("| )/g,'').toLowerCase()] = o[1]
                        }
                    })
                    list.push(fields)
                })
                if (typeof callback === "function")
                    callback(list)
            }

        })

    }

    function exec(cmd)
    {
        getResponseXml(cmd)
    }

}
