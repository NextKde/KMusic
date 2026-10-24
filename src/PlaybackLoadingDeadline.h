#pragma once
#include <algorithm>
#include <cstdint>

// A loading episode may make slow progress, but must never wait indefinitely.
// Caller supplies monotonic milliseconds so policy tests need no wall-clock sleep.
class PlaybackLoadingDeadline {
public:
    static constexpr int stallMs = 30000;
    static constexpr int totalMs = 120000;
    void reset(int buffered, double downloaded) {
        m_buffered = buffered; m_downloaded = downloaded; m_lastProgress = 0;
    }
    void observe(std::int64_t elapsed, int buffered, double downloaded) {
        if (remaining(elapsed) == 0) return;
        if (buffered > m_buffered || downloaded > m_downloaded)
            m_lastProgress = elapsed;
        // Oscillating buffering percentages are not fresh progress.
        m_buffered = std::max(m_buffered, buffered);
        m_downloaded = std::max(m_downloaded, downloaded);
    }
    int remaining(std::int64_t elapsed) const {
        return int(std::max<std::int64_t>(0, std::min<std::int64_t>(
            totalMs - elapsed, stallMs - (elapsed - m_lastProgress))));
    }
private:
    int m_buffered = 0;
    double m_downloaded = -1;
    std::int64_t m_lastProgress = 0;
};
