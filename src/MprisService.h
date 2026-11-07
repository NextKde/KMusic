#pragma once

#include <QtGlobal>

#if defined(Q_OS_MACOS)
// macOS 用 MediaPlayer 框架实现，见 platform/macos/MprisService.mm
#include "../platform/macos/MprisService.h"
#else


#include <QObject>
#include <QVariantMap>

class MusicController;

class MprisService : public QObject {
    Q_OBJECT

public:
    explicit MprisService(MusicController *controller, QObject *parent = nullptr);
    ~MprisService() override;

    bool registered() const;

private:
    void publishPlayerProperties(const QVariantMap &properties) const;

    bool m_objectRegistered = false;
    bool m_registered = false;
};

#endif // Q_OS_MACOS
