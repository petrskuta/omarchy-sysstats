import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Commons as Commons
import qs.Ui

// Minimal system readout: CPU, RAM, GPU, network and battery power.
// Data comes from stats.sh as one JSON line every two seconds.
// Clicking opens (or focuses) btop.
BarWidget {
  id: root
  moduleName: "petrskuta.sysstats"

  property var stats: null

  readonly property color foreground: bar ? bar.barForeground : Commons.Color.foreground
  readonly property bool charging: stats !== null && (stats.battery === "Charging" || stats.battery === "Full")

  readonly property var items: {
    if (!stats) return []
    var list = [
      { icon: 0xF4BC, value: stats.cpu + "%" },
      { icon: 0xEFC5, value: stats.ram + "%" }
    ]
    if (stats.gpu >= 0) list.push({ icon: 0xF08AE, value: stats.gpu + "%" })
    list.push({ icon: 0xF04E1, value: "↓" + rate(stats.down) + " ↑" + rate(stats.up) })
    if (stats.powerUw >= 0)
      list.push({ icon: charging ? 0xF06A5 : 0xF140B, value: (stats.powerUw / 1e6).toFixed(1) + "W" })
    return list
  }

  visible: stats !== null
  implicitWidth: visible ? content.implicitWidth + Style.space(12) : 0
  implicitHeight: barSize

  // Always K or M, never B: under 1K shows one decimal, such as 0.3K.
  function rate(bytes) {
    var kb = bytes / 1024
    if (kb >= 1023.5) return (kb / 1024).toFixed(1) + "M"
    if (kb >= 1) return Math.round(kb) + "K"
    return bytes > 0 ? kb.toFixed(1) + "K" : "0K"
  }

  function apply(line) {
    if (line.length > 1024) return
    var data
    try { data = JSON.parse(line) } catch (e) { return }
    if (!data || typeof data.cpu !== "number") return
    root.stats = data
  }

  function tooltip() {
    if (!stats) return ""
    var lines = [
      "CPU " + stats.cpu + "%",
      "RAM " + (stats.ramMb / 1024).toFixed(1) + " / " + (stats.ramTotalMb / 1024).toFixed(1) + " GB",
    ]
    if (stats.gpu >= 0) lines.push("GPU " + stats.gpu + "% busy")
    lines.push("Down " + rate(stats.down) + "/s, up " + rate(stats.up) + "/s")
    if (stats.powerUw >= 0)
      lines.push((charging ? "Charging at " : "Drawing ") + (stats.powerUw / 1e6).toFixed(1) + " W")
    return lines.join("\n")
  }

  Process {
    id: watcher
    running: true
    command: [Qt.resolvedUrl("stats.sh").toString().replace("file://", ""), "2"]
    stdout: SplitParser {
      onRead: function(line) { root.apply(line) }
    }
  }

  // The watcher only ends if the script dies; try again later.
  Timer {
    interval: 5000
    running: !watcher.running
    repeat: true
    onTriggered: watcher.running = true
  }

  Row {
    id: content
    anchors.centerIn: parent
    spacing: Style.space(10)

    Repeater {
      model: root.items

      Row {
        required property var modelData
        anchors.verticalCenter: parent.verticalCenter
        spacing: Style.space(4)

        Text {
          anchors.verticalCenter: parent.verticalCenter
          textFormat: Text.PlainText
          text: String.fromCodePoint(modelData.icon)
          color: root.foreground
          font.family: bar ? bar.fontFamily : Style.font.family
          font.pixelSize: Style.bar.iconFont
        }

        Text {
          anchors.verticalCenter: parent.verticalCenter
          textFormat: Text.PlainText
          text: modelData.value
          color: root.foreground
          font.family: bar ? bar.fontFamily : Style.font.family
          font.pixelSize: Style.font.body
          font.features: { "tnum": 1 }
        }
      }
    }
  }

  MouseArea {
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onClicked: if (root.bar) root.bar.run("omarchy-launch-or-focus-tui btop")
    onEntered: if (root.bar) root.bar.showTooltip(root, root.tooltip())
    onExited: if (root.bar) root.bar.hideTooltip(root)
  }
}
