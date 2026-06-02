"""
Pure renderer-layout tests.
"""

import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from todoist_overlay_render import WIDE_TIER_MIN_WIDTH, _tier_for_width


class TestTodoistOverlayRenderTier(unittest.TestCase):

    def test_2560_width_uses_wide_four_column_tier(self):
        self.assertEqual(_tier_for_width(WIDE_TIER_MIN_WIDTH - 1), 1)
        self.assertEqual(_tier_for_width(WIDE_TIER_MIN_WIDTH), 2)


if __name__ == "__main__":
    unittest.main()
