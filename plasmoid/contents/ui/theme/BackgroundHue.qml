import QtQuick 2.9
import QtGraphicalEffects 1.15

HueSaturation {
    saturation: 0.9
    layer.enabled: true
    cached: true
    layer.effect: GaussianBlur {
        cached: true
        radius: 128
        deviation: 12
        samples: 63
        transparentBorder: false
    }
}
