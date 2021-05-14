import QtQuick 2.12

Loader {
    id: root

    property Image source

    Component {
        id: imgComp
        BackgroundHue {
            source: root.source
            opacity: useDefaultBkgd | useCoverArt
                        ? plasmoid.configuration.themeDark ? .5 : 1
                        : 1
        }
    }

    sourceComponent: {
        if (useCoverArt)
            return imgComp

        if (useDefaultBkgd)
            return hueComp

        if (useTheme)
            return (radialTheme ? radComp : gradComp)

        return null
    }
}
