.POSIX:

# configuration for dependencies
include config.mk

CC = gcc
CPPFLAGS = -D_DEFAULT_SOURCE -D_BSD_SOURCE -D_XOPEN_SOURCE=700L -D_POSIX_C_SOURCE=200809L
CFLAGS = -Wall -Wextra -std=c99 -ggdb -O3 
LDFLAGS = -lncurses

# Directories
SRC_DIR = src

# Source files
PROCAUDIT_SRC = $(SRC_DIR)/procaudit.c
ARENA_SRC = $(SRC_DIR)/arena.c
STRING_SRC = $(SRC_DIR)/string.c

# Object files
PROCAUDIT_OBJ = $(SRC_DIR)/procaudit.o
ARENA_OBJ = $(SRC_DIR)/arena.o
STRING_OBJ = $(SRC_DIR)/string.o

# Headers
ARENA_H = $(SRC_DIR)/arena.h
STRING_H = $(SRC_DIR)/string.h
HEADERS = $(ARENA_H) $(STRING_H)

# Target executable
TARGET = procaudit

# Platform-specific flags (AddressSanitizer for clang on Linux)
CPPFLAGS += $(shell if echo "$(CC)" | grep -q clang && [ "`uname -s`" = "Linux" ]; then echo "-fsanitize=address"; fi)

# Default target
all: deps $(TARGET)

deps:
	@if [ ! -f "$(ARENA_H)" ] || [ ! -f "$(STRING_H)" ] || [ ! -f "$(ARENA_SRC)" ] || [ ! -f "$(STRING_SRC)" ]; then \
		echo "==> Dependencies not found, fetching..."; \
		$(MAKE) fetch-only; \
	fi

# Main executable (procaudit)
$(TARGET): $(PROCAUDIT_OBJ) $(ARENA_OBJ) $(STRING_OBJ)
	$(CC) $(CPPFLAGS) $(CFLAGS) $(PROCAUDIT_OBJ) $(ARENA_OBJ) $(STRING_OBJ) -o $(TARGET) $(LDFLAGS)
	@echo "==> Build complete: $(TARGET)"

# Object files
$(PROCAUDIT_OBJ): $(PROCAUDIT_SRC) $(HEADERS)
	@echo "==> Compiling: $(PROCAUDIT_SRC)"
	$(CC) $(CPPFLAGS) $(CFLAGS) -c $(PROCAUDIT_SRC) -o $(PROCAUDIT_OBJ)

$(STRING_OBJ): $(STRING_SRC) $(HEADERS)
	@echo "==> Compiling: $(STRING_SRC)"
	$(CC) $(CPPFLAGS) $(CFLAGS) -c $(STRING_SRC) -o $(STRING_OBJ)

# Arena must be compiled before string (dependency)
$(ARENA_OBJ): $(ARENA_SRC) $(ARENA_H)
	@echo "==> Compiling: $(ARENA_SRC)"
	$(CC) $(CPPFLAGS) $(CFLAGS) -c $(ARENA_SRC) -o $(ARENA_OBJ)

# Fetch dependencies
fetch-only:
	@echo "==> Fetching dependencies..."
	@if [ ! -d "$(SRC_DIR)" ]; then mkdir -p $(SRC_DIR); fi
	@echo "==> Downloading arena library..."
	curl -L "$(ARENA_URL)/arena.c" -o $(ARENA_SRC) || \
		{ echo "Failed to download arena.c"; exit 1; }
	curl -L "$(ARENA_URL)/arena.h" -o $(ARENA_H) || \
		{ echo "Failed to download arena.h"; exit 1; }
	@echo "==> Downloading string library..."
	curl -L "$(STRING_URL)/string.c" -o $(STRING_SRC) || \
		{ echo "Failed to download string.c"; exit 1; }
	curl -L "$(STRING_URL)/string.h" -o $(STRING_H) || \
		{ echo "Failed to download string.h"; exit 1; }
	@echo "==> Dependencies fetched successfully"

# Fetch dependencies from GitHub and compile them
fetch: fetch-only
	@echo "==> Compiling dependencies..."
	$(MAKE) $(ARENA_OBJ)
	$(MAKE) $(STRING_OBJ)
	@echo "==> Dependencies compiled successfully"

arena: $(ARENA_OBJ)
	@echo "==> Arena module compiled successfully"

string: $(STRING_OBJ)
	@echo "==> String module compiled successfully"

run: deps $(TARGET)
	@echo "==> Running $(TARGET)..."
	./$(TARGET)

clean:
	@echo "==> Cleaning up..."
	rm -f $(SRC_DIR)/*.o $(TARGET)
	rm -f $(ARENA_SRC) $(ARENA_H) $(STRING_SRC) $(STRING_H)
	@echo "==> Clean complete"

# Help target
help:
	@echo "Available targets:"
	@echo "  all     - Build the main executable (default)"
	@echo "  fetch   - Download and compile dependencies"
	@echo "  run     - Build and run the main executable"
	@echo "  arena   - Compile only the arena module"
	@echo "  string  - Compile only the string module"
	@echo "  clean   - Remove all files (objects, executables, dependencies)"
	@echo "  help    - Show this help message"

.PHONY: all deps fetch fetch-only run arena string clean help
