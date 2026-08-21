# Makefile сборки модуля ядра (kbuild). Дан готовым.
#
#   make            собрать shadow.ko (нужны заголовки ядра)
#   make clean      убрать за собой
#   make unit       собрать и прогнать юнит-тесты логики обычным gcc
#
# Модуль собирается из ДВУХ объектных файлов, поэтому его имя (shadow)
# отличается от имени любого из них — таково требование kbuild.
#
# Цель unit не требует ни ядра, ни root: ровно ради этого логика вынесена
# в отдельный файл без kernel-заголовков.

obj-m += shadow.o
shadow-objs := shadow_mod.o shadow_ring.o

KDIR ?= /lib/modules/$(shell uname -r)/build
PWD  := $(shell pwd)

all:
	$(MAKE) -C $(KDIR) M=$(PWD) modules

clean:
	$(MAKE) -C $(KDIR) M=$(PWD) clean 2>/dev/null || true
	rm -f unit_ring *.o

unit: shadow_ring.c ../tests/unit_ring.c
	$(CC) -std=c99 -Wall -Wextra -Werror -O1 -I. -o unit_ring \
	    shadow_ring.c ../tests/unit_ring.c
	./unit_ring

.PHONY: all clean unit
