/* unit_ring.c — юнит-тесты логики модуля (s06e11).
 *
 * Собирается обычным gcc вместе с shadow_ring.c и запускается в
 * пользовательском пространстве: ни ядра, ни root, ни перезагрузок.
 * Ровно та часть кода, где живут ошибки границ и знаков, проверяется
 * здесь — до того, как попадёт в ядро, где цена ошибки другая.
 */
#include <stdio.h>
#include <string.h>

#include "shadow_ring.h"

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

static void t_init(void)
{
	struct shadow_ring r;

	shadow_ring_init(&r, 8);
	CHECK(shadow_ring_len(&r) == 0, "после init буфер пуст",
	      "count должен быть 0");
	CHECK(r.capacity == 8, "capacity сохранена", "ожидали 8");
	CHECK(r.dropped == 0, "счётчик вытеснений обнулён", "dropped != 0");

	shadow_ring_init(&r, 0);
	CHECK(r.capacity >= 1, "capacity=0 подтянута к минимуму",
	      "нулевая ёмкость сделала бы деление на ноль");

	shadow_ring_init(&r, SHADOW_RING_MAX + 100);
	CHECK(r.capacity == SHADOW_RING_MAX, "capacity обрезана по максимуму",
	      "иначе запись уйдёт за пределы массива");
}

static void t_push_pop(void)
{
	struct shadow_ring r;
	int v;

	shadow_ring_init(&r, 4);
	CHECK(shadow_ring_pop(&r, &v) == -1, "pop из пустого возвращает -1",
	      "пустой буфер не должен отдавать значение");

	CHECK(shadow_ring_push(&r, 10) == 0, "push в свободный не вытесняет",
	      "вытеснение при неполном буфере");
	shadow_ring_push(&r, 20);
	CHECK(shadow_ring_len(&r) == 2, "длина растёт", "count не увеличился");

	CHECK(shadow_ring_pop(&r, &v) == 0 && v == 10,
	      "pop отдаёт самое СТАРОЕ", "отдано не 10");
	CHECK(shadow_ring_pop(&r, &v) == 0 && v == 20,
	      "порядок сохраняется", "отдано не 20");
	CHECK(shadow_ring_len(&r) == 0, "буфер опустел", "count != 0");
}

static void t_overflow(void)
{
	struct shadow_ring r;
	int i, v;

	shadow_ring_init(&r, 3);
	for (i = 1; i <= 5; i++)
		shadow_ring_push(&r, i * 100);

	CHECK(shadow_ring_len(&r) == 3, "длина не превышает capacity",
	      "буфер вырос — в ядре это порча памяти");
	CHECK(r.dropped == 2, "вытеснения посчитаны", "dropped != 2");
	CHECK(shadow_ring_push(&r, 600) == 1, "push в полный возвращает 1",
	      "вытеснение не отмечено");

	shadow_ring_init(&r, 3);
	for (i = 1; i <= 5; i++)
		shadow_ring_push(&r, i * 100);
	CHECK(shadow_ring_pop(&r, &v) == 0 && v == 300,
	      "после переполнения старейшее — третье", "ожидали 300");
}

static void t_peek(void)
{
	struct shadow_ring r;
	int v;

	shadow_ring_init(&r, 4);
	shadow_ring_push(&r, 11);
	shadow_ring_push(&r, 22);
	shadow_ring_push(&r, 33);

	CHECK(shadow_ring_peek(&r, 0, &v) == 0 && v == 33,
	      "peek(0) — самое свежее", "ожидали 33");
	CHECK(shadow_ring_peek(&r, 2, &v) == 0 && v == 11,
	      "peek(2) — самое старое", "ожидали 11");
	CHECK(shadow_ring_peek(&r, 3, &v) == -1,
	      "peek за пределами count возвращает -1",
	      "чтение за границей отдало значение");

	shadow_ring_init(&r, 3);
	shadow_ring_push(&r, 1);
	shadow_ring_push(&r, 2);
	shadow_ring_push(&r, 3);
	shadow_ring_push(&r, 4);
	CHECK(shadow_ring_peek(&r, 0, &v) == 0 && v == 4,
	      "peek(0) верен после оборота", "оборот головы сбил индексацию");
	CHECK(shadow_ring_peek(&r, 2, &v) == 0 && v == 2,
	      "peek(2) верен после оборота", "ожидали 2");
}

static void t_null_safe(void)
{
	int v;

	shadow_ring_init(NULL, 4);
	CHECK(shadow_ring_len(NULL) == 0, "len(NULL) не падает",
	      "разыменование NULL в ядре — паника");
	CHECK(shadow_ring_pop(NULL, &v) == -1, "pop(NULL) возвращает -1",
	      "нет проверки указателя");
	CHECK(shadow_ring_peek(NULL, 0, &v) == -1, "peek(NULL) возвращает -1",
	      "нет проверки указателя");
	ok("init(NULL) не падает");
}

static void t_clamp(void)
{
	CHECK(shadow_param_clamp(10, 4, 64) == 10, "значение внутри границ",
	      "изменено допустимое значение");
	CHECK(shadow_param_clamp(1, 4, 64) == 4, "ниже границы подтянуто",
	      "ожидали 4");
	CHECK(shadow_param_clamp(100000, 4, 64) == 64, "выше границы обрезано",
	      "параметр извне не должен выходить за буфер");
	CHECK(shadow_param_clamp(10, 64, 4) == 10, "перепутанные границы выдержаны",
	      "lo > hi ломает проверку");
	CHECK(shadow_param_clamp(-5, 4, 64) == 4, "отрицательное подтянуто",
	      "отрицательная глубина — это выход за массив");
}

static void t_scale(void)
{
	int w, f, rc;

	rc = shadow_scale_milli(23062, &w, &f);
	CHECK(rc == 0 && w == 23 && f == 62, "23062 -> 23 и 62",
	      "целочисленное деление на 1000");

	rc = shadow_scale_milli(-4875, &w, &f);
	CHECK(rc == 0 && w == -4 && f == 875, "-4875 -> -4 и 875",
	      "дробная часть должна быть неотрицательной: иначе «-4.-875»");

	rc = shadow_scale_milli(0, &w, &f);
	CHECK(rc == 0 && w == 0 && f == 0, "0 -> 0 и 0", "ноль обработан неверно");

	rc = shadow_scale_milli(-875, &w, &f);
	CHECK(rc == 1 && w == 0 && f == 875, "-875 -> знак отмечен признаком",
	      "при целой части 0 знак теряется и его надо вернуть отдельно");

	rc = shadow_scale_milli(1000, &w, &f);
	CHECK(rc == 0 && w == 1 && f == 0, "1000 -> 1 и 0", "ровный градус");

	rc = shadow_scale_milli(5, NULL, &f);
	CHECK(rc == -1, "NULL-выход даёт -1", "нет проверки указателей");
}

int main(void)
{
	printf("── Юнит-тесты логики (gcc, пользовательское пространство) ──\n");
	t_init();
	t_push_pop();
	t_overflow();
	t_peek();
	t_null_safe();
	t_clamp();
	t_scale();
	printf("  Логика: %d passed, %d failed\n", passed, failed);
	return failed == 0 ? 0 : 1;
}
