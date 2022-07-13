cargo = $(env) cargo

serve:
	mdbook serve

build:
	mdbook build

# these versions are guaranteed to be able to build the specs mdbook
ci-deps:
	$(cargo) install mdbook --version 0.4.19
	$(cargo) install mdbook-mermaid --version 0.11.0
	$(cargo) install mdbook-linkcheck --version 0.7.6
	$(cargo) install --git https://github.com/heliaxdev/mdbook-katex.git --rev 2b37a542808a0b3cc8e799851514e145990f1e3a

dev-deps:
	$(cargo) install mdbook
	$(cargo) install mdbook-mermaid
	$(cargo) install mdbook-linkcheck
	$(cargo) install --git https://github.com/heliaxdev/mdbook-katex.git

.PHONY: build serve dev-deps
