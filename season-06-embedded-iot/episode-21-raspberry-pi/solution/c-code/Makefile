# Makefile for GPIO Control - Episode 21 SOLUTION

CC = gcc
CFLAGS = -Wall -Wextra -Werror -O2 -std=c11
LIBS = -lgpiod

TARGET = gpio_control
SRC = gpio_control.c

all: $(TARGET)

$(TARGET): $(SRC)
	$(CC) $(CFLAGS) -o $(TARGET) $(SRC) $(LIBS)
	@echo "✓ Compiled successfully"
	@echo "  Run: sudo ./$(TARGET)"

clean:
	rm -f $(TARGET)
	@echo "✓ Cleaned"

run: $(TARGET)
	@echo "Running GPIO control..."
	sudo ./$(TARGET)

install: $(TARGET)
	sudo cp $(TARGET) /usr/local/bin/
	@echo "✓ Installed to /usr/local/bin/"

.PHONY: all clean run install
