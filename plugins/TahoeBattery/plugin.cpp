#include "powersupply.h"

#include <QQmlExtensionPlugin>
#include <QTimer>
#include <qqml.h>

class BatteryInfo : public QObject {
    Q_OBJECT
    Q_PROPERTY(bool present READ present NOTIFY changed)
    Q_PROPERTY(int capacity READ capacity NOTIFY changed)
    Q_PROPERTY(QString status READ status NOTIFY changed)
    Q_PROPERTY(bool plugged READ plugged NOTIFY changed)

public:
    BatteryInfo()
    {
        refresh();
        connect(&timer, &QTimer::timeout, this, &BatteryInfo::refresh);
        timer.start(30000);
    }

    bool present() const { return state.present; }
    int capacity() const { return state.capacity; }
    QString status() const { return state.status; }
    bool plugged() const { return state.plugged; }

signals:
    void changed();

private:
    void refresh()
    {
        auto next = readPowerSupplies(QStringLiteral("/sys/class/power_supply"));
        if (state.present == next.present && state.capacity == next.capacity
            && state.status == next.status && state.plugged == next.plugged)
            return;
        state = next;
        emit changed();
    }

    BatteryState state;
    QTimer timer;
};

class BatteryPlugin : public QQmlExtensionPlugin {
    Q_OBJECT
    Q_PLUGIN_METADATA(IID QQmlExtensionInterface_iid)

public:
    void registerTypes(const char *uri) override
    {
        qmlRegisterType<BatteryInfo>(uri, 1, 0, "BatteryInfo");
    }
};

#include "plugin.moc"
