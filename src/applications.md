> TODO: Ignore this section for now.

# Applications

Applications consist of a set of related resource logics. The state of any particular application is sharded across the system, and may be under many different controllers. Applications, of course, can restrict themselves to specific sets or paths of controllers with appropriate checks in the predicates, but by default this model is designed to provide a clean separation of application design and security choices, such that application developers can choose the data model but users can choose the security assumptions.

It is important to note that the abstraction of an `Application` is "virtual" - applications are not "deployed" or tracked in any sort of registry - rather, they are content-addressed by the logics particular resources. An `Application` can be said to exist by virtue of the existence resources referencing it, and if those resources are completely consumed it no longer exists (except in history).

- Explain how interfaces might work
- List the different applications