import QtQuick 2.8
import QtQuick.XmlListModel 2.0

BaseXml {
    query: "/MPL/Item"
    mcwsFields: "Name,Artist,Album,Genre,Duration,Media Type,Media Sub Type"

    property string queryCmd: ''
    property string logicalJoin: 'and'
    property var constraintList
    property string constraintString: ''

    onConstraintListChanged: {
        constraintString = ''
        if (Object.keys(constraintList).length === 0 | queryCmd === '')
            source = ''
        else {
            // https://wiki.jriver.com/index.php/Search_Language#Comparison_Operators
            for(var k in constraintList) {
                if (constraintString === '')
                    constraintString = k + '=' + constraintList[k]
                else
                    constraintString += (' ' + logicalJoin + ' ' + k + '=' + constraintList[k])
            }
            console.log(queryCmd + constraintString)
            load(queryCmd + constraintString)
        }
    }

    onHostUrlChanged: source = ''

    function reload() {
        source = ''
        load(queryCmd + constraintString)
    }

    // Filekey (mcws: Key) will always be the first field returned
    XmlRole { name: "filekey";  query: "Field[1]/string()" }
}
