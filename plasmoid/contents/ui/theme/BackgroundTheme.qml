import QtQuick 2.12
import '../controls'

/* Background color theming
*   If on, checks for "Default" option
*   and uses the default image.
*   Cover art option use per track cover art
*   theme list (defined in config)
*/
Item {

    property bool useTheme:       false
    property bool radialTheme:    false
    property bool useCoverArt:    useTheme && currentThemeName === 'Cover Art'
    property bool useDefaultBkgd: useTheme && currentThemeName === 'Default'
    property bool darkBkgd:       false
    property string currentThemeName
    property string themeConfig

    onThemeConfigChanged: d.load()

    onCurrentThemeNameChanged:  d.setColors()
    onDarkBkgdChanged:          d.setColors()

    property alias imageSource: img
    readonly property alias color1: d.color1
    readonly property alias color2: d.color2

    QtObject {
        id: d

        // {name, c1, c2}
        property var list: []
        property string color1
        property string color2

        function setColors() {
            let t = list.find(t => t.name === currentThemeName)
            if (t) {
                if (darkBkgd) {
                     color1 = Qt.darker(t.c1)
                     color2 = Qt.darker(t.c2)
                } else {
                     color1 = Qt.lighter(t.c1)
                     color2 = Qt.lighter(t.c2)
                }
            }
        }

        function load() {
            list.length = 0
            try {
                JSON.parse(themeConfig)
                    .forEach(t => d.list.push(t))
                d.setColors()
            }
            catch (err) {
                console.log('Unable to load theme config: ' + err)
            }
        }
    }

    TrackImage {
        id: img
        visible: false
        animateLoad: false
        thumbnail: true

        states: [
            State {
                name: "default"; when: useDefaultBkgd
                PropertyChanges { target: img; sourceKey: '-1' }
            }
        ]
    }

}
