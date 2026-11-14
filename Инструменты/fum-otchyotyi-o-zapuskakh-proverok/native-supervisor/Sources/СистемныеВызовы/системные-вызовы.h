#include <sys/stat.h>
#include <sys/wait.h>
#include <unistd.h>
#include <signal.h>
#include <pthread.h>
#include <time.h>
#include <errno.h>
#include <fcntl.h>
#include <poll.h>
#include <spawn.h>
#include <stdlib.h>
#include <string.h>

// C-адаптер: прямой вызов системного flock без неоднозначности имени структуры.
static inline int fum_flock(int fd, int operation) { return flock(fd, operation); }
