import QtQuick 2.9
import QtGraphicalEffects 1.15

HueSaturation {
    saturation: 1.0
    layer.enabled: true
    opacity: .5
    layer.effect: GaussianBlur {
        radius: 128
        deviation: 12
        samples: 63
        transparentBorder: false
    }
}
