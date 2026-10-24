#include "PlaybackLoadingDeadline.h"
#include <cstdlib>
#include <iostream>
#define CHECK(c) do { if (!(c)) { std::cerr << "Failed line " << __LINE__ << '\n'; return EXIT_FAILURE; } } while (false)
int main() {
    PlaybackLoadingDeadline deadline;
    deadline.reset(0, -1);
    CHECK(deadline.remaining(30000) == 0); // Stalled connection still fails.
    deadline.observe(20000, 10, .01);
    CHECK(deadline.remaining(30000) == 20000); // Active long download survives 30s.
    deadline.observe(35000, 5, .01);
    deadline.observe(40000, 10, .01);
    CHECK(deadline.remaining(50000) == 0); // Repeated/oscillating reports cannot extend it.
    deadline.observe(55000, 90, .5);
    CHECK(deadline.remaining(55000) == 0); // Late events cannot revive an expired episode.
    deadline.reset(0, 0);
    for (int t = 10000; t <= 110000; t += 10000) {
        deadline.observe(t, 0, double(t) / 1000000);
        CHECK(deadline.remaining(t) > 0); // Fractional download progress counts.
    }
    deadline.observe(120000, 100, 1);
    CHECK(deadline.remaining(120000) == 0); // Absolute upper bound, even with progress.
    deadline.reset(50, .5);
    CHECK(deadline.remaining(0) == 30000); // A new loading episode has its own budget.
    deadline.observe(10000, 40, .4);
    CHECK(deadline.remaining(30000) == 0);
    std::cout << "PASS: loading progress, stalls, oscillation, hard deadline and reset\n";
}
