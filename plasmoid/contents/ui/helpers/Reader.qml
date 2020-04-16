import QtQuick 2.8
import 'utils.js' as Utils

QtObject {

    property string currentHost
    property string hostUrl

    readonly property var forEach: Array.prototype.forEach

    onCurrentHostChanged: hostUrl = "http://%1/MCWS/v1/".arg(currentHost)

    signal connectionError(var msg, var cmd)
    signal commandError(var msg, var cmd)

    // Issue xhr mcws request, handle json/xml/text results
    function __exec(cmdstr, cb, json) {
        json = json !== undefined ? json : false

        var xhr = new XMLHttpRequest()

        xhr.onerror = () => {
            connectionError("Unable to connect: ", cmdstr)
        }

        xhr.onreadystatechange = () =>
        {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200) {
                    if (Utils.isFunction(cb)) {
                        // FIXME: Remove MPL? Check return format
                        if (xhr.getResponseHeader('Content-Type') === 'application/x-mediajukebox-mpl')
                            console.log('MPL:', cmdstr)
                        if (xhr.getResponseHeader('Content-Type') === 'application/x-mediajukebox-mpl'
                                || xhr.getResponseHeader('Content-Type') === 'application/json')
                            cb(xhr.response)
                        else
                            cb(xhr.responseXML.documentElement.childNodes)
                    }
                } else {
                    if (xhr.getResponseHeader('Content-Type') !== 'application/x-mediajukebox-mpl'
                            & xhr.getResponseHeader('Content-Type') !== 'application/json')
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
        if (json)
            xhr.responseType = 'json'
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

    // Get array of objects, callback(array)
    function loadObject(cmd, cb) {
        __exec(hostUrl + cmd, (nodes) =>
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

    // Get JSON array of objects, callback(array)
    function loadJSON(cmd, cb) {
        if (!Utils.isFunction(cb))
            return

        __exec(hostUrl + cmd, (json) =>
        {
           try {
               var arr = []
               json.forEach((item) => {
                    let obj = {}
                    for (var p in item) {
                        obj[Utils.toRoleName(p)] = String(item[p])
                    }
                    arr.push(obj)
                })

               cb(arr)
           }
           catch (err) {
               console.log(commandError(err, 'JSON data'))
           }
        }, true)
    }

    // Load MCWS JSON objects => model, callback(count)
    function loadModelJSON(cmd, model, cb) {
        if (model === undefined) {
            if (Utils.isFunction(cb))
                cb(0)
            return
        }

        // Look for/remove default obj which defines the model data structure
        if (model.count === 1) {
            var defObj = Object.assign({}, model.get(0))
            model.remove(0)
        }

        __exec(hostUrl + cmd, (json) =>
        {
            try {
               json.forEach((item) => {
                    let obj = Object.create(defObj)
                    for (var p in item)
                        obj[Utils.toRoleName(p)] = String(item[p])
                    model.append(obj)
              })
              cb(model.count)
            }
            catch (err) {
               console.log(commandError(err, 'JSON data'))
            }
        }, true)

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

            var defObj = {}
            if (model.count === 1) {
                defObj = Object.assign({}, model.get(0))
                model.remove(0)
            }

            __createObjectList(xmlStr, function(obj) { model.append(Object.assign(defObj, obj)) })

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
