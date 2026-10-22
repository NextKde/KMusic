#include "AudioCache.h"

#include <QCryptographicHash>
#include <QDateTime>
#include <QDir>
#include <QFile>
#include <QFileInfo>

#include <algorithm>

AudioCache::AudioCache(const QString &directory, qint64 maxBytes)
    : m_directory(directory), m_maxBytes(maxBytes)
{
    QDir().mkpath(directory);
    prune();
}

QString AudioCache::pathFor(const QString &key) const
{
    const auto digest = QCryptographicHash::hash(key.toUtf8(), QCryptographicHash::Sha256);
    return QDir(m_directory).filePath(QString::fromLatin1(digest.toHex()) + QStringLiteral(".audio"));
}

QString AudioCache::downloadDirectory() const { return m_directory; }

QUrl AudioCache::lookup(const QString &key)
{
    QFile file(pathFor(key));
    if (file.size() <= 0 || !file.open(QIODevice::ReadOnly))
        return {};
    file.setFileTime(QDateTime::currentDateTimeUtc(), QFileDevice::FileModificationTime);
    return QUrl::fromLocalFile(file.fileName());
}

bool AudioCache::storeCompleted(const QString &key, const QString &path)
{
    const QFileInfo info(path);
    if (key.isEmpty() || info.size() <= 0
        || info.size() > std::min<qint64>(m_maxBytes, 256LL * 1024 * 1024)
        || info.absolutePath() != QDir(m_directory).absolutePath())
        return false;
    if (!lookup(key).isEmpty())
        return true;
    // Only closed, fully written downloads reach this atomic publication step.
    // Incomplete downloads are removed by PlaybackEngine.
    if (!QFile::rename(path, pathFor(key)))
        return false;
    prune();
    return true;
}

void AudioCache::remove(const QString &key) { QFile::remove(pathFor(key)); }

void AudioCache::prune()
{
    const QFileInfoList entries = QDir(m_directory).entryInfoList(
        {QStringLiteral("*.audio")}, QDir::Files, QDir::Time);
    qint64 total = 0;
    for (const QFileInfo &entry : entries) {
        total += entry.size();
        if (total > m_maxBytes)
            QFile::remove(entry.absoluteFilePath());
    }
}

qint64 AudioCache::sizeBytes() const
{
    qint64 bytes = 0;
    for (const auto &entry : QDir(m_directory).entryInfoList({QStringLiteral("*.audio")}, QDir::Files | QDir::NoSymLinks))
        bytes += entry.size();
    return bytes;
}

bool AudioCache::clearCompleted(const QString &protectedPath, const QString &protectedKey)
{
    bool complete = true;
    for (const auto &entry : QDir(m_directory).entryInfoList({QStringLiteral("*.audio")}, QDir::Files | QDir::NoSymLinks)) {
        if (entry.absoluteFilePath() == protectedPath
            || (!protectedKey.isEmpty() && entry.absoluteFilePath() == pathFor(protectedKey))) { complete = false; continue; }
        if (!QFile::remove(entry.absoluteFilePath())) complete = false;
    }
    return complete;
}
