import QtQuick 2.8
import 'utils.js' as Utils

QtObject {

    property string currentHost
    property string hostUrl

    readonly property var forEach: Array.prototype.forEach

    onCurrentHostChanged: hostUrl = "http://%1/MCWS/v1/".arg(currentHost)

    signal connectionError(var msg, var cmd)
    signal commandError(var msg, var cmd)

    // Does all the xhr stuff with the mcwsrequest
    function __exec(cmdstr, cb) {
        var xhr = new XMLHttpRequest()

        xhr.onerror = function() {
            connectionError("Unable to connect: ", cmdstr)
        }

        xhr.onreadystatechange = function()
        {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200) {
                    if (Utils.isFunction(cb))
                        // Check return format, MPL returns as a text file download
                        cb(xhr.getResponseHeader('Content-Type') !== 'application/x-mediajukebox-mpl'
                                    ? xhr.responseXML.documentElement.childNodes
                                    : xhr.responseText)
                } else {
                    if (xhr.getResponseHeader('Content-Type') !== 'application/x-mediajukebox-mpl')
                        commandError(xhr.responseXML
                                        ? xhr.responseXML.documentElement.attributes[1].value
                                        : 'Connection error'
                                     + ' <status: %1:%2>'.arg(xhr.status).arg(xhr.statusText), cmdstr)
                    else
                        commandError('<status: %1:%2>'.arg(xhr.status).arg(xhr.statusText), cmdstr)
                }
            }
        }

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
                    model.append({ key: Utils.toRoleName(node.attributes[0].value)
                                 , value: isNaN(node.firstChild.data)
                                          ? node.firstChild.data
                                          : +node.firstChild.data })
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
                    if (node.nodeType === 1 && node.firstChild !== null) {
                        obj[Utils.toRoleName(node.attributes[0].value)] = isNaN(node.firstChild.data)
                                                ? node.firstChild.data
                                                : +node.firstChild.data
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
        var fldRegExp = /(?:< Name=")(.*?)(?:<\/>)/
        var items = xmlstr
//                .replace(/&quot;/g, '"')
//                .replace(/&#39;/g, "'")
//                .replace(/&lt;/g, '<')
//                .replace(/&gt;/g, '>')
            .replace(/&amp;/g, '&')
            .replace(/Field/g,'')
            .split('<Item>')

        // ignore first item, it's the MPL header info
        for (var i=1, len=items.length; i<len; ++i) {

            var fl = items[i].split('\r\n')
            var fields = {}
            fl.forEach(function(fldstr)
            {
                var l = fldRegExp.exec(fldstr)
                if (l !== null) {
                    var o = l.pop().split('">')
                    // Can't convert numbers, same field will vary (string/number)
                    fields[Utils.toRoleName(o[0])] = o[1]
                }
            })
            fun(fields)
        }
    }
    // Run an mcws cmd
    function exec(cmd) {
        __exec(hostUrl + cmd)
    }

}
