# Engines

why engines
- decouple cleanly separable functions
    - typically, engines can be upgraded as long as interface properties are still satisfied
    - separation of concerns
    - independently testable/provable for property adherence
    - all engines implement some `f : (s, {m}) -> (s', {m'})` 
        - in this way we can reason about composition
- allow for hot reloading
    - typically, engines can be hot reloaded as long as interface properties are still satisfied, messages are just queued
- allow for separation of machines
    - engines are assumed to operate within single trust domain, but otherwise can be separated
        - separate processes
        - machines across network boundary
        - etc.
    - engines can also be internally parallelised
    - logical processes, not physical ones

notes
- there is only ONE database
    - storage engine
    - this must be started first & shut down last
    - engines do have internal state
- complex compute (searching) delegated to compute engine
    - simple compute performed separately by individual engines
- all engines should be 

questions
- what about commitments
- "trust engine"
    - where to track trust preferences
    - seems like high overlap with preference engine
- randomness
    - should come from interaction engine only
    - whole system should be deterministic otherwise
    - time should also come from interaction engine