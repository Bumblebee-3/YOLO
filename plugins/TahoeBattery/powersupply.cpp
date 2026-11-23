#include "powersupply.h"

#include <QDir>
#include <QFile>

static QString attribute(const QDir &device, const QString &name)
{
    QFile file(device.filePath(name));
    if (!file.open(QIODevice::ReadOnly))
        return {};
    return QString::fromUtf8(file.readAll()).trimmed();
}

BatteryState readPowerSupplies(const QString &root)
{
    BatteryState state;
    bool onlineKnown = false;
    const QDir supplies(root);
    const auto devices = supplies.entryList(QDir::Dirs | QDir::NoDotAndDotDot, QDir::Name);
    for (const auto &name : devices) {
        const QDir device(supplies.filePath(name));
        const auto type = attribute(device, "type");
        if (type.isEmpty() || attribute(device, "scope") == "Device")
            continue;
        if (type == "Battery") {
            if (state.present || attribute(device, "present") == "0")
                continue;
            state.present = true;
            state.status = attribute(device, "status");
            bool ok;
            const int capacity = attribute(device, "capacity").toInt(&ok);
            if (ok && capacity >= 0 && capacity <= 100)
                state.capacity = capacity;
        } else {
            bool ok;
            const int online = attribute(device, "online").toInt(&ok);
            if (ok && online >= 0) {
                onlineKnown = true;
                state.plugged |= online > 0;
            }
        }
    }
    if (!onlineKnown)
        state.plugged = state.status == "Charging" || state.status == "Full"
                     || state.status == "Not charging" || state.status == "Pending charge";
    return state;
}
