/* unit_view.c — юнит-тесты представления буфера (s06e12).
 *
 * Собирается gcc вместе с shadow_ring.c и shadow_view.c. Проверяется то,
 * из-за чего драйверы символьных устройств чаще всего ведут себя странно:
 * частичное чтение, позиция и признак конца файла.
 */
#include <stdio.h>
#include <string.h>

#include "shadow_view.h"

static int passed;
static int failed;

static void ok(const char *what)
{
	printf("  PASS: %s\n", what);
	passed++;
}

static void no(const char *what, const char *why)
{
	printf("  FAIL: %s — %s\n", what, why);
	failed++;
}

#define CHECK(cond, what, why) do { if (cond) ok(what); else no(what, why); } while (0)

static void t_format(void)
{
	char buf[64];
	int n;

	memset(buf, 0, sizeof(buf));
	n = shadow_format_line(12, 23062, buf, sizeof(buf));
	CHECK(n > 0 && strcmp(buf, "seq=12 t=23.062\n") == 0,
	      "23062 -> «seq=12 t=23.062»", buf);

	memset(buf, 0, sizeof(buf));
	n = shadow_format_line(1, -4875, buf, sizeof(buf));
	CHECK(n > 0 && strcmp(buf, "seq=1 t=-4.875\n") == 0,
	      "-4875 -> «t=-4.875»", buf);

	memset(buf, 0, sizeof(buf));
	n = shadow_format_line(2, -875, buf, sizeof(buf));
	CHECK(n > 0 && strcmp(buf, "seq=2 t=-0.875\n") == 0,
	      "-875 -> «t=-0.875»: знак при нулевой целой части", buf);

	memset(buf, 0, sizeof(buf));
	n = shadow_format_line(3, 23005, buf, sizeof(buf));
	CHECK(n > 0 && strcmp(buf, "seq=3 t=23.005\n") == 0,
	      "23005 -> «.005», а не «.5»", buf);

	memset(buf, 0, sizeof(buf));
	n = shadow_format_line(4, 21000, buf, sizeof(buf));
	CHECK(n > 0 && strcmp(buf, "seq=4 t=21.000\n") == 0,
	      "ровный градус -> «.000»", buf);

	n = shadow_format_line(5, 23062, buf, 4);
	CHECK(n == -1, "не помещается -> -1",
	      "запись за пределы буфера в ядре — порча чужой памяти");

	n = shadow_format_line(5, 23062, NULL, 64);
	CHECK(n == -1, "NULL-буфер -> -1", "нет проверки указателя");
}

static void t_render(void)
{
	struct shadow_ring r;
	char buf[512];
	int n;

	shadow_ring_init(&r, 4);
	shadow_ring_push(&r, 21000);
	shadow_ring_push(&r, 22000);
	shadow_ring_push(&r, 23000);

	memset(buf, 0, sizeof(buf));
	n = shadow_render(&r, buf, sizeof(buf));
	CHECK(n > 0, "снимок собран", "shadow_render вернул ошибку");
	CHECK(strstr(buf, "t=21.000") && strstr(buf, "t=23.000"),
	      "в снимке все значения", buf);

	{
		const char *a = strstr(buf, "t=21.000");
		const char *c = strstr(buf, "t=23.000");
		CHECK(a && c && a < c, "порядок от старого к свежему",
		      "самое старое должно идти первым");
	}

	shadow_ring_init(&r, 4);
	n = shadow_render(&r, buf, sizeof(buf));
	CHECK(n == 0, "пустой буфер даёт пустой снимок", "ожидали длину 0");

	n = shadow_render(NULL, buf, sizeof(buf));
	CHECK(n == -1, "render(NULL) -> -1", "нет проверки указателя");
}

static void t_slice(void)
{
	const char *src = "0123456789";
	size_t len = 10;
	char dst[32];
	int n;

	memset(dst, 0, sizeof(dst));
	n = shadow_copy_slice(src, len, 0, dst, 32);
	CHECK(n == 10 && memcmp(dst, "0123456789", 10) == 0,
	      "запрос больше данных -> отдано всё", "ожидали 10 байт");

	memset(dst, 0, sizeof(dst));
	n = shadow_copy_slice(src, len, 0, dst, 4);
	CHECK(n == 4 && memcmp(dst, "0123", 4) == 0,
	      "запрос меньше данных -> отдано count", "ожидали 4 байта");

	memset(dst, 0, sizeof(dst));
	n = shadow_copy_slice(src, len, 7, dst, 32);
	CHECK(n == 3 && memcmp(dst, "789", 3) == 0,
	      "чтение с позиции отдаёт хвост", "ожидали «789»");

	n = shadow_copy_slice(src, len, 10, dst, 32);
	CHECK(n == 0, "позиция на конце -> 0 (конец файла)",
	      "ноль здесь означает EOF, а не ошибку");

	n = shadow_copy_slice(src, len, 999, dst, 32);
	CHECK(n == 0, "позиция за концом -> 0", "ожидали 0");

	n = shadow_copy_slice(src, len, 0, dst, 0);
	CHECK(n == 0, "count=0 -> 0", "ожидали 0");

	n = shadow_copy_slice(NULL, len, 0, dst, 4);
	CHECK(n == -1, "src=NULL -> -1", "нет проверки указателя");
	n = shadow_copy_slice(src, len, 0, NULL, 4);
	CHECK(n == -1, "dst=NULL -> -1", "нет проверки указателя");
}

static void t_partial_reads(void)
{
	const char *src = "seq=1 t=21.000\nseq=2 t=22.000\n";
	size_t len = strlen(src);
	char out[128];
	char chunk[8];
	size_t pos = 0, at = 0;
	int n, guard = 0;

	/* Именно так ведёт себя `head -c` и любой буферизованный читатель:
	 * маленькими кусками, пока не придёт 0. */
	memset(out, 0, sizeof(out));
	while ((n = shadow_copy_slice(src, len, pos, chunk, sizeof(chunk))) > 0) {
		if (at + (size_t)n >= sizeof(out))
			break;
		memcpy(out + at, chunk, (size_t)n);
		at += (size_t)n;
		pos += (size_t)n;
		if (++guard > 100)
			break;
	}
	CHECK(n == 0, "чтение по кускам завершается нулём",
	      "без EOF читатель зациклится навсегда");
	CHECK(at == len && memcmp(out, src, len) == 0,
	      "куски собираются в исходные данные", out);
	CHECK(guard < 100, "число вызовов конечно", "похоже на бесконечный цикл");
}

int main(void)
{
	printf("── Юнит-тесты представления (gcc, пользовательское пространство) ──\n");
	t_format();
	t_render();
	t_slice();
	t_partial_reads();
	printf("  Логика: %d passed, %d failed\n", passed, failed);
	return failed == 0 ? 0 : 1;
}
