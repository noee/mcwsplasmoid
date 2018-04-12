import QtQuick 2.8

Item {
    id: root

    property string currentHost: ''
    property int zoneCount: 0
    readonly property string path: plasmoid.file("", "libs/mcwsmpris2")

    property var __procs: []

    onEnabledChanged: {
        if (enabled & currentHost !== '')
            init()
    }

    Connections {
        target: plasmoid.configuration
        enabled: path !== '' && root.enabled
        onMprisConfigChanged: {
            stopAll()
            init()
        }
    }

    function start(accessKey, zonendx) {
        if (accessKey === '')
            return false

        var p = proc.createObject(root)
        p.exec('%1 -k %2 -z %3 -xs'.arg(path).arg(accessKey).arg(zonendx))
        __procs.push({ zone: zonendx, proc: p, valid: true })
        return true
    }

    function stopAll() {
        // clean up dyn procs
        // Have to flag each first as destroy will not cleanly stop the proc
        if (__procs.length > 0) {
            // flag and zonelist
            var zl = []
            __procs.forEach(function(p) { p.valid = false; zl.push(p.zone) })
            // ask running procs for zonelist to quit
            run.exec('%1 %2 --stopall %3'.arg(path).arg(currentHost).arg(zl.join(',')))
            // give it a sec, replace the proc array with only non-flagged
            event.queueCall(500, function() {
                // destroy the flagged dyn proc
                __procs.forEach(function(p) {
                    if (!p.valid) {
                        p.proc.destroy()
                    }
                })
                // new array, just valid objs
                __procs = __procs.filter(function(item){ return item.valid })
            })
        }
    }

    function init() {
        // get cfg for currentHost, if exists, start mpris on each zone index
        var hostObj = JSON.parse(plasmoid.configuration.mprisConfig).find(function(cfg) {
                        return cfg.host === currentHost })

        if (hostObj !== undefined && hostObj.enabled) {
            if (hostObj.zones === '*') {
                for (var i = 0; i < zoneCount; ++i)
                    start(hostObj.accessKey, i)
            } else if (hostObj.zones !== '') {
                hostObj.zones.split(',').forEach(function(zonendx) {
                    if (zonendx < zoneCount)
                        start(hostObj.accessKey, zonendx)
                    else
                        console.log('MPRIS2: Cannot monitor a zone that does not exist: ' + zonendx + '. Ignoring.')
                })
            }
        }
    }

    Component {
        id: proc
        Process { }
    }
    Process {
        id: run
    }
}
