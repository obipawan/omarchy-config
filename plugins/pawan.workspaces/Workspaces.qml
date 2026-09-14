import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland
import qs.Commons
import qs.Ui

BarWidget {
  id: root
  moduleName: "omarchy.workspaces"

  function workspaceById(id) {
    var values = Hyprland.workspaces.values
    for (var i = 0; i < values.length; i++) {
      if (values[i].id === id) return values[i]
    }

    return null
  }

  function workspaceIds() {
    var ids = [1, 2, 3, 4, 5]
    var values = Hyprland.workspaces.values

    for (var i = 0; i < values.length; i++) {
      var id = values[i].id
      if (id > 0 && id <= 10 && ids.indexOf(id) === -1) ids.push(id)
    }

    ids.sort(function(left, right) { return left - right })
    return ids
  }

  function focusWorkspace(id) {
    if (!root.bar) return
    root.bar.run("hyprctl dispatch " + Util.shellQuote("hl.dsp.focus({ workspace = \"" + id + "\" })"))
  }

  // Width of the rounded-rectangle indicator.
  readonly property real squircleSize: Style.spaceReal(13)
  // Short height so it reads as a rounded bar, not a square.
  readonly property real indicatorHeight: Style.spaceReal(8)
  // Focused indicator is 2 unit(s) larger each dimension.
  readonly property real focusSize: Style.spaceReal(2)
  // Height of the whole workspace container (the outlined box), independent of bar thickness.
  readonly property real itemHeight: Math.min(root.barSize, Style.spaceReal(18))
  // Radius: theme rounding, but never exceeding the shape's half-height.
  readonly property real squircleRadius: Math.min(Math.max(Style.cornerRadius + 1, 2), root.indicatorHeight / 2 + 1)

  readonly property real trailingGap: root.vertical ? 0 : Style.spaceReal(1.5)

  // Outline that surrounds the whole indicator container.
  readonly property real containerMargin: Style.spaceReal(2)
  // Extra air inside the container between the outline and the first/last indicator.
  readonly property real containerPadH: Style.spaceReal(6)
  readonly property real containerRadius: Math.max(Style.cornerRadius + 2, 14)

  // Rounded-corner outline around the container, drawn behind the indicators.
  Rectangle {
    anchors.fill: parent
    anchors.leftMargin: root.containerMargin
    anchors.rightMargin: root.containerMargin
    anchors.topMargin: 0
    anchors.bottomMargin: 0
    radius: root.containerRadius
    color: root.bar.transparent ? "transparent" : root.bar.background
    border.width: 0

    Behavior on color {
      enabled: !root.bar || root.bar.foregroundAnimationEnabled
      ColorAnimation { duration: 160 }
    }

    Behavior on border.color {
      enabled: !root.bar || root.bar.foregroundAnimationEnabled
      ColorAnimation { duration: 160 }
    }
  }

  implicitWidth: grid.implicitWidth + (root.vertical ? 0 : root.containerPadH * 2) + trailingGap
  implicitHeight: grid.implicitHeight + (root.vertical ? root.containerPadH * 2 : 0)

  GridLayout {
    id: grid
    anchors.fill: parent
    anchors.leftMargin: root.vertical ? 0 : root.containerPadH
    anchors.rightMargin: root.vertical ? 0 : root.containerPadH + trailingGap
    anchors.topMargin: root.vertical ? root.containerPadH : 0
    anchors.bottomMargin: root.vertical ? root.containerPadH : 0
    columns: root.vertical ? 1 : root.workspaceIds().length
    columnSpacing: root.vertical ? 0 : Style.space(1)
    rowSpacing: root.vertical ? Style.space(2) : 0

    Repeater {
      model: root.workspaceIds()

      WidgetButton {
        required property int modelData

        readonly property var workspace: root.workspaceById(modelData)
        readonly property bool occupied: workspace !== null && workspace.toplevels.values.length > 0
        readonly property bool focused: Hyprland.focusedWorkspace !== null && Hyprland.focusedWorkspace.id === modelData

        bar: root.bar
        labelVisible: false
        hasVisualContent: true
        opacity: occupied || focused ? 1 : 0.5
        horizontalMargin: 6
        verticalPadding: 6
        fixedWidth: root.vertical ? root.itemHeight : Style.space(20)
        fixedHeight: root.vertical ? Style.space(20) : root.itemHeight
        onPressed: function() { root.focusWorkspace(modelData) }

        // Solid rounded rectangle for the focused workspace.
        Rectangle {
          visible: focused
          anchors.centerIn: parent
          width: root.squircleSize + root.focusSize
          height: root.indicatorHeight + root.focusSize
          radius: root.squircleRadius
          color: root.bar.barForeground

          Behavior on color {
            enabled: !root.bar || root.bar.foregroundAnimationEnabled
            ColorAnimation { duration: 160 }
          }
        }

        // Outline rounded rectangle for every other workspace.
        Rectangle {
          visible: !focused
          anchors.centerIn: parent
          width: root.squircleSize
          height: root.indicatorHeight
          radius: root.squircleRadius
          color: "transparent"
          border.width: 1
          border.color: root.bar.barForeground

          Behavior on border.color {
            enabled: !root.bar || root.bar.foregroundAnimationEnabled
            ColorAnimation { duration: 160 }
          }
        }
      }
    }
  }
}