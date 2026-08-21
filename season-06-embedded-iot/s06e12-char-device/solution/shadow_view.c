/* shadow_view.c — представление буфера для чтения (ЭТАЛОН, s06e12).
 *
 * Ни одного заголовка ядра — как и shadow_ring.c. Здесь живёт то, что
 * в драйверах символьных устройств ломается чаще всего: подсчёт, сколько
 * байт отдать при данном вызове read() и с какой позиции.
 */
#include "shadow_view.h"

/* Маленький помощник вместо snprintf: он есть и в ядре, но зависимость
 * от него утащила бы за собой заголовки. Здесь всё вручную и без
 * плавающей точки. */
static int put_str(char *buf, size_t cap, size_t at, const char *s)
{
	size_t i = 0;

	while (s[i]) {
		if (at + i >= cap)
			return -1;
		buf[at + i] = s[i];
		i++;
	}
	return (int)i;
}

static int put_ulong(char *buf, size_t cap, size_t at, unsigned long v)
{
	char tmp[24];
	int n = 0, i;

	if (v == 0) {
		tmp[n++] = '0';
	} else {
		while (v > 0 && n < (int)sizeof(tmp)) {
			tmp[n++] = (char)('0' + (v % 10));
			v /= 10;
		}
	}
	if (at + (size_t)n > cap)
		return -1;
	for (i = 0; i < n; i++)
		buf[at + i] = tmp[n - 1 - i];
	return n;
}

static int put_pad3(char *buf, size_t cap, size_t at, int v)
{
	if (at + 3 > cap)
		return -1;
	buf[at + 0] = (char)('0' + (v / 100) % 10);
	buf[at + 1] = (char)('0' + (v / 10) % 10);
	buf[at + 2] = (char)('0' + v % 10);
	return 3;
}

int shadow_format_line(unsigned long seq, int milli, char *buf, size_t cap)
{
	size_t at = 0;
	int n, whole, frac, neg;

	if (!buf || cap == 0)
		return -1;

	n = put_str(buf, cap, at, "seq=");        if (n < 0) return -1; at += (size_t)n;
	n = put_ulong(buf, cap, at, seq);         if (n < 0) return -1; at += (size_t)n;
	n = put_str(buf, cap, at, " t=");         if (n < 0) return -1; at += (size_t)n;

	/* Знак и дробная часть — из проверенной функции s06e11.
	 * Возврат 1 означает «целая часть ноль, но значение отрицательное»:
	 * без этого -0.875 напечаталось бы как 0.875. */
	neg = shadow_scale_milli(milli, &whole, &frac);
	if (neg < 0)
		return -1;
	if (neg == 1 || whole < 0) {
		n = put_str(buf, cap, at, "-");   if (n < 0) return -1; at += (size_t)n;
		if (whole < 0)
			whole = -whole;
	}
	n = put_ulong(buf, cap, at, (unsigned long)whole); if (n < 0) return -1; at += (size_t)n;
	n = put_str(buf, cap, at, ".");           if (n < 0) return -1; at += (size_t)n;
	n = put_pad3(buf, cap, at, frac);         if (n < 0) return -1; at += (size_t)n;
	n = put_str(buf, cap, at, "\n");          if (n < 0) return -1; at += (size_t)n;

	return (int)at;
}

int shadow_render(const struct shadow_ring *r, char *buf, size_t cap)
{
	size_t at = 0;
	unsigned int len, i;
	int v, n;

	if (!r || !buf)
		return -1;

	len = shadow_ring_len(r);
	/* от самого старого к самому свежему: peek считает от свежего,
	 * поэтому идём с конца */
	for (i = len; i > 0; i--) {
		if (shadow_ring_peek(r, i - 1, &v) != 0)
			return -1;
		n = shadow_format_line((unsigned long)(len - i + 1), v,
				       buf + at, cap - at);
		if (n < 0)
			return -1;
		at += (size_t)n;
	}
	return (int)at;
}

int shadow_copy_slice(const char *src, size_t len, size_t pos,
		      char *dst, size_t count)
{
	size_t avail, i;

	if (!src || !dst)
		return -1;

	/* Позиция за концом данных — это конец файла, а не ошибка.
	 * Ровно так read() сообщает «больше ничего нет». */
	if (pos >= len)
		return 0;

	avail = len - pos;
	if (count < avail)
		avail = count;

	for (i = 0; i < avail; i++)
		dst[i] = src[pos + i];

	return (int)avail;
}
