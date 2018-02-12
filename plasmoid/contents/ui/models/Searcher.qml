import QtQuick 2.8

Item {
    readonly property alias items: tm.items
    property alias comms: tm.comms
    property bool autoShuffle: false

    property string logicalJoin: 'and'
    property var constraintList
    property string constraintString: ''

    // https://wiki.jriver.com/index.php/Search_Language#Comparison_Operators
    onConstraintListChanged: {
        constraintString = ''
        if (Object.keys(constraintList).length === 0)
            items.clear()
        else {
            var constraints = Object.assign({}, { name: ''
                                                ,artist: ''
                                                ,album: ''
                                                ,genre: '' }, constraintList)
            var list = []
            for(var k in constraints) {
                if (constraints[k] !== '')
                    list.push('[%1]=%2'.arg(k).arg(constraints[k]))
            }
            constraintString = list.join(' %1 '.arg(logicalJoin))
            tm.load(constraintString)
        }
    }

    signal searchBegin()
    signal searchDone(var count)

    TrackModel {
        id: tm
        queryCmd: 'Files/Search'
                  + (autoShuffle ? '?Shuffle=1&' : '?')
                  + 'query='

        Component.onCompleted: {
            tm.items.aboutToLoad.connect(searchBegin)
            tm.items.resultsReady.connect(searchDone)
        }
    }
}
