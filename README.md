# Mini POSIX Shell (C)

A minimal interactive shell written in C that demonstrates core UNIX process concepts: tokenizing input, forking, executing programs with `execvp`, synchronizing with `wait`, basic built-ins (`cd`, `pwd`, `exit`), a simple signal handler, and a **threaded command runner** via a custom `&t` prefix.

> This README is tailored to the provided `shell.c` implementation.

## Features

- **Foreground execution**: Runs external programs using `fork()` + `execvp()`, and the parent waits with `wait()` for deterministic output.
- **Built-ins**:
  - `cd <dir>` and `cd -` (the `-` form goes **one directory up** in this implementation)
  - `pwd`
  - `exit`
  Built-ins run in the parent process so directory changes persist.
- **Threaded runner (`&t`)**: Prefix a command with `&t` to run it in a separate **pthread** that calls `system("<full command>")`. The thread is **joined** immediately (so this is not full background job control).
- **Signal handling**: A `SIGINT` (Ctrl‑C) handler prevents the shell process itself from terminating.

## Build & Run

```bash
# Build (Linux/macOS; requires pthreads)
gcc -Wall -Wextra -O2 -pthread shell.c -o mysh

# Or with the included Makefile
make

# Run
./mysh
```

You should see a prompt like:

```
my-shell> $
```

## Usage Examples

**Run an external command (foreground):**
```
my-shell> $ ls -l
```

**Built-ins:**
```
my-shell> $ pwd
/home/user
my-shell> $ cd /tmp
my-shell> $ pwd
/tmp
my-shell> $ cd -        # goes up one directory (parent) in this implementation
my-shell> $ exit
```

**Threaded execution (custom `&t` syntax):**
```
my-shell> $ &t sleep 2
```
This spawns a thread that calls `system("sleep 2")` and **waits** for it to finish via `pthread_join`.

**Ctrl‑C behavior:**
- Pressing `Ctrl‑C` sends `SIGINT`, which is caught by the shell’s handler so the REPL keeps running.

## How It Works (High-Level)

1. **Read & tokenize**: Input is read with `fgets` and split into tokens using `strtok`.
2. **Command selection**:
   - **Built-ins** (`cd`, `pwd`, `exit`) are handled in the parent process.
   - Other commands: the shell `fork()`s; the child calls `execvp(argv[0], argv)`, and the parent `wait()`s.
3. **Threaded runner `&t`**: If the first token is `&t`, the remainder of the line is passed as a single string to `system()` inside a `pthread`. The thread is **joined** before reading the next command.
4. **Signals**: `signal(SIGINT, handle_signit)` installs a handler so that Ctrl‑C doesn’t terminate the shell loop.

## Design Notes / Trade-Offs

- Uses `execvp`, so the executable is searched using the current `PATH`.
- The `&t` mode uses `system()`, which executes via `/bin/sh -c "<string>"`. This is simple but means:
  - Quoting/expansion is handled by `/bin/sh`.
  - **Security**: Do not pass untrusted input (possible shell injection).
  - Because the thread is **joined**, there is **no concurrent prompt** or job control.
- Minimal parsing: tokens are whitespace-delimited; no quotes/escapes of its own.

## Limitations (Intentional for Simplicity)

- No job control (`&`, `fg`, `bg`), no process groups.
- No pipes (`|`) or I/O redirection (`>`, `<`, `2>`).
- No globbing or advanced shell features.
- EOF (`Ctrl‑D`) exits only if your libc returns `NULL` from `fgets`; not explicitly handled with a custom message.

## Roadmap / Ideas

- Detach threaded jobs (`pthread_detach`) and keep a job table for true background tasks.
- Add pipes and redirection using `pipe()`, `dup2()`, and multiple `fork()`s.
- Implement a proper tokenizer/parser that understands quotes and escapes.
- More robust signal handling (`SIGCHLD`, restore default handlers in child before `exec`). 
- Tests and sanitizers (`-fsanitize=address,undefined`).

## File Structure

```
.
├── shell.c
├── README.md
└── Makefile
```

Key functions in `shell.c` (names as implemented):
- `tokenize(...)` – splits raw input into tokens.
- `token_to_cmd(...)` – builds a single command argv from tokens.
- `execute(...)` – prepares `argv` and calls `execvp` for non-built-ins.
- `run_thread(...)` – executes a full command string in a pthread via `system()`.
- `main()` – the REPL loop: handles built-ins, `&t`, `fork/exec`, `wait`, and signal setup.

## Example Session

See `example_session.txt` for a short transcript.

## License

MIT (or choose your preferred license).
