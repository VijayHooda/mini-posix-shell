CC = gcc
CFLAGS = -Wall -Wextra -O2 -pthread
TARGET = mysh

all: $(TARGET)

$(TARGET): shell.o
	$(CC) $(CFLAGS) -o $@ $^

shell.o: shell.c
	$(CC) $(CFLAGS) -c $<

clean:
	rm -f $(TARGET) *.o
