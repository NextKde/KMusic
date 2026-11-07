#include "Transcoder.h"

#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QProcess>
#include <QStandardPaths>
#include <QUuid>

Transcoder::Transcoder(QObject *parent)
    : QObject(parent)
{
    const QString afconvert = QStandardPaths::findExecutable(QStringLiteral("afconvert"));
    if (!afconvert.isEmpty()) {
        m_formats = {
            {QStringLiteral("m4a"), QStringLiteral("M4A (AAC)"), QStringLiteral("m4a"),
             {QStringLiteral("-f"), QStringLiteral("m4af"), QStringLiteral("-d"),
              QStringLiteral("aac"), QStringLiteral("-b"), QStringLiteral("256000")}},
            {QStringLiteral("wav"), QStringLiteral("WAV"), QStringLiteral("wav"),
             {QStringLiteral("-f"), QStringLiteral("WAVE"), QStringLiteral("-d"),
              QStringLiteral("LEI16")}},
            {QStringLiteral("aiff"), QStringLiteral("AIFF"), QStringLiteral("aiff"),
             {QStringLiteral("-f"), QStringLiteral("AIFF"), QStringLiteral("-d"),
              QStringLiteral("BEI16")}},
        };
    }
    m_progressTimer.setInterval(250);
    connect(&m_progressTimer, &QTimer::timeout, this, &Transcoder::updateProgress);
}

Transcoder::~Transcoder()
{
    cleanup(true);
}

QVariantList Transcoder::availableFormats() const
{
    QVariantList result;
    for (const Format &format : m_formats) {
        result.append(QVariantMap{
            {QStringLiteral("id"), format.id},
            {QStringLiteral("label"), format.label},
            {QStringLiteral("extension"), format.extension},
        });
    }
    return result;
}

bool Transcoder::active() const { return m_active; }
double Transcoder::progress() const { return m_progress; }
QString Transcoder::status() const { return m_status; }
QString Transcoder::errorMessage() const { return m_errorMessage; }

const Transcoder::Format *Transcoder::findFormat(const QString &id) const
{
    for (const Format &format : m_formats) {
        if (format.id == id)
            return &format;
    }
    return nullptr;
}

bool Transcoder::start(const QUrl &input, const QUrl &output, const QString &formatId,
                       bool overwrite)
{
    if (m_active) {
        setError(QStringLiteral("Another conversion is already running"));
        return false;
    }
    const Format *format = findFormat(formatId);
    if (!format) {
        setError(QStringLiteral("The selected encoder is not installed"));
        return false;
    }
    if (!input.isLocalFile() || !QFileInfo::exists(input.toLocalFile()) || !output.isLocalFile()) {
        setError(QStringLiteral("Conversion requires local input and output files"));
        return false;
    }
    const QFileInfo outputInfo(output.toLocalFile());
    if (outputInfo.exists() && !overwrite) {
        setError(QStringLiteral("The output file already exists"));
        return false;
    }
    if (!QDir().mkpath(outputInfo.absolutePath())) {
        setError(QStringLiteral("Unable to create the output directory"));
        return false;
    }

    m_temporaryPath = outputInfo.absoluteDir().filePath(
        QStringLiteral(".%1.kosmusic-part-%2").arg(outputInfo.fileName(),
            QUuid::createUuid().toString(QUuid::WithoutBraces)));
    m_outputUrl = output;
    setError({});

    QStringList arguments{input.toLocalFile()};
    arguments << format->arguments << m_temporaryPath;

    m_process = new QProcess(this);
    connect(m_process, &QProcess::errorOccurred, this, [this](QProcess::ProcessError error) {
        if (error == QProcess::FailedToStart) {
            setError(QStringLiteral("Unable to start afconvert"));
            cleanup(true);
            setStatus(QStringLiteral("Failed"));
            setActive(false);
        }
    });
    connect(m_process, QOverload<int, QProcess::ExitStatus>::of(&QProcess::finished), this,
            [this](int exitCode, QProcess::ExitStatus) {
        const QString standardError = m_process ? QString::fromUtf8(m_process->readAllStandardError())
                                                : QString();
        if (exitCode != 0) {
            setError(standardError.isEmpty()
                         ? QStringLiteral("afconvert failed with exit code %1").arg(exitCode)
                         : standardError.trimmed());
            cleanup(true);
            setStatus(QStringLiteral("Failed"));
            setActive(false);
            return;
        }
        QFile::remove(m_outputUrl.toLocalFile());
        const bool moved = QFile::rename(m_temporaryPath, m_outputUrl.toLocalFile());
        if (!moved) {
            setError(QStringLiteral("Unable to write the converted file"));
            cleanup(true);
            setStatus(QStringLiteral("Failed"));
            setActive(false);
            return;
        }
        m_temporaryPath.clear();
        setProgress(1.0);
        setStatus(QStringLiteral("Finished"));
        setActive(false);
        cleanup(false);
        emit finished(m_outputUrl);
    });

    setProgress(0.0);
    setStatus(QStringLiteral("Converting"));
    setActive(true);
    m_progressTimer.start();
    m_process->start(QStringLiteral("afconvert"), arguments);
    return true;
}

void Transcoder::cancel()
{
    if (!m_active)
        return;
    cleanup(true);
    setStatus(QStringLiteral("Cancelled"));
    setActive(false);
}

void Transcoder::updateProgress()
{
    if (!m_active)
        return;
    if (m_progress < 0.9)
        setProgress(qMin(0.9, m_progress + 0.02));
}

void Transcoder::cleanup(bool removeTemporaryFile)
{
    m_progressTimer.stop();
    if (m_process) {
        m_process->disconnect(this);
        if (m_process->state() != QProcess::NotRunning) {
            m_process->kill();
            m_process->waitForFinished(2000);
        }
        m_process->deleteLater();
        m_process = nullptr;
    }
    if (removeTemporaryFile && !m_temporaryPath.isEmpty()) {
        QFile::remove(m_temporaryPath);
        m_temporaryPath.clear();
    }
}

void Transcoder::setStatus(const QString &status)
{
    if (m_status == status)
        return;
    m_status = status;
    emit statusChanged();
}

void Transcoder::setError(const QString &message)
{
    if (m_errorMessage == message)
        return;
    m_errorMessage = message;
    emit errorMessageChanged();
}

void Transcoder::setActive(bool active)
{
    if (m_active == active)
        return;
    m_active = active;
    emit activeChanged();
}

void Transcoder::setProgress(double progress)
{
    if (qFuzzyCompare(m_progress, progress))
        return;
    m_progress = progress;
    emit progressChanged();
}
