#include "powersupply.h"

#include <QDir>
#include <QFile>
#include <QTemporaryDir>

int main()
{
    QTemporaryDir tree;
    if (!tree.isValid())
        return 1;
    auto write = [&](const QString &device, const QString &name, const QByteArray &value) {
        const QDir dir(tree.filePath(device));
        QFile file(dir.filePath(name));
        if (!dir.mkpath(".") || !file.open(QIODevice::WriteOnly) || file.write(value) != value.size())
            qFatal("Could not create power-supply fixture");
    };
    auto read = [&] { return readPowerSupplies(tree.path()); };
    write("hid-mouse", "type", "Battery");
    write("hid-mouse", "scope", "Device");
    write("main-pack", "type", "Battery");
    write("main-pack", "present", "0");
    if (read().present)
        qFatal("Peripheral and absent batteries must be ignored");

    write("main-pack", "present", "1");
    write("main-pack", "capacity", "80\n");
    write("main-pack", "status", "Not charging");
    write("typec-port", "type", "USB");
    write("typec-port", "online", "1");
    auto held = read();
    if (!held.present || held.capacity != 80 || held.status != "Not charging" || !held.plugged)
        qFatal("Charge-limited battery should show plugged at 80 percent");

    write("typec-port", "online", "0");
    write("main-pack", "status", "Discharging");
    if (read().plugged)
        qFatal("Offline adapter should show unplugged");
    write("main-pack", "capacity", "unavailable");
    if (read().capacity != -1)
        qFatal("Invalid capacity should be unknown");
    QFile::remove(tree.filePath("typec-port/online"));
    write("main-pack", "status", "Charging");
    if (!read().plugged)
        qFatal("Charging should indicate power when adapter state is unavailable");
    write("main-pack", "present", "0");
    if (read().present || read().capacity != -1)
        qFatal("Unplugged battery should disappear");
}
