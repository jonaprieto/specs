cargo = $(env) cargo

serve:
	mdbook serve --open

build:
	mdbook build

dev-deps:
	$(cargo) install mdbook
	$(cargo) install mdbook-mermaid
	$(cargo) install mdbook-linkcheck
	$(cargo) install mdbook-pdf
	$(cargo) install --git https://github.com/heliaxdev/mdbook-katex.git

.PHONY: build serve dev-deps
