# KERNEL SHADOWS — единый раннер (план §7.1)
#
# Одна команда на всё, что можно проверить механически. Цели держатся тонкими:
# вся логика живёт в tools/*.sh, Makefile только даёт им имена и порядок.
#
#   make                 то же, что make help
#   make test            unit-тесты всех серий (без root, без сети)
#   make test SEASON=season-01-shell-foundations
#   make test SERIES=s01e10
#   make test-repeat     два прогона подряд — проверка воспроизводимости (§4.3)
#   make test-locale     прогон под LC_ALL=C и чужой TZ (§4.3)
#   make test-integration тесты, которым нужен живой хост (s06e11, s06e12)
#   make links           проверка ссылок между документами (§4.9)
#   make tools           аудит forward-deps по инструментам (правило Сергея)
#   make check           links + tools + test — то, что гоняет CI
#   make progress        где я остановился (§7.5)
#   make clean-clone     приёмка на чистом клоне (§7.4)
#   make clean           убрать логи прогонов

SHELL := /usr/bin/env bash
.DEFAULT_GOAL := help

# Пробрасываются в раннер как переменные окружения.
SEASON ?=
SERIES ?=
VERBOSE ?=

export SEASON SERIES VERBOSE

.PHONY: help season-table test test-repeat test-locale test-integration links tools timeline check progress clean-clone clean

help:
	@echo "KERNEL SHADOWS — доступные цели:"
	@echo ""
	@echo "  make test                 unit-тесты всех серий (без root и сети)"
	@echo "  make test SEASON=season-01-shell-foundations"
	@echo "  make test SERIES=s01e10   одна серия по подстроке имени"
	@echo "  make test VERBOSE=1       печатать вывод упавших серий целиком"
	@echo "  make test-repeat          два прогона подряд (воспроизводимость)"
	@echo "  make test-locale          прогон под LC_ALL=C и чужим TZ"
	@echo "  make test-integration     тесты, требующие живого хоста"
	@echo "  make season-table SEASON=…  таблица серий сезона из фактов"
	@echo "  make links                проверка ссылок между документами"
	@echo "  make tools                аудит forward-deps по инструментам"
	@echo "  make timeline             сквозная хронология: логистика канона"
	@echo "  make check                links + tools + timeline + test (как в CI)"
	@echo "  make progress             где я остановился"
	@echo "  make clean-clone          приёмка на чистом клоне репозитория"
	@echo "  make clean                убрать tests/logs"
	@echo ""
	@echo "Логи прогонов: tests/logs/<сезон>.log"

test:
	@bash tools/run_tests.sh

test-repeat:
	@REPEAT=2 bash tools/run_tests.sh

test-locale:
	@echo "→ прогон под LC_ALL=C"
	@LC_ALL=C bash tools/run_tests.sh >/dev/null && echo "  LC_ALL=C: зелёно" || { echo "  LC_ALL=C: ПАДЕНИЕ"; exit 1; }
	@echo "→ прогон под TZ=Pacific/Auckland LANG=de_DE.UTF-8"
	@TZ=Pacific/Auckland LANG=de_DE.UTF-8 bash tools/run_tests.sh >/dev/null && echo "  чужая локаль и TZ: зелёно" || { echo "  чужая локаль/TZ: ПАДЕНИЕ"; exit 1; }

# Серии, которым нужен живой хост (systemd, Docker, root), выносятся сюда
# отдельной целью с явной декларацией требований в mission.md (§7.1).
# Сейчас таких две — s06e11 и s06e12: сборка модуля ядра, insmod и чтение
# /dev/shadow0. Без Linux, заголовков ядра или прав root обе сообщают SKIP,
# поэтому основной прогон (make test) от окружения не зависит.
test-integration:
	@bash tools/run_integration.sh

season-table:
	@test -n "$(SEASON)" || { echo "нужно: make season-table SEASON=season-01-shell-foundations"; exit 2; }
	@python3 tools/season_table.py $(SEASON)

links:
	@bash tools/check_links.sh

tools:
	@bash tools/check_tools.sh

# §4.6: логистику не ловит ни тест, ни линтер — только сквозная таблица.
timeline:
	@bash tools/gen_timeline.sh --check

check: links tools timeline test

progress:
	@bash tools/progress.sh

# §7.4: ловит расхождение рабочей копии с репозиторием — файлы, съеденные
# .gitignore, забытые git add, потерянные права на test.sh.
clean-clone:
	@set -euo pipefail; \
	tmp="$$(mktemp -d)"; \
	echo "→ клонирую в $$tmp"; \
	git clone --quiet . "$$tmp/clean"; \
	echo "→ make check на чистом клоне"; \
	$(MAKE) --no-print-directory -C "$$tmp/clean" check; \
	echo "→ сверяю дерево с рабочей копией (без .git и personal)"; \
	diff -rq . "$$tmp/clean" --exclude=.git --exclude=personal --exclude=tests --exclude=.progress \
	  && echo "  клон совпадает с рабочей копией" \
	  || { echo "  РАСХОЖДЕНИЕ: см. список выше"; rm -rf "$$tmp"; exit 1; }; \
	rm -rf "$$tmp"; \
	echo "Приёмка на чистом клоне пройдена."

clean:
	@rm -rf tests/logs
	@echo "tests/logs убран."
