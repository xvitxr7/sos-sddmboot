import QtQuick
import QtQml
import QtQuick.Layouts
import QtQuick.Controls
import Qt5Compat.GraphicalEffects
import QtMultimedia

Item {
    id: sizeHelper

    anchors.fill: parent
    height: parent.height
    width: parent.width

    opacity: 0
    Behavior on opacity {
        NumberAnimation { duration: 2000 }
    }

    Component.onCompleted: sizeHelper.opacity = 1

    /* for some reason, this gif causes a terrible memory leak
       tried to move it to here, since sddm just straight-up crashes
       when it tries to loop the thing
       no progress though -- the gif might be corrupted
    AnimatedImage {
        id: background
        anchors.fill: parent
        source: Qt.resolvedUrl("../lockscreen.gif")
    }
    */

    Rectangle {
        id: formBackground
        anchors.fill: form
        anchors.centerIn: form
        color: "#FFFFFF"
        opacity: config.PartialBlur == "true" ? 0.3 : 1
        z: 1
    }

    LoginForm {
        id: form

        height: virtualKeyboard.state == "visible" ? parent.height - virtualKeyboard.implicitHeight : parent.height
        width: parent.width / 2.5
        anchors.horizontalCenter: config.FormPosition == "center" ? parent.horizontalCenter : undefined
        anchors.left: config.FormPosition == "left" ? parent.left : undefined
        anchors.right: config.FormPosition == "right" ? parent.right : undefined
        virtualKeyboardActive: virtualKeyboard.state == "visible" ? true : false
        z: 1
    }

    Button {
        id: vkb
        onClicked: virtualKeyboard.switchState()
        visible: virtualKeyboard.status == Loader.Ready && config.ForceHideVirtualKeyboardButton == "false"
        anchors.bottom: parent.bottom
        anchors.bottomMargin: implicitHeight
        anchors.horizontalCenter: form.horizontalCenter
        z: 1
        contentItem: Text {
            text: config.TranslateVirtualKeyboardButton || "Virtual Keyboard"
            color: parent.visualFocus ? palette.highlight : palette.text
            font.pointSize: root.font.pointSize * 0.8
        }
        background: Rectangle {
            id: vkbbg
            color: "transparent"
        }
    }

    Loader {
        id: virtualKeyboard
        source: "VirtualKeyboard.qml"
        state: "hidden"
        property bool keyboardActive: item ? item.active : false
        onKeyboardActiveChanged: keyboardActive ? state = "visible" : state = "hidden"
        width: parent.width
        z: 1
        function switchState() { state = state == "hidden" ? "visible" : "hidden" }
        states: [
        State {
            name: "visible"
            PropertyChanges {
                target: form
                systemButtonVisibility: false
                clockVisibility: false
            }
            PropertyChanges {
                target: virtualKeyboard
                y: root.height - virtualKeyboard.height
                opacity: 1
            }
        },
        State {
            name: "hidden"
            PropertyChanges {
                target: virtualKeyboard
                y: root.height - root.height/4
                opacity: 0
            }
        }
        ]
        transitions: [
        Transition {
            from: "hidden"
            to: "visible"
            SequentialAnimation {
                ScriptAction {
                    script: {
                        virtualKeyboard.item.activated = true;
                        Qt.inputMethod.show();
                    }
                }
                ParallelAnimation {
                    NumberAnimation {
                        target: virtualKeyboard
                        property: "y"
                        duration: 100
                        easing.type: Easing.OutQuad
                    }
                    OpacityAnimator {
                        target: virtualKeyboard
                        duration: 100
                        easing.type: Easing.OutQuad
                    }
                }
            }
        },
        Transition {
            from: "visible"
            to: "hidden"
            SequentialAnimation {
                ParallelAnimation {
                    NumberAnimation {
                        target: virtualKeyboard
                        property: "y"
                        duration: 100
                        easing.type: Easing.InQuad
                    }
                    OpacityAnimator {
                        target: virtualKeyboard
                        duration: 100
                        easing.type: Easing.InQuad
                    }
                }
                ScriptAction {
                    script: {
                        Qt.inputMethod.hide();
                    }
                }
            }
        }
        ]
    }

    AnimatedImage {
        id: backgroundImage

        height: parent.height
        width: config.HaveFormBackground == "true" && config.FormPosition != "center" && config.PartialBlur != "true" ? parent.width - formBackground.width : parent.width
        anchors.left: leftleft ||
        leftcenter ?
        formBackground.right : undefined

        anchors.right: rightright ||
        rightcenter ?
        formBackground.left : undefined

        horizontalAlignment: config.BackgroundImageAlignment == "left" ?
        Image.AlignLeft :
        config.BackgroundImageAlignment == "right" ?
        Image.AlignRight :
        config.BackgroundImageAlignment == "center" ?
        Image.AlignHCenter : undefined

        source: config.background || config.Background
        fillMode: config.ScaleImageCropped == "true" ? Image.PreserveAspectCrop : Image.PreserveAspectFit
        asynchronous: true
        cache: true
        clip: true
        mipmap: true
    }

    MouseArea {
        anchors.fill: backgroundImage
        onClicked: parent.forceActiveFocus()
    }
}
