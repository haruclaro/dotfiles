pragma Singleton
import QtQuick
import Quickshell.Services.Notifications

// Serviço de notificações — substitui o dunst.
// Usa o NotificationServer nativo do Quickshell que implementa
// a Desktop Notifications Specification via D-Bus.
//
// As notificações são expostas via `trackedNotifications` para que
// o módulo NotificationToast (PanelWindow) as renderize como toasts.
QtObject {
    id: root

    // Quantos toasts aparecem ao mesmo tempo (o resto fica na fila)
    readonly property int maxVisible: 5

    // Tempo padrão de exibição (ms) — se o app não especificar timeout
    readonly property int defaultTimeout: 5000

    property NotificationServer server: NotificationServer {
        // Capacidades reportadas aos apps que enviam notificações
        actionsSupported: true
        bodySupported: true
        bodyMarkupSupported: true
        imageSupported: true
        persistenceSupported: false
        keepOnReload: true

        onNotification: notification => {
            notification.tracked = true;

            // Auto-expire: se o app não pediu persistência, expire após timeout
            if (notification.expireTimeout === -1) {
                notification.expireTimeout = root.defaultTimeout;
            }
        }
    }

    // Lista reativa de notificações ativas — usada pelo toast UI
    readonly property var tracked: server.trackedNotifications
}
