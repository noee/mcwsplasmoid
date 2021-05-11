import QtQuick 2.15

Behavior {
    id: root

    property Item fadeTarget: targetProperty.object
    property string fadeProperty: "opacity"
    property int fadeDuration: 500
    property var fadeValue: 0
    property string easingType: "Quad"
    property bool usePauseAnimation: true
    property int pauseAnimationDuration: Math.floor(fadeDuration/2)

    property alias exitAnimation: exitAni
    property alias enterAnimation: enterAni
    property alias pauseAnimation: pauseAni

    readonly property bool running: seq.running

    signal animationStart()
    signal animationPause()
    signal animationEnd()

    SequentialAnimation {
        id: seq

        ScriptAction { script: { root.animationStart() } }

        NumberAnimation {
            id: exitAni
            target: root.fadeTarget
            property: root.fadeProperty
            duration: root.fadeDuration
            to: root.fadeValue
            easing.type: root.easingType === "Linear"
                         ? Easing.Linear
                         : Easing["In"+root.easingType]
        }
        // actually change the controlled property between the 2 other animations
        PropertyAction {}

        ScriptAction {
            script: {
                if (usePauseAnimation && pauseAnimationDuration !== 0)
                    animationPause()
            }
        }

        PauseAnimation {
            id: pauseAni
            duration: usePauseAnimation ? pauseAnimationDuration : 0
        }

        NumberAnimation {
            id: enterAni
            target: root.fadeTarget
            property: root.fadeProperty
            duration: root.fadeDuration
            to: target[property]
            easing.type: root.easingType === "Linear"
                         ? Easing.Linear
                         : Easing["Out"+root.easingType]
        }

        ScriptAction { script: { root.animationEnd() } }
    }
}
