import QtQuick 2.11
import QtQuick.Layouts 1.11
import QtQuick.Controls 2.4
import org.kde.kirigami 2.4 as Kirigami

import 'helpers/utils.js' as Utils
import 'controls'

BaseStreamSource {
    id: root

//    property int __lastCtr: -1
    logo: "http://somafm.com/linktous/150x50sfm2_1.gif"

    function load() {
        channels.clear()
        tracks.clear()
        Utils.jsonGet('http://api.somafm.com/channels.json', function(obj) {
            obj.channels.forEach(function(ch, ndx) {
                channels.append(ch)
                channels.set(ndx, {urls: {list: ch.playlists}})
            })
        })
    }
    function loadTracks(channel, cb) {
        tracks.clear()
        Utils.jsonGet('http://api.somafm.com/songs/%1.json'.arg(channel), function(obj) {
            obj.songs.forEach(function(ch) { tracks.append(ch) })
            cb(obj.songs)
        })
    }

    listDelegate: Component {
        RowLayout {
            width: parent.width

            AddButton {
                visible: false
                onClicked: {
                    var p = urls.list.find(function(i) {
                        return i.format === 'aac' && i.quality === 'highest'
                    })
                    if (!p) {
                        p = urls.list[0]
                    }
                    console.log('%1(%2/%3)'.arg(p.url)
                                .arg(p.format)
                                .arg(p.quality))
//                    loadTracks(id, function(trks) {
//                        console.log(Utils.stringifyObj(trks))
//                    })
//                    mcws.importPath(p.url)
                    mcws.playURL(zoneView.currentIndex, p.url)
                }
            }
            Image {
                source: image
                sourceSize.width: units.iconSizes.medium
                sourceSize.height: units.iconSizes.medium
            }
            Kirigami.Heading {
                text: '%1 (%2)\n - %3'.arg(title).arg(genre).arg(lastPlaying)
                level: 4
                Layout.fillWidth: true
                MouseAreaEx {
                    onClicked: {
                        streamView.currentIndex = index
                    }
                    tipText: description
                }
            }
        }
    }

//    poller.onTriggered: {
//        Utils.jsonGet('http://api.somafm.com/recent/%1.test.html'.arg(),
//                          function(val) {
//                              if (val !== root.__lastCtr) {
//                                  root.__lastCtrl = val
//                                  loadTracks(currentChannelID, function(tList) {
//                                      trackChanged(tList[0])
//                                  })
//                              }
//                          })
//    }

}
