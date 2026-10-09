#include <vector>

#include "keyboard_report_util.hpp"
#include "keycode.h"
#include "keymap_extras/keymap_dvorak.h"
#include "test_common.hpp"
#include "test_fixture.hpp"
#include "test_keymap_key.hpp"

using testing::_;
using testing::AnyNumber;
using testing::Invoke;

// Records what the host receives: every key as it first appears in a report,
// and every modifier byte that went out.
class TapHold : public TestFixture {
   protected:
    void record_reports(TestDriver& driver) {
        EXPECT_CALL(driver, send_keyboard_mock(_)).Times(AnyNumber()).WillRepeatedly(Invoke([this](report_keyboard_t& report) {
            mods_seen.push_back(report.mods);
            for (uint8_t key : report.keys) {
                if (key != KC_NO && !was_down(key)) {
                    typed.push_back(key);
                }
            }
            down.assign(std::begin(report.keys), std::end(report.keys));
        }));
    }

    uint8_t all_mods() const {
        uint8_t mods = 0;
        for (uint8_t seen : mods_seen) {
            mods |= seen;
        }
        return mods;
    }

    std::vector<uint8_t> typed;
    std::vector<uint8_t> mods_seen;

   private:
    bool was_down(uint8_t key) const {
        return std::find(down.begin(), down.end(), key) != down.end();
    }

    std::vector<uint8_t> down;
};

// Matrix halves as tap_hold.c reads them: rows 0-1 are the left hand and
// rows 2-3 the right hand. KeymapKey takes layer, column, row, keycode.
TEST_F(TapHold, ClaudeRollAfterPauseTypesLetters) {
    TestDriver driver;
    auto       key_c = KeymapKey(0, 0, 2, LGUI_T(DV_C));
    auto       key_l = KeymapKey(0, 1, 2, LCTL_T(DV_L));
    auto       key_a = KeymapKey(0, 0, 0, DV_A);
    auto       key_u = KeymapKey(0, 1, 0, DV_U);
    set_keymap({key_c, key_l, key_a, key_u});
    record_reports(driver);

    idle_for(1000);
    for (KeymapKey* key : {&key_c, &key_l, &key_a, &key_u}) {
        key->press();
        run_one_scan_loop();
        idle_for(20);
    }
    for (KeymapKey* key : {&key_a, &key_u, &key_c, &key_l}) {
        key->release();
        run_one_scan_loop();
        idle_for(20);
    }
    idle_for(300);

    EXPECT_EQ(all_mods(), 0);
    EXPECT_EQ(typed, (std::vector<uint8_t>{KC_I, KC_P, KC_A, KC_F}));
}
