#pragma once

#include <QString>

struct BatteryState {
    bool present = false;
    int capacity = -1;
    QString status;
    bool plugged = false;
};

BatteryState readPowerSupplies(const QString &root);
