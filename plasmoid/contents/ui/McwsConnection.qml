import QtQuick 2.8
import "../code/utils.js" as Utils
import "models"

Item {
    readonly property bool isConnected: (d.zoneCount > 0) && d.modelReady
    property ListModel model: ListModel{}
    readonly property var playlists: playlists
    readonly property alias timer: pnTimer
    readonly property alias hostUrl: reader.hostUrl

    readonly property var zoneModel: {
        var list = []
        for(var i=0; i<model.count; ++i)
            list.push({ "zoneid": model.get(i).zoneid, "zonename": model.get(i).zonename })
        return list
    }

    // Player states
    readonly property string stateStopped:  "0"
    readonly property string statePaused:   "1"
    readonly property string statePlaying:  "2"
    readonly property string stateAborting: "3"
    readonly property string stateBuffering:"4"

    // private stuff
    QtObject{
        id: d
        property int zoneCount: 0
        property int currZoneIndex: 0
        property bool modelReady: false
        property int initCtr: 0

        function init(host) {
            pnTimer.stop()
            model.clear()
            playlists.clear()
            zoneCount = 0
            currZoneIndex = 0
            initCtr = 0
            modelReady = false
            reader.currentHost = host
        }

        function loadRepeatMode(zonendx) {
            dynReader.runQuery("Playback/Repeat?ZoneType=Index&Zone=" + zonendx
                 , function(data)
                 {
                     model.set(zonendx, {"repeat": data["mode"]})
                 })
        }
    }

    signal connectionReady(var zonendx)
    signal trackKeyChanged(var zonendx, var trackKey)

    function run(cmd, zonendx) {
        if (zonendx === undefined)
            reader.exec(cmd)
        else {
            var delim = cmd.indexOf('?') === -1 ? '?' : '&'
            reader.exec("%1%2Zone=%3".arg(cmd).arg(delim).arg(model.get(zonendx).zoneid))
            event.singleShot(300, function(){ updateModelItem(zonendx) })
        }
    }

    function zonesByStatus(status) {
        var list = []
        for(var i=0; i<model.count; ++i) {
            if (model.get(i).status === status)
                list.push(i)
        }
        return list
    }
    function imageUrl(filekey, size) {
        var imgsize = (size === undefined | size === null) ? 'medium' : size
        return hostUrl + "File/GetImage?Thumbnailsize=" + imgsize + "&File=" + filekey
    }

    function updateModel(state, include) {
        var inclStatus = (include === undefined || include === null) ? true : include

        if (inclStatus) {
            for (var z=0; z<model.count; ++z) {
                if (model.get(z).state === state) {
                    updateModelItem(z)
                }
            }
        }
        else {
            for (var z=0; z<model.count; ++z) {
                if (model.get(z).state !== state) {
                    updateModelItem(z)
                }
            }
        }
    }
    function updateModelItem(ndx) {
        // reset some transient fields
        model.setProperty(ndx, "linkedzones", "")
        // pass model/ndx so the reader will update it directly
        reader.runQuery("Playback/Info?zone=" + model.get(ndx).zoneid, model, ndx)
    }
    function connect(host) {
        // reset everything
        d.init(host)
        // Set callback to get zones, reset when done to prepare reader for pn poller
        reader.callback = function(data)
        {
            // seeding model entries
            d.zoneCount = data["numberzones"]
            d.currZoneIndex = data["currentzoneindex"]
            for(var i = 0; i<d.zoneCount; ++i) {
                // setup defined props in the model for each zone
                model.append({"zoneid": data["zoneid"+i]
                                   , "zonename": data["zonename"+i]
                                   , "state": stateStopped
                                   , "linked": false
                                   , "mute": false
                                   , "prevfilekey": '-1'
                               })
                d.loadRepeatMode(i)
            }
            updateModel(statePlaying, false)
            pnTimer.start()
            reader.callback = null
        }
        reader.runQuery("Playback/Zones")
    }

    function play(zonendx) {
        run("Playback/PlayPause", zonendx)
    }
    function previous(zonendx) {
        run("Playback/Previous", zonendx)
    }
    function next(zonendx) {
        run("Playback/Next", zonendx)
    }
    function stop(zonendx) {
        run("Playback/Stop", zonendx)
    }
    function stopAllZones() {
        run("Playback/StopAll")
    }

    function unLinkZone(zonendx) {
        run("Playback/UnlinkZones", zonendx)
    }
    function linkZones(zone1id, zone2id) {
        run("Playback/LinkZones?Zone1=" + zone1id + "&Zone2=" + zone2id)
    }

    function isMuted(zonendx) {
        return model.get(zonendx).mute
    }
    function toggleMute(zonendx) {
        setMute(zonendx, !isMuted(zonendx))
    }
    function setMute(zonendx, mute) {
        var val = (mute === undefined)
                ? "0"
                : mute ? "1" : "0"

        run("Playback/Mute?Set=" + val + "&ZoneType=Index", zonendx)
    }
    function setVolume(level, zonendx) {
        run("Playback/Volume?Level=" + level, zonendx)
    }

    function shuffle(zonendx) {
        run("Playback/Shuffle?Mode=reshuffle", zonendx)
    }
    function setPlayingPosition(pos, zonendx) {
        run("Playback/Position?Position=" + pos, zonendx)
    }
    function setRepeat(mode, zonendx) {
        run("Playback/Repeat?Mode=" + mode, zonendx)
        event.singleShot(250, function() { d.loadRepeatMode(zonendx) })
    }
    function repeatMode(zonendx) {
        return zonendx >= 0 ? model.get(zonendx).repeat : ""
    }

    function removeTrack(trackndx, zonendx) {
        run("Playback/EditPlaylist?Action=Remove&Source=" + trackndx, zonendx);
    }
    function clearPlaylist(zonendx) {
        run("Playback/ClearPlaylist", zonendx);
    }
    function playTrack(pos, zonendx) {
        run("Playback/PlaybyIndex?Index=" + pos, zonendx);
    }
    function playTrackByKey(filekey, zonendx) {
        var pos = +model.get(zonendx).playingnowposition + 1
        run("Playback/PlaybyKey?Key=%1&Location=%2".arg(filekey).arg(pos), zonendx)
        event.singleShot(500, function() { playTrack(pos, zonendx) })
    }
    function addTrack(filekey, next, zonendx)
    {
        searchAndAdd("[key]=" + filekey, next, false, zonendx)
    }

    function queueAlbum(filekey, next, zonendx) {
        run("Playback/PlaybyKey?Key=%1&Album=1&Location=%2".arg(filekey).arg(next ? "Next" : "End"), zonendx)
    }
    function playAlbum(filekey, zonendx) {
        run("Playback/PlaybyKey?Album=1&Key=" + filekey, zonendx)
    }
    function searchAndPlayNow(srch, shuffleMode, zonendx) {
        run("Files/Search?Action=Play&query=" + srch + (shuffleMode ? "&Shuffle=1" : ""), zonendx)
    }
    function searchAndAdd(srch, next, shuffleMode, zonendx) {
        run("Files/Search?Action=Play&query=%1&PlayMode=%2".arg(srch).arg(next ? "NextToPlay" : "Add"), zonendx)
        if (shuffleMode)
            event.singleShot(500, function() { shuffle(zonendx) })
    }

    function handleError(msg, cmd) {
        console.log("MCWS Error: " + msg + ": " + cmd)
    }

    SingleShot {
        id: event
    }

    Reader {
        id: reader
        onDataReady:
        {
            var ndx = data['index']
            // handle defined props
            model.setProperty(ndx, "linked", data["linkedzones"] === undefined ? false : true)
            model.setProperty(ndx, "mute", data["volumedisplay"] === "Muted" ? true : false)

            // handle manual field changes
            if (data['filekey'] !== model.get(ndx).prevfilekey) {
                model.setProperty(ndx, 'prevfilekey', data['filekey'])
                trackKeyChanged(ndx, data['filekey'])
            }

            // tell consumers models are ready
            if (!d.modelReady) {
                d.initCtr++
                if (d.zoneCount === d.initCtr) {
                    d.modelReady = true
                    connectionReady(d.currZoneIndex)
                }
            }
        }
    }

    ReaderEx {
        id: dynReader
        currentHost: reader.currentHost
        onConnectionError: handleError
        onCommandError: handleError
    }

    Connections {
        target: reader
        onConnectionError: {
            handleError(msg, cmd)
            if (cmd.split('/')[2] === reader.currentHost)
                d.init("")
        }
        onCommandError: handleError(msg, cmd)
    }

    Playlists {
        id: playlists
        hostUrl: reader.hostUrl

        function play(plid, shuffleMode, zonendx) {
            run("Playlist/Files?Action=Play&Playlist=" + plid + (shuffleMode ? "&Shuffle=1" : ""), zonendx)
        }
        function add(plid, shuffleMode, zonendx) {
            run("Playlist/Files?Action=Play&PlayMode=Add&Playlist=" + plid, zonendx)
            if (shuffleMode)
                event.singleShot(500, function() { shuffle(zonendx) })
        }
    }

    Timer {
        id: pnTimer; repeat: true
        triggeredOnStart: true

        property int ctr: 0
        onTriggered: {
            ++ctr
            if (ctr === 3) {
                ctr = 0
                updateModel(statePlaying, false)
            }
            updateModel(statePlaying)
        }
    }
}
