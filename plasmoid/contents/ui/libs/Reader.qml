import QtQuick 2.8
import '../code/utils.js' as Utils

QtObject {

    property bool debug: false
    property string currentHost
    property string hostUrl

    readonly property var forEach: Array.prototype.forEach
    readonly property var fldRegExp: /(?:<Field Name=")(.*?)(?:<\/Field>)/

    onCurrentHostChanged: hostUrl = "http://%1/MCWS/v1/".arg(currentHost)

    signal connectionError(var msg, var cmd)
    signal commandError(var msg, var cmd)

    // Does all the xhr stuff with the mcwsrequest
    function __exec(cmdstr, cb) {
        var xhr = new XMLHttpRequest()
        xhr.onreadystatechange = function()
        {
            if (xhr.readyState === XMLHttpRequest.DONE) {

                if (xhr.status === 0) {
                    connectionError("Unable to connect: ", cmdstr)
                    return
                }
                if (xhr.status !== 200) {
                    if (xhr.getResponseHeader('Content-Type') !== 'application/x-mediajukebox-mpl')
                        commandError(xhr.responseXML.documentElement.attributes[1].value
                                     + ' <status: %1:%2>'.arg(xhr.status).arg(xhr.statusText), cmdstr)
                    else
                        commandError('<status: %1:%2>'.arg(xhr.status).arg(xhr.statusText), cmdstr)
                    return
                }

                // Check return format, MPL returns as a text file download
                if (Utils.isFunction(cb))
                    cb(xhr.getResponseHeader('Content-Type') !== 'application/x-mediajukebox-mpl'
                                ? xhr.responseXML.documentElement.childNodes
                                : xhr.responseText)

            }
        }

        if (debug)
            console.log(cmdstr)

        xhr.open("GET", cmdstr);
        xhr.send();
    }
    // Load a model with Key/Value pairs
    function loadKVModel(cmd, model, cb) {
        if (model === undefined) {
            if (Utils.isFunction(cb))
                cb(0)
            return
        }

        __exec(hostUrl + cmd, function(nodes)
        {
            // XML nodes, key = attr.name, value = node.value
            forEach.call(nodes, function(node)
            {
                if (node.nodeType === 1) {
                    model.append({ key: Utils.toRoleName(node.attributes[0].value), value: node.childNodes[0].data })
                }
            })
            if (Utils.isFunction(cb))
                cb(model.count)
        })
    }
    // Return an mcws object
    function loadObject(cmd, cb) {
        __exec(hostUrl + cmd, function(nodes)
        {
            // XML nodes, builds obj as single object with props = nodes
            if (typeof nodes === 'object') {
                var obj = {}
                forEach.call(nodes, function(node)
                {
                    if (node.nodeType === 1) {
                        obj[Utils.toRoleName(node.attributes[0].value)]
                                = node.childNodes[0] !== undefined ? node.childNodes[0].data : 'Null'
                    }
                })
                if (Utils.isFunction(cb))
                    cb(obj)
            // MPL string (multiple Items/multiple Fields for each item) builds an array of item objs
            } else if (typeof nodes === 'string') {
                var list = []

                __createObjectList(nodes, function(obj) { list.push(obj) })

                if (Utils.isFunction(cb))
                    cb(list)
            }
        })
    }
    // Load a model with mcws objects (MPL)
    function loadModel(cmd, model, cb) {
        if (model === undefined) {
            if (Utils.isFunction(cb))
                cb(0)
            return
        }

        __exec(hostUrl + cmd, function(xmlStr)
        {
            __createObjectList(xmlStr, function(obj) { model.append(obj) })

            if (Utils.isFunction(cb))
                cb(model.count)
        })
    }
    // Helper to build obj list for the model
    function __createObjectList(xmlstr, fun) {
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
                    fields[Utils.toRoleName(o[0])] = o[1]
                }
            })
            fun(fields)
        })
    }
    // Run an mcws cmd
    function exec(cmd) {
        __exec(hostUrl + cmd)
    }

}
