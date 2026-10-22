#include <QtQuickTest/quicktest.h>
#include <QCoreApplication>
class InputTestSetup : public QObject {
    Q_OBJECT
public slots:
    void applicationAvailable() {
        QCoreApplication::setOrganizationName("NextKdeTests");
        QCoreApplication::setApplicationName("KMusicInputTests");
    }
};
QUICK_TEST_MAIN_WITH_SETUP(kmusic_input, InputTestSetup)
#include "main.moc"
