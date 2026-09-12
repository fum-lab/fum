# Извлечённый текст

Источник: <https://raw.githubusercontent.com/swiftlang/swift/cc4f13a96e9600bd6f801368ab51f614ab5ddd5e/utils/update-checkout>

## Содержимое

```text
#!/usr/bin/env python3

import sys

import update_checkout

if __name__ == '__main__':
    # This line was added in dfe3af81b2 to address an importing issue on
    # Windows.  It causes this script to break badly when used with
    # Python 3.8 on macOS. Disabling for all Python 3 until someone
    # can help sort out what's really needed for Windows:
    if sys.version_info.major < 3:
        sys.modules[__name__] = sys.modules['update_checkout']

    update_checkout.main()
```

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-12 04:23:00 MSK -->
<!-- content-sha256: sha256:ccf335fc4be780b6329dbec3abeb848a7d400ecb8e0a1bb0a61b75666a57f1f2 -->
<!-- FUM-MD-RECENCY:END -->
