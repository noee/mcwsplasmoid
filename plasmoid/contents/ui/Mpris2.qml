import QtQuick 2.8

Item {
    id: root

    property string currentHost: ''
    property int zoneCount: 0

    readonly property string path: plasmoid.file("", "libs/mcwsmpris2")
    // stores mcwsmpris2 process by zone index
    property var __procs: ({})

    onCurrentHostChanged: {
        stopAll()
    }

    onEnabledChanged: {
        if (currentHost !== '')
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
        if (isRunning(zonendx) || accessKey === '')
            return false

        var p = proc.createObject(root)
        p.exec('%1 -k %2 -z %3 -x'.arg(path).arg(accessKey).arg(zonendx))
        p.exited.connect(function(c, s, o, e) {
            console.log(c + ' ' + o)
            p.destroy()
        })

        __procs[zonendx] = p
        return true
    }

    function stop(zonendx) {
        if (isRunning(zonendx)) {
            __procs[zonendx].destroy()
            __procs[zonendx] = null
            return true
        }
        return false
    }

    function isRunning(zonendx) {
        return __procs[zonendx] === undefined || __procs[zonendx] === null
                ? false
                : true
    }
    function stopAll() {
        for (var i in __procs) {
            stop(i)
        }
        __procs = {}
    }

    function init() {
        // get cfg for currentHost, if exists, start mpris on each zone index
        var hostObj = JSON.parse(plasmoid.configuration.mprisConfig).find(function(cfg) {
                        return cfg.host === currentHost })

        if (hostObj !== undefined & hostObj.enabled) {
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
}
