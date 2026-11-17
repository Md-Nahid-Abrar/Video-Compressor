/*
 * FFmpegCmd — runs FFmpeg's command-line front end inside an app.
 *
 * This header and ffcmd.c are part of the FFmpegCmd library and are licensed, like FFmpeg
 * itself as built here, under the GNU Lesser General Public License version 2.1 or later.
 */
#ifndef FFMPEGCMD_H
#define FFMPEGCMD_H

#include <stddef.h>

#ifdef __cplusplus
extern "C" {
#endif

/**
 * Runs one FFmpeg command and blocks until it finishes.
 *
 * `argv[0]` is the program name ("ffmpeg"); the rest are ordinary FFmpeg arguments.
 * Only one command may run at a time. Returns 0 on success, 255 if cancelled, or another
 * non-zero value on failure.
 */
int ffcmd_run(int argc, const char *const *argv);

/** Asks the running command to stop. Safe to call from any thread. */
void ffcmd_cancel(void);

/**
 * Copies the most recent warnings and errors logged by FFmpeg into `buffer`,
 * always NUL-terminated. Returns the number of bytes written, excluding the terminator.
 */
size_t ffcmd_copy_log(char *buffer, size_t capacity);

/** The FFmpeg version this library was built from, such as "8.1". */
const char *ffcmd_ffmpeg_version(void);

#ifdef __cplusplus
}
#endif

#endif /* FFMPEGCMD_H */
