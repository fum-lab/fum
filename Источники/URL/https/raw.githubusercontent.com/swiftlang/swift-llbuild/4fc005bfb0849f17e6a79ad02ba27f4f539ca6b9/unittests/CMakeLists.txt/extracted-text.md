# Извлечённый текст

Источник: <https://raw.githubusercontent.com/swiftlang/swift-llbuild/4fc005bfb0849f17e6a79ad02ba27f4f539ca6b9/unittests/CMakeLists.txt>

## Содержимое

```text
add_custom_target(UnitTests)
set_target_properties(UnitTests PROPERTIES FOLDER "Tests")

function(add_llbuild_unittest test_dirname)
  add_unittest(UnitTests ${test_dirname} ${ARGN})
endfunction()

add_subdirectory(Basic)
add_subdirectory(CAPI)
add_subdirectory(Core)
add_subdirectory(BuildSystem)
add_subdirectory(Ninja)
```

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-12 04:23:00 MSK -->
<!-- content-sha256: sha256:a2b16d33278d4e954f43ebf0ab1f91f24d27ec7b5a912e7345bb799c569a7c91 -->
<!-- FUM-MD-RECENCY:END -->
