#pragma once

#include <QObject>
#include <QTimer>
#include <QUrl>
#include <QVariantList>

class QProcess;

// macOS 版转码器：调用系统自带 afconvert（无需第三方编码器）。
// 公共接口与原 GStreamer 实现一致。
class Transcoder : public QObject {
    Q_OBJECT

public:
    explicit Transcoder(QObject *parent = nullptr);
    ~Transcoder() override;

    QVariantList availableFormats() const;
    bool active() const;
    double progress() const;
    QString status() const;
    QString errorMessage() const;

    bool start(const QUrl &input, const QUrl &output, const QString &formatId,
               bool overwrite = false);
    void cancel();

signals:
    void availableFormatsChanged();
    void activeChanged();
    void progressChanged();
    void statusChanged();
    void errorMessageChanged();
    void finished(const QUrl &output);

private slots:
    void updateProgress();

private:
    struct Format {
        QString id;
        QString label;
        QString extension;
        QStringList arguments;
    };

    void setStatus(const QString &status);
    void setError(const QString &message);
    void setActive(bool active);
    void setProgress(double progress);
    void cleanup(bool removeTemporaryFile);
    const Format *findFormat(const QString &id) const;

    QList<Format> m_formats;
    QProcess *m_process = nullptr;
    QTimer m_progressTimer;
    QUrl m_outputUrl;
    QString m_temporaryPath;
    QString m_status = QStringLiteral("Idle");
    QString m_errorMessage;
    double m_progress = 0.0;
    bool m_active = false;
};
