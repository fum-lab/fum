# Извлечённый текст

Источник: <https://raw.githubusercontent.com/swiftlang/swift-llbuild/4fc005bfb0849f17e6a79ad02ba27f4f539ca6b9/products/CMakeLists.txt>

## Содержимое

```text
# Command line tools.
add_subdirectory(llbuild)
add_subdirectory(swift-build-tool)

# Public API products.
add_subdirectory(libllbuild)
if(Swift IN_LIST LLBUILD_SUPPORT_BINDINGS)
  enable_language(Swift)
  if(NOT CMAKE_SYSTEM_NAME STREQUAL Darwin)
    find_package(dispatch CONFIG)
    find_package(Foundation CONFIG)
  endif()

  add_subdirectory(llbuildSwift)
endif()
```

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-12 04:23:00 MSK -->
<!-- content-sha256: sha256:cba9863e7fe8d2641f8580702994470a5287385ea6c891d0da005b9859eb3e61 -->
<!-- FUM-MD-RECENCY:END -->
