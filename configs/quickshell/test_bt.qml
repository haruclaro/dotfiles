import QtQuick
import Quickshell
import Quickshell.Bluetooth

ShellWindow {
    width: 200; height: 200
    Component.onCompleted: {
        console.log("Enabled: ", Bluetooth.defaultAdapter?.enabled)
        for (const dev of Bluetooth.devices.values) {
            console.log(dev.name, dev.connected, dev.icon, dev.state)
        }
        Quickshell.exit(0)
    }
}
