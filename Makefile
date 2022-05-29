cargo = $(env) cargo

serve:
	mdbook serve

build:
	mdbook build

dev-deps:
	$(cargo) install mdbook
	$(cargo) install mdbook-mermaid
	$(cargo) install mdbook-linkcheck
	$(cargo) install --git https://github.com/heliaxdev/mdbook-katex.git --rev 2b37a542808a0b3cc8e799851514e145990f1e3a

.PHONY: build serve dev-deps
