import QtQuick
import Quickshell
import "./services" as Services
Item {
    Component.onCompleted: {
        Services.HyprConfig.saved.connect(() => {
            console.log("Saved OK!")
            Qt.quit()
        })
        Services.HyprConfig.saveFailed.connect((reason) => {
            console.log("Save FAILED: " + reason)
            Qt.quit()
        })
        Services.HyprConfig.save()
        console.log("Wait for save...")
    }
}
