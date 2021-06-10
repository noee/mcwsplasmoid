import QtQuick 2.15
import QtQuick.Layouts 1.3
import QtQuick.Controls 2.15
import org.kde.kirigami 2.12 as Kirigami

ColumnLayout {

    // arr of { host, friendlyname, accesskey, zones, enabled }
    component McwsHostModel: BaseListModel {

        property bool autoLoad: true
        property bool loadEnabledOnly: true

        // Configured mcws host string
        property string configString: ''
        onConfigStringChanged: if (autoLoad) load()

        signal loadStart()
        signal loadFinish(int count)
        signal loadError(string msg)

        function load() {
            loadStart()
            clear()

            try {
                var arr = JSON.parse(configString)
                arr.forEach(item => {
                    if (!loadEnabledOnly | item.enabled) {
                        // Because friendlyname is used as displayText,
                        // make sure it's present, default to host name
                        item.friendlyname = item.friendlyname ?? item.host.split(':')[0]
                        append(item)
                    }
                })
            }
            catch (err) {
                var s = err.message + '\n' + configString
                console.warn(s)
                loadError('Host config parse error: ' + s)
            }

            loadFinish(count)
        }
    }

    property bool includeZones: true
    property bool allowMove: true
    property alias hostConfig: lm.outputStr

    property var _alive: ({})

    ConfigListModel {
        id: lm
        configKey: 'hostConfig'
        objectDef: ['host', 'accesskey', 'friendlyname', 'zones', 'enabled']
    }

    Reader {
        id: reader
        onCommandError: hostInfo.text = 'not found'
        onConnectionError: hostInfo.text = 'not found'
    }

    function getServerInfo(host) {
        if (host.length === 0) return

        reader.currentHost = host.indexOf(':') === -1
                ? host + ':' + plasmoid.configuration.defaultPort
                : host
        zoneList.clear()
        hostInfo.text = 'searching...'
        reader.loadObject('Alive', obj => {
            // check zone str for included zone
            var includeZone = (ndx) => {
                                  if (configedZone) {
                                      let arr = configedZone.zones.split(',')
                                      if (arr[0] === '*')
                                        return true
                                      else if (arr.includes(ndx.toString()))
                                        return true
                                      else
                                        return false
                                  }
                                  // not config'd, default to true
                                  return true
                              }

            _alive = obj
            hostInfo.text = '%1(%2): %3, v%4'
                              .arg(obj.friendlyname)
                              .arg(obj.accesskey)
                              .arg(obj.platform)
                              .arg(obj.programversion)

            // get host currently config'd host, if there
            let configedZone = lm.items.find(item => item.host === reader.currentHost)

            reader.loadObject('Playback/Zones', zones => {
                for (var i=0, len=zones.numberzones; i<len; ++i) {
                      zoneList.append({key: zones['zoneid' + i].toString()
                                      , value: zones['zonename'+i]
                                      , include: includeZone(i)})
                    }
                })
        })
    }

    Kirigami.InlineMessage {
        id: zoneMsg
        type: Kirigami.MessageType.Error
        showCloseButton: true
        text: 'You must select at least one Zone to add a host'
    }

    // Lookup and Alive display
    RowLayout {
        Kirigami.SearchField {
            id: mcwshost
            placeholderText: 'host:port'
            autoAccept: false
            onAccepted: searchBtn.clicked()
            onTextChanged: {
                zoneMsg.visible = false
                if (text.length === 0) {
                    zoneList.clear()
                    hostInfo.text = ''
                }
            }
        }
        ToolButton {
            id: searchBtn
            icon.name: 'search'
            onClicked: getServerInfo(mcwshost.text)
        }
        Label {
            id: hostInfo
        }
    }

    // Zones for the current host
    GroupSeparator {
        text: includeZones ? 'Select zones to include' : 'Playback Zones'
        opacity: zoneList.count > 0

        ToolButton {
            icon.name: 'checkbox'

            ToolTip {
                text: 'Update Config for ' + reader.currentHost
            }

            onClicked: {
                let zonestr = ''
                if (includeZones) {
                    // at least one zone must be selected
                    if (!zoneList.contains(i => i.include)) {
                        zoneMsg.visible = true
                        return
                    }

                    let cnt = 0
                    zoneList.forEach((item, ndx) => {
                                     if (item.include) {
                                         zonestr += ',%1'.arg(ndx)
                                         ++cnt
                                     }
                                 })

                    zonestr = cnt === zoneList.count
                                ? '*'
                                : zonestr.slice(1)
                }

                // if host is config'd, update it, otherwise add it
                let ndx = lm.items.findIndex(item => item.host === reader.currentHost)
                if (ndx === -1)
                    lm.items.append({ host: reader.currentHost
                                    , friendlyname: _alive.friendlyname
                                    , accesskey: _alive.accesskey
                                    , zones: zonestr
                                    , enabled: true })
                else
                    lm.items.set(ndx, {friendlyname: _alive.friendlyname
                                     , accesskey: _alive.accesskey
                                     , zones: zonestr})

                lm.items.save()
            }
        }
    }

    ListView {
        id: zoneView
        model: BaseListModel { id: zoneList }
        Layout.minimumHeight: parent.height * .35
        Layout.fillWidth: true
        clip: true
        delegate: RowLayout {
            width: Math.round(zoneView.width*.5)
            Kirigami.BasicListItem {
                icon: 'media-default-album'
                checkable: includeZones
                checked: include
                text: '%1 (id: %2)'.arg(value).arg(key)
                separatorVisible: false
                onClicked: model.include = checked
            }
        }
    }

    // Current Config setup
    GroupSeparator { text: 'MCWS Host Config' }

    Component {
        id: itemDelegate

        Kirigami.SwipeListItem {
            id: swipelistItem

            onClicked: {
                lvHosts.currentIndex = index
                mcwshost.text = host
                getServerInfo(host)
            }

            RowLayout {

                Rectangle {
                    Layout.fillHeight: true
                    opacity: model.enabled ? 1 : 0
                    width: 3
                    color: Kirigami.Theme.highlightColor
                }

                //FIXME: If not used within DelegateRecycler, item goes on top of the first item when clicked
                Kirigami.ListItemDragHandle {
                    implicitWidth: Kirigami.Units.iconSizes.medium
                    listItem: swipelistItem
                    listView: lvHosts
                    onMoveRequested: {
                        lm.items.move(oldIndex, newIndex, 1)
                    }
                }

                ColumnLayout {
                    spacing: 0
                    Label {
                        text: host + (includeZones ? ', Zones: [%1]'.arg(zones) : '')
                        Layout.fillWidth: true
                    }
                    Label {
                        text: '%1, accesskey: %2'.arg(friendlyname).arg(accesskey)
                        font: Kirigami.Theme.smallFont
                        color: Kirigami.Theme.disabledTextColor
                        Layout.fillWidth: true
                    }
                }

                CheckBox {
                    text: 'Include'
                    checked: model ? model.enabled : false
                    onClicked: lm.setEnabled(index, checked)
                }

            }

            actions: [
                Kirigami.Action {
                    text: 'Remove item'
                    iconName: 'delete'
                    onTriggered: lm.items.remove(index)
                }
            ]
        }
    }

    ListView {
        id: lvHosts
        model: lm.items
        Layout.fillHeight: true
        Layout.fillWidth: true
        Layout.minimumHeight: parent.height * .35
        clip: true
        spacing: 0

        moveDisplaced: Transition {
            YAnimator {
                duration: Kirigami.Units.longDuration
                easing.type: Easing.InOutQuad
            }
        }

        delegate: Kirigami.DelegateRecycler {
            width: lvHosts.width
            sourceComponent: itemDelegate
        }
    }
}
