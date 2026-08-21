/* shadow_ring.c — логика модуля shadow_mod (ЭТАЛОН, s06e11).
 *
 * Ни одного заголовка ядра. Это сознательное решение: та часть, где
 * живут ошибки (границы буфера, переполнение, знаки), собирается обычным
 * gcc и проверяется юнит-тестами за миллисекунды. В ядро уезжает уже
 * проверенный код, и там остаётся только обвязка.
 */
#include "shadow_ring.h"

void shadow_ring_init(struct shadow_ring *r, unsigned int capacity)
{
	unsigned int i;

	if (!r)
		return;
	if (capacity < 1)
		capacity = 1;
	if (capacity > SHADOW_RING_MAX)
		capacity = SHADOW_RING_MAX;

	for (i = 0; i < SHADOW_RING_MAX; i++)
		r->buf[i] = 0;
	r->head = 0;
	r->count = 0;
	r->capacity = capacity;
	r->dropped = 0;
}

int shadow_ring_push(struct shadow_ring *r, int value)
{
	int evicted = 0;

	if (!r || r->capacity == 0)
		return 0;

	r->buf[r->head] = value;
	r->head = (r->head + 1) % r->capacity;

	if (r->count < r->capacity) {
		r->count++;
	} else {
		/* буфер полон: самое старое вытеснено. Он НИКОГДА не растёт —
		 * в ядре нет никого, кто спасёт от переполнения памяти. */
		evicted = 1;
		r->dropped++;
	}
	return evicted;
}

int shadow_ring_pop(struct shadow_ring *r, int *out)
{
	unsigned int oldest;

	if (!r || !out || r->count == 0)
		return -1;

	/* самое старое лежит на count позиций назад от head */
	oldest = (r->head + r->capacity - r->count) % r->capacity;
	*out = r->buf[oldest];
	r->count--;
	return 0;
}

unsigned int shadow_ring_len(const struct shadow_ring *r)
{
	return r ? r->count : 0;
}

int shadow_ring_peek(const struct shadow_ring *r, unsigned int idx, int *out)
{
	unsigned int pos;

	if (!r || !out || idx >= r->count)
		return -1;

	/* idx=0 — самое свежее, то есть на шаг назад от head */
	pos = (r->head + r->capacity - 1 - idx) % r->capacity;
	*out = r->buf[pos];
	return 0;
}

int shadow_param_clamp(int requested, int lo, int hi)
{
	if (lo > hi) {
		int t = lo;
		lo = hi;
		hi = t;
	}
	if (requested < lo)
		return lo;
	if (requested > hi)
		return hi;
	return requested;
}

int shadow_scale_milli(int milli, int *whole, int *frac)
{
	int sign = 1;

	if (!whole || !frac)
		return -1;

	/* В ядре нет плавающей точки, поэтому делим целочисленно.
	 * Знак несёт целая часть, дробная всегда неотрицательна:
	 * иначе -4875 напечатается как «-4.-875». */
	if (milli < 0) {
		sign = -1;
		milli = -milli;
	}
	*whole = sign * (milli / 1000);
	*frac = milli % 1000;

	/* Отдельный случай: -0.875 — целая часть ноль, а знак нужен.
	 * Возвращаем его признаком, чтобы вызывающий напечатал минус. */
	return (sign < 0 && *whole == 0) ? 1 : 0;
}
