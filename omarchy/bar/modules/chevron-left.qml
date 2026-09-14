import QtQuick

// Custom bar module: a left-pointing chevron (❮) that reveals/hides a group of
// stock bar widgets (bluetooth / monitor / "power" = battery). Hidden by
// default; click to toggle them; auto-hides again after `autoHideSeconds` (10).
//
// The chevron finds its neighbours by walking the QML scene up from its own
// root to the container holding the sibling ModuleSlots, then reveals/hides
// each slot's loaded widget (activeItem). A hidden ModuleSlot collapses out of
// the bar's Row layout exactly like any invisible child (the Spacer mechanism).
//
// Show/hide is animated — a subtle opacity fade combined with a gentle scale,
// driven by a timer tween using an InOutCubic (bezier-like) easing. Because the
// collapsing happens on stock sibling slots whose widths are hard-bound in the
// (read-only) bar internals, we cannot animate the widths themselves; we animate
// opacity + scale, which reads the same way without forking Omarchy-owned bar
// code.
//
// First-party panels (bluetooth/monitor/power) mount through deferred loaders,
// so they are NOT yet in the scene when this module's onCompleted fires. We poll
// briefly until all members of the group are available before applying the
// default-hide, so the timing cannot race the bar build.
Item {
  id: root

  property var bar
  property string moduleName
  property var settings

  readonly property bool vertical: bar ? bar.vertical : false
  readonly property int barSize: bar ? bar.barSize : 26
  readonly property int slot: 27

  // Stock widgets this chevron controls, matched against the moduleName of
  // sibling ModuleSlots in the same bar region.
  readonly property var groupIds: ["omarchy.bluetooth", "omarchy.monitor", "omarchy.power"]
  readonly property int autoHideSeconds: settings && settings.autoHideSeconds !== undefined
    ? Number(settings.autoHideSeconds) : 10
  property bool open: false

  // Tune the animation here.
  readonly property int animDurationMs: 220
  readonly property real animMinScale: 0.86

  // ---- tween state -------------------------------------------------------
  // Slots currently being animated (so we can pause/swallow a re-entrant
  // toggle mid-flight) and the direction: 1 = opening, -1 = closing.
  property var animSlots: []
  property int animDirection: 0
  property real animElapsed: -1

  implicitWidth: root.vertical ? root.barSize : root.slot
  implicitHeight: root.vertical ? root.slot : root.barSize

  // InOutCubic (a smooth bezier-like ease): a.k.a. smoothstep.
  function ease(t) {
    t = t < 0 ? 0 : (t > 1 ? 1 : t)
    return t * t * (3 - 2 * t)
  }

  // Every sibling ModuleSlot in this bar surface whose moduleName is one of
  // groupIds. Climb the parent chain until we reach the container that hosts
  // this ModuleSlot and its neighbours.
  function groupSlots() {
    var out = []
    var node = root
    var guard = 0
    while (node && guard++ < 16) {
      var kids = null
      try { kids = node.children } catch (e) { kids = null }
      var n = 0
      if (kids && (Array.isArray(kids) || typeof kids.length === "number")) {
        try { n = kids.length } catch (e) { n = -1 }
      }
      if (n > 0 && kids) {
        var foundHere = false
        for (var i = 0; i < n; i++) {
          var c = null
          try { c = kids[i] } catch (e) {}
          if (!c) continue
          var name = ""
          try { name = typeof c.moduleName !== "undefined" ? String(c.moduleName) : "" } catch (e) {}
          if (name && root.groupIds.indexOf(name) !== -1 && out.indexOf(c) === -1) {
            out.push(c)
            foundHere = true
          }
        }
        if (foundHere) return out
      }
      node = node.parent
      if (!node) break
    }
    return out
  }

  // Grab the widget a slot is actually painting (its activeItem), with guards
  // for whichever loader/branch produced it.
  function slotItem(slot) {
    if (!slot) return null
    try {
      var it = typeof slot.activeItem !== "undefined" ? slot.activeItem : null
      return it ? it : null
    } catch (e) { return null }
  }

  // Write opacity/scale on an item's content, tolerating items without scale.
  function applyState(item, opacity, scale) {
    try { item.opacity = opacity } catch (e) {}
    if ("scale" in item) {
      try { item.scale = scale } catch (e) {}
    }
  }

  function setGroupVisible(show) {
    var slots = root.groupSlots()
    root.open = show
    root.animSlots = slots
    root.animDirection = show ? 1 : -1
    root.animElapsed = 0
    for (var i = 0; i < slots.length; i++) {
      var item = root.slotItem(slots[i])
      if (!item) continue
      // Reserve layout space immediately; the slot is hidden on close only
      // once the fade has finished (in sweepTween).
      try { slots[i].visible = true } catch (e) {}
      // Seed the start of the arc so a quick re-toggle stays consistent.
      if (show) root.applyState(item, 0.0, root.animMinScale)
      else root.applyState(item, 1.0, 1.0)
    }
    if (!tweenTimer.running) tweenTimer.start()
  }

  function close() {
    root.setGroupVisible(false)
  }

  Timer {
    id: tweenTimer
    interval: 15
    repeat: true
    running: false
    onTriggered: root.sweepTween()
  }

  function sweepTween() {
    if (root.animElapsed < 0) { tweenTimer.running = false; return }

    root.animElapsed = root.animElapsed + tweenTimer.interval
    var t = root.ease(root.animElapsed / root.animDurationMs)

    if (root.animDirection > 0) {
      for (var i = 0; i < root.animSlots.length; i++) {
        var item = root.slotItem(root.animSlots[i])
        if (!item) continue
        var scale = root.animMinScale + (1 - root.animMinScale) * t
        root.applyState(item, t, scale)
      }
    } else {
      for (var j = 0; j < root.animSlots.length; j++) {
        var it2 = root.slotItem(root.animSlots[j])
        if (!it2) continue
        var s2 = 1 - (1 - root.animMinScale) * t
        root.applyState(it2, 1 - t, s2)
      }
    }

    // Finished: land the final state and (for a close) collapse the slots.
    if (root.animElapsed >= root.animDurationMs) {
      tweenTimer.running = false
      root.animElapsed = -1
      if (root.animDirection < 0) {
        // Fade finished: now collapse the slots out of the Row layout and
        // restore their resting state for the next open.
        for (var m = 0; m < root.animSlots.length; m++) {
          var slot = root.animSlots[m]
          var gi = root.slotItem(slot)
          try { slot.visible = false } catch (e) {}
          if (gi) root.applyState(gi, 1.0, 1.0)
        }
      } else {
        // Opening finished: make sure the content is fully opaque.
        for (var n = 0; n < root.animSlots.length; n++) {
          var fn = root.slotItem(root.animSlots[n])
          if (fn) root.applyState(fn, 1.0, 1.0)
        }
      }
      root.animSlots = []
    }
  }

  // Poll for the group so the default-hide can't race the deferred panel mount.
  property int probeTicks: 0
  Timer {
    id: probeTimer
    interval: 250
    repeat: true
    running: true
    onTriggered: {
      root.probeTicks = root.probeTicks + 1
      var slots = root.groupSlots()
      if (slots.length === root.groupIds.length) {
        probeTimer.running = false
        root.setGroupVisible(false)
      } else if (root.probeTicks >= 20) {
        probeTimer.running = false
      }
    }
  }
  Component.onCompleted: { probeTimer.start() }

  onOpenChanged: {
    if (root.open) {
      if (autoCloseTimer.running) autoCloseTimer.restart()
      else autoCloseTimer.start()
    } else {
      autoCloseTimer.stop()
    }
  }

  Timer {
    id: autoCloseTimer
    interval: root.autoHideSeconds * 1000
    onTriggered: root.close()
  }

  MouseArea {
    anchors.fill: parent
    acceptedButtons: Qt.LeftButton
    cursorShape: Qt.PointingHandCursor
    onClicked: root.setGroupVisible(!root.open)
  }

  Text {
    anchors.centerIn: parent
    text: "\uf053"
    color: bar ? bar.foreground : "white"
    font.family: bar ? bar.fontFamily : "monospace"
    font.pixelSize: 13
  }
}