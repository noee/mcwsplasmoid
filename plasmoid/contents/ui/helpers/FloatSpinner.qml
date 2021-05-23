import QtQuick 2.9
import QtQuick.Controls 2.4

SpinBox {
    id: control
    from: 0
    to: 100 * 100
    stepSize: 10

    property int decimals: 2
    property real realValue: value / 100

    validator: DoubleValidator {
        bottom: Math.min(control.from, control.to)
        top:  Math.max(control.from, control.to)
    }

    textFromValue: function(value) {
        return value/100 + ' sec'
    }

    valueFromText: function(text, locale) {
        return parseFloat(text) * 100
//        return Number.fromLocaleString(locale, text.split(" ")[0]) * 100
    }
}
