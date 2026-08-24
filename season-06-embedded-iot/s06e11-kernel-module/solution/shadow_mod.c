// SPDX-License-Identifier: GPL-2.0
/* shadow_mod.c — модуль ядра узла shadow_mesh (ЭТАЛОН, s06e11).
 *
 * Обвязка вокруг проверенной логики из shadow_ring.c: точки входа и
 * выхода, параметры, сообщения в журнал ядра. Ничего, что стоит
 * отлаживать перезагрузками, здесь нет — оно уже проверено юнит-тестами.
 */

#include <linux/init.h>
#include <linux/kernel.h>
#include <linux/module.h>
#include <linux/moduleparam.h>
#include <linux/slab.h>

#include "shadow_ring.h"

#define SHADOW_DEPTH_MIN 4
#define SHADOW_DEPTH_MAX SHADOW_RING_MAX

/* Параметры модуля. Права 0444: файл в /sys/module/shadow_mod/parameters/
 * доступен на чтение всем и не меняется на ходу — глубину буфера нельзя
 * поменять у работающего модуля, не переписав его логику под блокировки.
 */
static int depth = 16;
module_param(depth, int, 0444);
MODULE_PARM_DESC(depth, "глубина кольцевого буфера измерений (4..64)");

static char *node_id = "shadow-node-00";
module_param(node_id, charp, 0444);
MODULE_PARM_DESC(node_id, "идентификатор узла для сообщений в журнале");

static struct shadow_ring *ring;

static int __init shadow_mod_init(void)
{
	int effective;

	/* Параметр приходит от того, кто загружает модуль, то есть извне.
	 * Доверять ему нельзя: depth=100000 — это выход за буфер. */
	effective = shadow_param_clamp(depth, SHADOW_DEPTH_MIN, SHADOW_DEPTH_MAX);
	if (effective != depth)
		pr_warn("shadow_mod: depth=%d вне [%d, %d], беру %d\n",
			depth, SHADOW_DEPTH_MIN, SHADOW_DEPTH_MAX, effective);

	ring = kzalloc(sizeof(*ring), GFP_KERNEL);
	if (!ring) {
		pr_err("shadow_mod: не хватило памяти под буфер\n");
		return -ENOMEM;
	}

	shadow_ring_init(ring, (unsigned int)effective);

	pr_info("shadow_mod: загружен, узел %s, глубина %d\n",
		node_id, effective);
	return 0;
}

static void __exit shadow_mod_exit(void)
{
	/* Всё, что выделено при загрузке, освобождается здесь. В ядре нет
	 * сборщика мусора: незакрытый ресурс живёт до перезагрузки машины. */
	if (ring) {
		pr_info("shadow_mod: выгружен, вытеснено значений: %lu\n",
			ring->dropped);
		kfree(ring);
		ring = NULL;
	}
}

module_init(shadow_mod_init);
module_exit(shadow_mod_exit);

MODULE_LICENSE("GPL");
MODULE_AUTHOR("shadow_mesh");
MODULE_DESCRIPTION("кольцевой буфер измерений узла shadow_mesh");
MODULE_VERSION("1.0");
