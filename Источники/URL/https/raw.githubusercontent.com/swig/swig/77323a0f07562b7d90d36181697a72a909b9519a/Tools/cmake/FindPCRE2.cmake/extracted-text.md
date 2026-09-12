# Извлечённый текст

Источник: <https://raw.githubusercontent.com/swig/swig/77323a0f07562b7d90d36181697a72a909b9519a/Tools/cmake/FindPCRE2.cmake>

## Содержимое

```text
# - Find PCRE2
# Perl Compatible Regular Expressions
# https://www.pcre.org/

# The following variables are set:
# PCRE2_FOUND - System has the PCRE library
# PCRE2_LIBRARIES - The PCRE library file
# PCRE2_INCLUDE_DIRS - The folder with the PCRE headers

find_library(PCRE2_LIBRARY NAMES pcre2 pcre2-8)
find_path(PCRE2_INCLUDE_DIR pcre2.h)

set (PCRE2_LIBRARIES ${PCRE2_LIBRARY})
set (PCRE2_INCLUDE_DIRS ${PCRE2_INCLUDE_DIR})

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(PCRE2 DEFAULT_MSG PCRE2_LIBRARIES PCRE2_INCLUDE_DIRS)

mark_as_advanced (
  PCRE2_LIBRARY
  PCRE2_INCLUDE_DIR)
```

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-12 04:23:00 MSK -->
<!-- content-sha256: sha256:9989cfba019e69e51f0a952d9db6b8c13b8c104f4169e049869361b7d3230210 -->
<!-- FUM-MD-RECENCY:END -->
