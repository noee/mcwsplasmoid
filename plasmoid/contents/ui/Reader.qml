import QtQuick 2.8

QtObject {

    property bool debug: false
    property string currentHost
    property string hostUrl

    readonly property var forEach: Array.prototype.forEach
    readonly property var fldRegExp: /(?:<Field Name=")(.*?)(?:<\/Field>)/

    onCurrentHostChanged: hostUrl = "http://%1/MCWS/v1/".arg(currentHost)

    signal connectionError(var msg, var cmd)
    signal commandError(var msg, var cmd)

    function getResponse(cmd, callback) {
        var cmdstr = hostUrl + cmd
        var xhr = new XMLHttpRequest

        xhr.onreadystatechange = function()
        {
            if (xhr.readyState === XMLHttpRequest.DONE) {

                if (xhr.status === 0) {
                    connectionError("Unable to connect: ", cmdstr)
                    return
                }

                // Check return format (if !MPL)
                if (xhr.getResponseHeader('Content-Type').indexOf('x-mediajukebox-mpl') === -1) {
                    var resp = xhr.responseXML

                    if (xhr.status !== 200) {
                        commandError(resp.documentElement.attributes[1].value
                                     + ' <status: %1:%2>'.arg(xhr.status).arg(xhr.statusText), cmdstr)
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

    function loadObject(cmd, callback) {
        getResponse(cmd, function(nodes)
        {
            // XML nodes, builds obj as single object with props = nodes
            if (typeof nodes === 'object') {
                var obj = {}
                forEach.call(nodes, function(node)
                {
                    if (node.nodeType === 1)
                        obj[node.attributes[0].value.toLowerCase().replace(/ /g,'')] = node.childNodes[0].data
                })
                if (typeof callback === "function")
                    callback(obj)
            // MPL string (multiple Items/multiple Fields for each item) builds an array of item objs
            } else if (typeof nodes === 'string') {
                var list = []

                createObjectList(nodes, function(obj) { list.push(obj) })

                if (typeof callback === "function")
                    callback(list)
            }
        })
    }

    function loadModel(cmd, model, callback) {
        if (model === undefined) {
            callback(0)
            return
        }

        getResponse(cmd, function(xmlStr)
        {
            createObjectList(xmlStr, function(obj) { model.append(obj) })

            if (typeof callback === "function")
                callback(model.count)
        })
    }

    function createObjectList(xmlstr, fun) {
        var items = xmlstr
//                .replace(/&quot;/g, '"')
//                .replace(/&#39;/g, "'")
//                .replace(/&lt;/g, '<')
//                .replace(/&gt;/g, '>')
            .replace(/&amp;/g, '&')
            .split('<Item>')

        // remove first item, it's the MPL header info
        items.shift()
        items.forEach(function(item)
        {
            var fl = item.split('\r\n')
            var fields = {}
            fl.forEach(function(fldstr)
            {
                var l = fldRegExp.exec(fldstr)
                if (l !== null) {
                    var o = l.pop().split('">')
                    fields[o[0].replace(/( )/g,'').toLowerCase()] = o[1]
                }
            })
            fun(fields)
        })
    }

    function exec(cmd) {
        getResponse(cmd)
    }

}
