import QtQuick 2.12
import QtGraphicalEffects 1.15

Loader {
    id: root

    active: theme.useTheme

    property BackgroundTheme theme

    property Image source: theme.imageSource
    property bool lighter

    property alias hueBkgd      : hueComp
    property alias radialBkgd   : radComp
    property alias gradientBkgd : gradComp

    Component {
        id: hueComp
        BackgroundHue {
            // theme.useDefaultBkgd will set image to "defaultImage"
            source: theme.useDefaultBkgd ? theme.imageSource : root.source
            opacity: theme.useDefaultBkgd | theme.useCoverArt
                        ? theme.darkBkgd ? .5 : 1
                        : 1
            lightness: {
                if (lighter)
                    return (theme.useDefaultBkgd | theme.useCoverArt)
                        ? theme.darkBkgd ? -0.5 : 0.0
                        : -0.4
                else
                    return 0.0
            }
        }
    }

    Component {
        id: radComp
        RadialGradient {
            opacity: .75
            gradient: Gradient {
                GradientStop { position: 0.0; color: theme.color1 }
                GradientStop { position: 0.5; color: 'black' }
            }
        }
    }

    Component {
        id: gradComp
        Rectangle {
            opacity: .75
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: theme.color1 }
                GradientStop { position: 0.45; color: theme.color2 }
                GradientStop { position: 1.0; color: "black" }
            }
        }
    }

    sourceComponent: {
        if (theme.useDefaultBkgd | theme.useCoverArt)
            return hueBkgd
        else
            return (theme.radialTheme ? radialBkgd : gradientBkgd)
    }

}
