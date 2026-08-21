/* shadow_ring.c — логика модуля shadow_mod (СТАРТЕР, s06e11).
 *
 * Ни одного заголовка ядра — и это главное в устройстве серии. Та часть,
 * где живут ошибки (границы буфера, переполнение, знаки), собирается
 * обычным gcc и проверяется юнит-тестами за миллисекунды. Отладка модуля
 * ядра через перезагрузки стоит на три порядка дороже.
 *
 * Интерфейс задан в shadow_ring.h — менять его не надо, надо реализовать.
 */
#include "shadow_ring.h"

void shadow_ring_init(struct shadow_ring *r, unsigned int capacity)
{
	/* TODO: обрезать capacity до [1, SHADOW_RING_MAX], обнулить буфер,
	 *       head, count и счётчик вытесненных. */
	(void)r; (void)capacity;   /* убрать, когда появится реализация */
}

int shadow_ring_push(struct shadow_ring *r, int value)
{
	/* TODO: положить значение, продвинуть head по кругу.
	 *       Если буфер уже полон — считать вытеснение (dropped++)
	 *       и вернуть 1. Буфер НИКОГДА не растёт. */
	(void)r; (void)value;
	return 0;
}

int shadow_ring_pop(struct shadow_ring *r, int *out)
{
	/* TODO: отдать самое СТАРОЕ значение. Подсказка: оно лежит на
	 *       count позиций назад от head, по модулю capacity. */
	(void)r; (void)out;
	return -1;
}

unsigned int shadow_ring_len(const struct shadow_ring *r)
{
	/* TODO */
	(void)r;
	return 0;
}

int shadow_ring_peek(const struct shadow_ring *r, unsigned int idx, int *out)
{
	/* TODO: idx=0 — самое СВЕЖЕЕ, то есть на шаг назад от head.
	 *       Не забирать, только посмотреть. */
	(void)r; (void)idx; (void)out;
	return -1;
}

int shadow_param_clamp(int requested, int lo, int hi)
{
	/* TODO: загнать в границы; выдержать и случай lo > hi. */
	(void)lo; (void)hi;
	return requested;
}

int shadow_scale_milli(int milli, int *whole, int *frac)
{
	/* TODO: 23062 -> 23 и 62; -4875 -> -4 и 875.
	 *
	 * В ядре НЕТ плавающей точки: делить только целочисленно.
	 * Дробная часть всегда неотрицательна — иначе -4875 напечатается
	 * как «-4.-875». Знак несёт целая часть; для значений вида -0.875
	 * целая часть ноль, и знак теряется — вернуть 1, чтобы вызывающий
	 * знал, что надо напечатать минус. */
	(void)milli; (void)whole; (void)frac;
	return -1;
}
