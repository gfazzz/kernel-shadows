// SPDX-License-Identifier: GPL-2.0
/* shadow_mod.c — модуль ядра узла shadow_mesh (СТАРТЕР, s06e11).
 *
 * Обвязка вокруг логики из shadow_ring.c. Здесь не должно быть ничего,
 * что стоит отлаживать перезагрузками: вся арифметика уже в shadow_ring.c
 * и проверена юнит-тестами.
 *
 * Что сделать (требования — в data/module_rules.txt, запреты — в
 * data/forbidden.txt):
 *   * подключить нужные заголовки ядра
 *   * объявить параметры depth (int) и node_id (charp) через module_param
 *     с восьмеричными правами и описанием MODULE_PARM_DESC
 *   * функция инициализации с пометкой __init:
 *       - загнать depth в допустимые границы через shadow_param_clamp:
 *         значение приходит извне, и depth=100000 — это выход за буфер
 *       - выделить память под struct shadow_ring (kzalloc)
 *       - при неудаче вернуть -ENOMEM, ничего за собой не оставив
 *       - инициализировать буфер, сообщить в журнал
 *   * функция выгрузки с пометкой __exit: освободить всё выделенное
 *   * module_init() и module_exit()
 *   * MODULE_LICENSE("GPL"), MODULE_AUTHOR, MODULE_DESCRIPTION,
 *     MODULE_VERSION
 *
 * Чего быть не должно: плавающей точки, stdio.h, malloc, printf.
 */

/* TODO: заголовки ядра */

#include "shadow_ring.h"

/* TODO: границы допустимой глубины */

/* TODO: параметры модуля */

/* TODO: указатель на буфер */

/* TODO: __init-функция */

/* TODO: __exit-функция */

/* TODO: module_init / module_exit */

/* TODO: MODULE_LICENSE и остальные метаданные */
