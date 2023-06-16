CARGO ?= cargo
PANDOC ?= pandoc
PIP ?= pip
APT ?= apt
GREP ?= grep
ifneq (,$(shell which gsed 2>/dev/null))
SED ?= gsed
else
SED ?= sed
endif
FIND ?= find

OUT ?= book

FORMAT := commonmark_x

DOT := $(shell find src -name '*.dot')
DOT_SVG := $(patsubst %.dot,%.dot.svg,$(DOT))

KATEX_URL := https://cdn.jsdelivr.net/npm/katex@0.12.0/dist

all: build pdf

serve: src/macros.txt dot
	mdbook serve --open

build: src/macros.txt dot
	mdbook build

serve-local: src/macros.txt dot dl-katex
	MDBOOK_preprocessor__katex__no_css=true \
	MDBOOK_output__html__additional_css='["assets/custom.css", "assets/katex.min.css"]' \
	mdbook serve --open

build-local: src/macros.txt dot dl-katex
	MDBOOK_preprocessor__katex__no_css=true \
	MDBOOK_output__html__additional_css='["assets/custom.css", "assets/katex.min.css"]' \
	mdbook build

src/specs.md: src/SUMMARY.md
	(echo '!include-header paper.yaml'; grep '\.md' src/SUMMARY.md | sed 's/^- .*(\(.*.md\))/\n!include`format="$(FORMAT)",incrementSection=0` \1/; s/^  - .*(\(.*.md\))/\n!include`format="$(FORMAT)",incrementSection=1` \1/; s/^    - .*(\(.*.md\))/\n!include`format="$(FORMAT)",incrementSection=2` \1/; s/^      - .*(\(.*.md\))/\n!include`format="$(FORMAT)",incrementSection=3` \1/; s/^        - .*(\(.*.md\))/\n!include`format="$(FORMAT)",incrementSection=4` \1/; s/^          - .*(\(.*.md\))/\n!include`format="$(FORMAT)",incrementSection=5` \1/; s/^            - .*(\(.*.md\))/\n!include`format="$(FORMAT)",incrementSection=6` \1/') > $@

src/macros.txt: src/macros.tex
	$(GREP) '^\\newcommand' src/macros.tex | $(SED) 's/\\ensuremath//; s/\\newcommand\*\?{\([^}]\+\)}\(\[[0-9]\]\)\?/\1:/' > $@

tex: src/specs.md dot
	mkdir -p $(OUT); \
	build="build.`date +%s`"; \
	mkdir "$$build"; \
	cp -a src "$$build"; \
	(cd "$$build"; \
	 $(SED) -i 's/{{#include *\([^}]\+\):\([^}]\+\)}}/!include\`format="$(FORMAT)", snippetStart="<!-- ANCHOR: \2 -->", snippetEnd="<!-- ANCHOR_END: \2 -->"\` "\1"/; s/\[\([^]]\+\)\](\([^)]\+\.md\)#\([^)]\+\))/[\1](#\3)/g; s/{{#include *\([^:}]\+\)}}/!include\`format="$(FORMAT)"\` "\1"/; s/\[\([^]]\+\)\](\([^)]\+\.md\)#\([^)]\+\))/[\1](#\3)/g' `$(FIND) src -name '*.md'`; \
	 $(PANDOC) --pdf-engine=xelatex --template=../assets/llncs -H src/header.tex --defaults=../defaults.yaml --resource-path=.:src --from=$(FORMAT) -o ../$(OUT)/anoma-specs.tex src/specs.md); \
	if [ "$(KEEP_BUILD)" != 1 ]; then rm -rf "$$build"; fi

pdf: src/specs.md dot
	mkdir -p $(OUT); \
	build="build.`date +%s`"; \
	mkdir "$$build"; \
	cp -a src "$$build"; \
	(cd "$$build"; \
	 $(SED) -i 's/{{#include *\([^}]\+\):\([^}]\+\)}}/!include\`format="$(FORMAT)", snippetStart="<!-- ANCHOR: \2 -->", snippetEnd="<!-- ANCHOR_END: \2 -->"\` "\1"/; s/\[\([^]]\+\)\](\([^)]\+\.md\)#\([^)]\+\))/[\1](#\3)/g; s/{{#include *\([^:}]\+\)}}/!include\`format="$(FORMAT)"\` "\1"/; s/\[\([^]]\+\)\](\([^)]\+\.md\)#\([^)]\+\))/[\1](#\3)/g' `$(FIND) src -name '*.md'`; \
	 $(PANDOC) --pdf-engine=xelatex --template=../assets/llncs -H src/header.tex --defaults=../defaults.yaml --resource-path=.:src --from=$(FORMAT) -o ../$(OUT)/anoma-specs.pdf src/specs.md); \
	if [ "$(KEEP_BUILD)" != 1 ]; then rm -rf "$$build"; fi

dot: $(DOT_SVG)

%.dot.svg: %.dot
	dot -Tsvg $< > $@

dev-deps:
	$(CARGO) install mdbook
	$(CARGO) install mdbook-linkcheck
	$(CARGO) install mdbook-katex
	$(PIP) install --user pandoc-include

dev-deps-apt:
	$(APT) install curl jq pandoc graphviz texlive texlive-latex-extra texlive-fonts-extra texlive-science texlive-xetex tex-gyre librsvg2-bin

dl-katex: assets/katex.min.css

assets/katex.min.css:
	cd assets; \
	echo "katex.min.css"; \
	curl -sO "$(KATEX_URL)/katex.min.css"; \
	mkdir -p fonts; \
	cd fonts; \
	for path in `grep -o 'fonts/\([^)]\+\)' ../katex.min.css`; do \
	  echo "$$path"; \
	  echo curl -sO "$(KATEX_URL)/$$path"; \
	done

.PHONY: all build serve pdf dev-deps dev-deps-apt
