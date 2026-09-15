import QtQuick; import Quickshell; import './services' as Services; ShellWindow { width: 100; height: 100; Component.onCompleted: console.log(Services.Network.wifiEnabled) }
