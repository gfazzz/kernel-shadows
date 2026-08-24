// SPDX-License-Identifier: GPL-2.0
/* shadow_dev.c — символьное устройство /dev/shadow0 (СТАРТЕР, s06e12).
 *
 * Финал сезона: измерения из буфера ядра становятся доступны обычными
 * open/read/close. Вся арифметика уже написана и проверена — в
 * shadow_ring.c (s06e11) и shadow_view.c. Здесь только граница.
 *
 * Что сделать (требования — в data/dev_rules.txt, парные вызовы —
 * в data/pairs.txt, запреты — в data/forbidden.txt):
 *
 *   * таблица struct file_operations: .owner = THIS_MODULE, .open,
 *     .read, .release
 *   * shadow_read():
 *       - взять блокировку: читателей может быть несколько
 *       - подготовить снимок текста через shadow_render()
 *       - спросить у shadow_copy_slice(), сколько отдать с позиции *ppos
 *       - 0 означает конец файла — вернуть 0
 *       - отдать данные через copy_to_user(); указатель из
 *         пользовательского пространства НЕЛЬЗЯ разыменовывать напрямую
 *       - неудача copy_to_user -> -EFAULT
 *       - продвинуть *ppos на число отданных байт
 *       - снять блокировку на КАЖДОМ пути выхода
 *   * инициализация: kzalloc, alloc_chrdev_region, cdev_add,
 *     class_create, device_create — и лестница меток err_*, которая
 *     откатывает ровно то, что успели взять
 *   * выгрузка: всё то же в обратном порядке
 *   * MODULE_LICENSE("GPL") и остальные метаданные
 *
 * Чего быть не должно: memcpy в пользовательский буфер, sprintf без
 * ограничения длины, плавающей точки, malloc.
 */

/* TODO: заголовки ядра */

#include "shadow_ring.h"
#include "shadow_view.h"

/* TODO: имена, границы, размер текстового буфера */

/* TODO: параметр depth */

/* TODO: состояние модуля: ring, text, блокировка, devt, cdev, class */

/* TODO: shadow_open / shadow_release */

/* TODO: shadow_read */

/* TODO: struct file_operations */

/* TODO: __init с лестницей отката */

/* TODO: __exit */

/* TODO: module_init / module_exit / метаданные */
