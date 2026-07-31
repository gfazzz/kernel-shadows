# Makefile for GPIO Control - Episode 21

CC = gcc
CFLAGS = -Wall -Wextra -O2
LIBS = -lgpiod

TARGET = gpio_control
SRC = gpio_control.c

all: $(TARGET)

$(TARGET): $(SRC)
	$(CC) $(CFLAGS) -o $(TARGET) $(SRC) $(LIBS)

clean:
	rm -f $(TARGET)

run: $(TARGET)
	sudo ./$(TARGET)

.PHONY: all clean run
