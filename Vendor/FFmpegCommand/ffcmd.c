/*
 * FFmpegCmd — runs FFmpeg's command-line front end inside an app.
 * Licensed under the GNU Lesser General Public License version 2.1 or later.
 */
#include "FFmpegCmd.h"

#include <pthread.h>
#include <stdarg.h>
#include <stdlib.h>
#include <string.h>

#include "libavutil/avutil.h"
#include "libavutil/log.h"

/* Provided by the patched fftools/ffmpeg.c. */
int ffmpeg_main(int argc, char **argv);
void ffcmd_reset_state(void);
void ffcmd_request_cancel(void);

#define LOG_CAPACITY 4096

static pthread_mutex_t log_lock = PTHREAD_MUTEX_INITIALIZER;
static char log_buffer[LOG_CAPACITY];
static size_t log_length;
static int log_print_prefix = 1;

/* Keeps the tail of FFmpeg's warnings and errors so the app can explain a failure. */
static void log_callback(void *ptr, int level, const char *fmt, va_list args)
{
    char line[1024];
    size_t length;

    if (level > AV_LOG_WARNING)
        return;

    pthread_mutex_lock(&log_lock);
    av_log_format_line(ptr, level, fmt, args, line, sizeof(line), &log_print_prefix);
    length = strlen(line);
    if (length >= LOG_CAPACITY) {
        memcpy(log_buffer, line + length - (LOG_CAPACITY - 1), LOG_CAPACITY - 1);
        log_length = LOG_CAPACITY - 1;
    } else {
        if (log_length + length >= LOG_CAPACITY) {
            size_t drop = log_length + length - (LOG_CAPACITY - 1);
            memmove(log_buffer, log_buffer + drop, log_length - drop);
            log_length -= drop;
        }
        memcpy(log_buffer + log_length, line, length);
        log_length += length;
    }
    log_buffer[log_length] = '\0';
    pthread_mutex_unlock(&log_lock);
}

int ffcmd_run(int argc, const char *const *argv)
{
    char **copy;
    int result;
    int i;

    if (argc <= 0 || !argv)
        return 1;

    /* FFmpeg may rewrite its argument array, so it gets its own copy. */
    copy = calloc((size_t)argc + 1, sizeof(*copy));
    if (!copy)
        return 1;
    for (i = 0; i < argc; i++) {
        copy[i] = strdup(argv[i] ? argv[i] : "");
        if (!copy[i]) {
            while (i-- > 0)
                free(copy[i]);
            free(copy);
            return 1;
        }
    }

    pthread_mutex_lock(&log_lock);
    log_length = 0;
    log_buffer[0] = '\0';
    log_print_prefix = 1;
    pthread_mutex_unlock(&log_lock);

    av_log_set_callback(log_callback);
    ffcmd_reset_state();
    result = ffmpeg_main(argc, copy);

    for (i = 0; i < argc; i++)
        free(copy[i]);
    free(copy);
    return result;
}

void ffcmd_cancel(void)
{
    ffcmd_request_cancel();
}

size_t ffcmd_copy_log(char *buffer, size_t capacity)
{
    size_t length;

    if (!buffer || capacity == 0)
        return 0;
    pthread_mutex_lock(&log_lock);
    length = log_length < capacity - 1 ? log_length : capacity - 1;
    memcpy(buffer, log_buffer + (log_length - length), length);
    buffer[length] = '\0';
    pthread_mutex_unlock(&log_lock);
    return length;
}

const char *ffcmd_ffmpeg_version(void)
{
    return av_version_info();
}
