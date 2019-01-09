import QtQuick 2.9
import QtQuick.Controls 2.4

SpinBox {
    id: control
    from: 0
    to: 100 * 100
    stepSize: 10
//    implicitHeight: parent.height * .75

    property int decimals: 2
//            property real realValue: value / 100

//    background: Rectangle {
//        implicitWidth: 50
//                implicitHeight: spinbox.height
//        color: theme.backgroundColor
//    }

    validator: DoubleValidator {
        bottom: Math.min(control.from, control.to)
        top:  Math.max(control.from, control.to)
    }

    textFromValue: function(value, locale) {
        return Number(value / 100).toLocaleString(locale, 'f', control.decimals)
    }

    valueFromText: function(text, locale) {
        return Number.fromLocaleString(locale, text) * 100
    }
}
