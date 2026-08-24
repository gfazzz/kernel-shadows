# Makefile сборки shadow.ko (kbuild). Дан готовым.
#
#   make            собрать shadow.ko (нужны заголовки ядра)
#   make unit       собрать и прогнать юнит-тесты логики обычным gcc
#   make clean      убрать за собой
#
# Модуль состоит из трёх объектных файлов, два из которых (shadow_ring,
# shadow_view) не зависят от ядра и проверяются без него.

obj-m += shadow.o
shadow-objs := shadow_dev.o shadow_view.o shadow_ring.o

KDIR ?= /lib/modules/$(shell uname -r)/build
PWD  := $(shell pwd)

all:
	$(MAKE) -C $(KDIR) M=$(PWD) modules

clean:
	$(MAKE) -C $(KDIR) M=$(PWD) clean 2>/dev/null || true
	rm -f unit_view *.o

unit: shadow_ring.c shadow_view.c ../tests/unit_view.c
	$(CC) -std=c99 -Wall -Wextra -Werror -O1 -I. -o unit_view \
	    shadow_ring.c shadow_view.c ../tests/unit_view.c
	./unit_view

.PHONY: all clean unit
