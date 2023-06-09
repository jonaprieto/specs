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
GIT ?= git

DOT := $(shell git ls-files | grep '\.dot$$')
DOT_SVG := $(patsubst %.dot,%.dot.svg,$(DOT))

all: build pdf

serve: src/macros.txt dot
	mdbook serve --open

build: src/macros.txt dot
	mdbook build

src/specs.md: src/SUMMARY.md
	(echo '!include-header paper.yaml'; grep '\.md' src/SUMMARY.md | sed 's/^- .*(\(.*.md\))/\n!include`incrementSection=0` \1/; s/^  - .*(\(.*.md\))/\n!include`incrementSection=1` \1/; s/^    - .*(\(.*.md\))/\n!include`incrementSection=2` \1/; s/^      - .*(\(.*.md\))/\n!include`incrementSection=3` \1/; s/^        - .*(\(.*.md\))/\n!include`incrementSection=4` \1/; s/^          - .*(\(.*.md\))/\n!include`incrementSection=5` \1/; s/^            - .*(\(.*.md\))/\n!include`incrementSection=6` \1/') > $@

src/macros.txt: src/macros.latex
	$(GREP) '^\\newcommand' src/macros.latex | $(SED) 's/\\ensuremath//; s/\\newcommand\*\?{\([^}]\+\)}\(\[[0-9]\]\)\?/\1:/' > $@

tex: src/specs.md dot
	cur_branch="`git branch --show-current`"; \
	tmp_branch="tmp/`date +%s`"; \
	$(GIT) checkout -b "$$tmp_branch"; \
	for f in `$(GIT) ls-files | $(GREP) '\.md$$'`; do \
	  $(SED) -i 's/{{#include *\(.*\?\)}}/!include "\1"/' "$$f"; \
	done; \
	$(PANDOC) --pdf-engine=xelatex --template=assets/llncs --defaults=defaults.yaml --resource-path=.:src -o book/anoma-specs.tex src/specs.md; \
	if [ -n "$$cur_branch" ]; then \
	  $(GIT) checkout "$$cur_branch"; \
	  $(GIT) branch -D "$$tmp_branch"; \
	fi

pdf: src/specs.md dot
	cur_branch="`git branch --show-current`"; \
	tmp_branch="tmp/`date +%s`"; \
	$(GIT) checkout -b "$$tmp_branch"; \
	for f in `$(GIT) ls-files | $(GREP) '\.md$$'`; do \
	  $(SED) -i 's/{{#include *\(.*\?\)}}/!include "\1"/' "$$f"; \
	done; \
	$(PANDOC) --pdf-engine=xelatex --template=assets/llncs --defaults=defaults.yaml --resource-path=.:src -o book/anoma-specs.pdf src/specs.md; \
	if [ -n "$$cur_branch" ]; then \
	  $(GIT) checkout "$$cur_branch"; \
	  $(GIT) branch -D "$$tmp_branch"; \
	fi

dot: $(DOT_SVG)

%.dot.svg: %.dot
	dot -Tsvg $< > $@

dev-deps:
	$(CARGO) install mdbook
	$(CARGO) install mdbook-linkcheck
	$(CARGO) install mdbook-katex
	$(PIP) install --user pandoc-include

dev-deps-apt:
	$(APT) install texlive texlive-latex-extra texlive-fonts-extra texlive-science texlive-xetex tex-gyre librsvg2-bin pandoc graphviz

.PHONY: all build serve pdf dev-deps dev-deps-apt
