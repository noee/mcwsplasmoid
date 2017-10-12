import QtQuick 2.8
import "../code/utils.js" as Utils

Item {
    readonly property bool isConnected: (d.zoneCount > 0) && d.modelReady
    readonly property var model: pnModel
    readonly property alias timer: pnTimer
    readonly property alias hostUrl: reader.hostUrl

    readonly property var zoneModel: {
        var list = []
        for(var i=0; i<pnModel.count; ++i)
            list.push({ "zoneid": pnModel.get(i).zoneid, "zonename": pnModel.get(i).zonename })
        return list
    }

    // private stuff
    QtObject{
        id: d
        property int zoneCount: 0
        property bool modelReady: false
        property int initCtr: 0

        function init(host) {
            pnTimer.stop()
            pnModel.clear()
            zoneCount = 0
            initCtr = 0
            modelReady = false
            reader.currentHost = host
        }

        function loadRepeatMode(zonendx) {
            dynReader.runQuery("Playback/Repeat?ZoneType=Index&Zone=" + zonendx
                 , function(data)
                 {
                     pnModel.set(zonendx, {"repeat": data["mode"]})
                 })
        }
    }

    signal connectionReady()

    function run(cmd, zonendx) {
        if (zonendx === undefined)
            reader.exec(cmd)
        else {
            var delim = cmd.indexOf('?') === -1 ? '?' : '&'
            reader.exec("%1%2Zone=%3".arg(cmd).arg(delim).arg(pnModel.get(zonendx).zoneid))
            event.singleShot(300, function(){ updateModelItem(zonendx) })
        }
    }

    function zonesByStatus(status) {
        var list = []
        for(var i=0; i<pnModel.count; ++i) {
            if (pnModel.get(i).status === status)
                list.push(i)
        }
        return list
    }
    function imageUrl(filekey, size) {
        var imgsize = (size === undefined | size === null) ? 'medium' : size
        return hostUrl + "File/GetImage?Thumbnailsize=" + imgsize + "&File=" + filekey
    }

    function updateModel(status, include) {
        var inclStatus = (include === undefined || include === null) ? true : include

        if (inclStatus) {
            for (var z=0; z<pnModel.count; ++z) {
                if (pnModel.get(z).status === status) {
                    updateModelItem(z)
                }
            }
        }
        else {
            for (var z=0; z<pnModel.count; ++z) {
                if (pnModel.get(z).status !== status) {
                    updateModelItem(z)
                }
            }
        }
    }
    function updateModelItem(ndx) {
        // reset some transient fields
        pnModel.setProperty(ndx, "linkedzones", "")
        // pass model/ndx so the reader will update it directly
        reader.runQuery("Playback/Info?zone=" + pnModel.get(ndx).zoneid, pnModel, ndx)
    }
    function connect(host) {
        // reset everything
        d.init(host)
        // Set callback to get zones, reset when done to prepare reader for pn poller
        reader.callback = function(data)
        {
            // seeding model entries
            d.zoneCount = data["numberzones"]
            for(var i = 0; i<d.zoneCount; ++i) {
                // setup defined props in the model for each zone
                pnModel.append({"zoneid": data["zoneid"+i]
                                   , "zonename": data["zonename"+i]
                                   , "status": "Stopped"
                                   , "linked": false
                                   , "mute": false})
                d.loadRepeatMode(i)
            }
            updateModel("Playing", false)
            pnTimer.start()
            reader.callback = null
        }
        reader.runQuery("Playback/Zones")
    }

    function playPlaylist(plid, zonendx) {
        run("Playlist/Files?Shuffle=1&Action=Play&Playlist=" + plid, zonendx)
    }
    function addPlaylist(plid, zonendx) {
        run("Playlist/Files?&Action=Play&PlayMode=Add&Playlist=" + plid, zonendx)
        event.singleShot(1000, function() { shuffle(zonendx) })
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
        return pnModel.get(zonendx).mute
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
        return zonendx >= 0 ? pnModel.get(zonendx).repeat : ""
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
        var pos = +pnModel.get(zonendx).playingnowposition + 1
        run("Playback/PlaybyKey?Key=%1&Location=%2".arg(filekey).arg(pos), zonendx)
        event.singleShot(500, function() { playTrack(pos, zonendx) })
    }

    function queueAlbum(filekey, next, zonendx) {
        run("Playback/PlaybyKey?Key=%1&Album=1&Location=%2".arg(filekey).arg(next ? "Next" : "End"), zonendx)
    }
    function playAlbum(filekey, zonendx) {
        run("Playback/PlaybyKey?Album=1&Key=" + filekey, zonendx)
    }
    function searchAndPlayNow(srch, shuffle, zonendx) {
        run("Files/Search?Action=Play&query=" + srch + (shuffle ? "&Shuffle=1" : ""), zonendx)
    }
    function searchAndAdd(srch, next, zonendx) {
        run("Files/Search?Action=Play&query=%1&PlayMode=%2".arg(srch).arg(next ? "NextToPlay" : "Add"), zonendx)
    }

    function handleError(msg, cmd) {
        console.log("MCWS Error: " + msg + ": " + cmd)
    }

    SingleShot {
        id: event
    }

    Reader {
        id: reader
        onDataReady: {
            // handle defined props
            pnModel.setProperty(data["index"], "linked", data["linkedzones"] === undefined ? false : true)
            pnModel.setProperty(data["index"], "mute", data["volumedisplay"] === "Muted" ? true : false)

            // tell consumers models are ready
            if (!d.modelReady) {
                d.initCtr++
                if (d.zoneCount === d.initCtr) {
                    d.modelReady = true
                    connectionReady()
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

    ListModel {
        id: pnModel
    }

    Timer {
        id: pnTimer; repeat: true
        triggeredOnStart: true

        property int ctr: 0
        onTriggered: {
            ++ctr
            if (ctr === 5) {
                ctr = 0
                updateModel("Playing", false)
            }
            updateModel("Playing")
        }

    }

}
