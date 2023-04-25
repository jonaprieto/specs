cargo = $(env) cargo
pandoc = $(env) pandoc
pip = $(env) pip
apt = $(env) apt

serve: src/macros.txt
	mdbook serve --open

build: src/macros.txt
	mdbook build

src/specs.md: src/SUMMARY.md
	(echo '!include-header paper.yaml'; grep '\.md' src/SUMMARY.md | sed 's/^- .*(\(.*.md\))/\n!include`incrementSection=0` \1/; s/^  - .*(\(.*.md\))/\n!include`incrementSection=1` \1/; s/^    - .*(\(.*.md\))/\n!include`incrementSection=2` \1/; s/^      - .*(\(.*.md\))/\n!include`incrementSection=3` \1/; s/^        - .*(\(.*.md\))/\n!include`incrementSection=4` \1/; s/^          - .*(\(.*.md\))/\n!include`incrementSection=5` \1/; s/^            - .*(\(.*.md\))/\n!include`incrementSection=6` \1/') > $@

src/macros.txt: src/macros.latex
	grep '^\\newcommand' src/macros.latex | sed 's/\\ensuremath//; s/\\newcommand\*\?{\([^}]\+\)}\(\[[0-9]\]\)\?/\1:/' > $@

tex: src/specs.md
	$(pandoc) --pdf-engine=xelatex --template=assets/llncs --defaults=defaults.yaml --resource-path=.:src -o book/anoma-specs.tex src/specs.md

pdf: src/specs.md
	$(pandoc) --pdf-engine=xelatex --template=assets/llncs --defaults=defaults.yaml --resource-path=.:src -o book/anoma-specs.pdf src/specs.md

dev-deps:
	$(cargo) install mdbook
	$(cargo) install mdbook-mermaid
	$(cargo) install mdbook-linkcheck
	$(cargo) install mdbook-katex
	$(pip) install --user pandoc-include

dev-deps-apt:
	$(apt) install texlive texlive-latex-extra texlive-fonts-extra texlive-science texlive-xetex tex-gyre librsvg2-bin pandoc

.PHONY: build serve dev-deps
