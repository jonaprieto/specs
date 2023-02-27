cargo = $(env) cargo
pandoc = $(env) pandoc

serve:
	mdbook serve --open

build:
	mdbook build

pdf:
	$(pandoc) --pdf-engine=xelatex --template=assets/llncs -o build/paper.pdf --number-sections src/paper.md

dev-deps:
	$(cargo) install mdbook
	$(cargo) install mdbook-mermaid
	$(cargo) install mdbook-linkcheck
	$(cargo) install --git https://github.com/heliaxdev/mdbook-katex.git

.PHONY: build serve dev-deps
