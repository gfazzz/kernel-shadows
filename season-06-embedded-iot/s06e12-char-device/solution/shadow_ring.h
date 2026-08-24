/* shadow_ring.h — интерфейс логики модуля shadow_mod (дан готовым).
 *
 * Этот заголовок и shadow_ring.c НЕ зависят от ядра: ни одного
 * kernel-заголовка, ни одного вызова printk. Ровно поэтому их можно
 * собрать обычным gcc и проверить настоящими юнит-тестами в
 * пользовательском пространстве — без сборки .ko, без root и без Linux.
 *
 * Всё, что зависит от ядра (module_init, module_param, printk, sysfs),
 * живёт в shadow_mod.c и проверяется отдельно.
 */
#ifndef SHADOW_RING_H
#define SHADOW_RING_H

#define SHADOW_RING_MAX 64

struct shadow_ring {
	int buf[SHADOW_RING_MAX];
	unsigned int head;      /* индекс, куда писать следующее */
	unsigned int count;     /* сколько значений лежит */
	unsigned int capacity;  /* сколько помещается */
	unsigned long dropped;  /* сколько вытеснено за всё время */
};

/* Подготовить буфер. capacity обрезается до [1, SHADOW_RING_MAX]. */
void shadow_ring_init(struct shadow_ring *r, unsigned int capacity);

/* Положить значение. Возвращает 1, если пришлось вытеснить самое
 * старое, иначе 0. Буфер никогда не растёт. */
int shadow_ring_push(struct shadow_ring *r, int value);

/* Забрать самое старое. 0 — успех, -1 — буфер пуст. */
int shadow_ring_pop(struct shadow_ring *r, int *out);

/* Сколько значений лежит. */
unsigned int shadow_ring_len(const struct shadow_ring *r);

/* Посмотреть idx-е с конца (0 — самое свежее), не забирая.
 * 0 — успех, -1 — такого нет. */
int shadow_ring_peek(const struct shadow_ring *r, unsigned int idx, int *out);

/* Загнать значение параметра в допустимые границы. */
int shadow_param_clamp(int requested, int lo, int hi);

/* Разложить тысячные доли на целую и дробную часть БЕЗ плавающей точки:
 * 23062 -> 23 и 62, -4875 -> -4 и 875.
 * Возвращает 0 при успехе; frac всегда неотрицателен, знак несёт whole. */
int shadow_scale_milli(int milli, int *whole, int *frac);

#endif /* SHADOW_RING_H */
