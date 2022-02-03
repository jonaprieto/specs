# import fgb_sage

'''
The Question.
Given
    • set of constraints c,     e.g., generators of the output ideal have to be at most degree 2
    • target function ω,        e.g., the total number of variables in the ring
    • ideal I,                  e.g., the ideal generated by the polynomial representing a range check
find set of polynomials f_0, …, f_k such that
    • c holds ∀f_i
    • ω(f_0, …, f_k) is minimized
    • I is the elimination ideal of <f_i> when eliminating vars(<f_i>) - vars(I)

Additional Question:
In general, can we know the minimum that ω can take for a given I, even though finding the corresponding f_i is impossible / infeasible?

Intermediate Questions:
• Is there a better way than Approach 3?
• Is there a better way than Approach 3 for particular input shapes / problems?
• How can we frame Approach 2 (binary decomposition) in a more mathematical / algebraic way?
• For Approach 3, how can we identify if / are there different choices of which reduction to apply that are equivalent (e.g., commutative, or something)?
• Are the ideals that we're dealing with radical?
'''

p = 17
field = GF(p)

variable_names = ['x', 'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l']
R = PolynomialRing(field, variable_names)
R.inject_variables()

target_degree = 3
target_constraints_met = lambda system : all([poly.degree() <= target_degree for poly in system])

num_variables_in_gb = lambda gb : len(set.union(*[set(p.variables()) for p in gb]))

trim_variables = lambda I : I.change_ring(PolynomialRing(field, variable_names[:num_variables_in_gb(I.basis)]))

def print_gb_fan_stats(I):
    gb_fan = I.groebner_fan()
    gbs = gb_fan.reduced_groebner_bases()
    gbs_cnstrd = [gb for gb in gbs if target_constraints_met(gb)]
    lens_of_gbs = [len(gb) for gb in gbs]
    lens_of_gbs_cnstrd = [len(gb) for gb in gbs_cnstrd]
    nums_of_vars = [num_variables_in_gb(gb) for gb in gbs]
    if min(nums_of_vars) != max(nums_of_vars):
        print(f" !!! something is weird with the number of vars! Start your investigation…")
    print(f"sys meets constraints:  {target_constraints_met(I.basis)}")
    print(f"input sys is GB:        {I.basis_is_groebner()}")
    print(f"#polys in input system: {len(I.basis)}")
    print(f"#vars in input system:  {nums_of_vars[0]}")
    print(f"#GBs in Fan:            {len(gbs)}")
    print(f"min #polys in GB:       {min(lens_of_gbs)}")
    print(f"max #polys in GB:       {max(lens_of_gbs)}")
    print(f"#GBs in Fan (constrained):   {len(gbs_cnstrd)}")
    print(f"min #polys (constrained):    {min(lens_of_gbs_cnstrd, default='N/A')}")
    print(f"max #polys (constrained):    {max(lens_of_gbs_cnstrd, default='N/A')}")
    print(f"Dimension of I:         {I.dimension()}")


print(" ================")
print(" == 3 ≤ x < 12 ==")
print(" ================")

target_roots = range(3,12)
target_poly = prod([x-i for i in target_roots])
print(f"Target polynomial: {target_poly}")

print()
print(" == Gröbner Fan of 'roots of nullifier' ==")

curr_var = R.gens()[1] # a
initial_poly = prod([R.gens()[0]-i for i in target_roots[:target_degree]]) - curr_var
polys0 = [initial_poly]
root_idx_for_next_polys = range(target_degree, len(target_roots), target_degree - 1)
num_next_polys = len(root_idx_for_next_polys)
for var_idx, root_idx in zip(range(2, num_next_polys + 2), root_idx_for_next_polys):
    curr_var = R.gens()[var_idx]
    prev_var = R.gens()[var_idx - 1]
    next_poly = prod([R.gens()[0]-i for i in target_roots[root_idx: root_idx + target_degree - 1]]) * prev_var - curr_var
    polys0 += [next_poly]
polys0[-1] += curr_var # don't introduce new variable for the last polynomial
I0 = trim_variables(Ideal(polys0))
print_gb_fan_stats(I0)

print()
print(" == Gröbner Fan of 'binary decomposition' ==")

polys1 = [
    # a, b, c, and d are bits
    (a-0) * (a-1),
    (b-0) * (b-1),
    (c-0) * (c-1),
    (d-0) * (d-1),

    # x is the binary decomposition of a, b, c, d
    2^3*a + 2^2*b + 2^1*c + 2^0*d - x,

    #  x  a b c d  f
    #  0  0 0 0 0
    #  1  0 0 0 1
    #  2  0 0 1 0
    #  3  0 0 1 1  0
    #  4  0 1 0 0  0
    #  5  0 1 0 1  0
    #  6  0 1 1 0  0
    #  7  0 1 1 1  0
    #  8  1 0 0 0  0
    #  9  1 0 0 1  0
    # 10  1 0 1 0  0
    # 11  1 0 1 1  0
    # 12  1 1 0 0
    # 13  1 1 0 1
    # 14  1 1 1 0
    # 15  1 1 1 1

    # DNF
    # (not a and not b and not c) or (not a and not b and not d) or (a and b)
    (e * (1-c)) + (e * (1-d)) + (a * b),
    (1-a) * (1-b) - e,

    # CNF
    # (a or not b) and (not a or b) and (a or not c or not d)
    # (a + 1-b) * (1-a + b) - e,
    # e * (a + 1-c + 1-d)
]
I1 = trim_variables(Ideal(polys1))
print_gb_fan_stats(I1)

print()
print(" == Gröbner Fan using reduction by square polynomials ==")

reductor_0 = x^2 - a
reductor_1 = a^2 - b
reductor_2 = b^2 - c
reduced_poly_0 = target_poly.reduce([reductor_0])
reduced_poly_1 = reduced_poly_0.reduce([reductor_1])
reduced_poly_2 = reduced_poly_1.reduce([reductor_2])

polys2 = [reduced_poly_2, reductor_0, reductor_1, reductor_2]
I2 = trim_variables(Ideal(polys2))
print_gb_fan_stats(I2)

print()
print(" == Unification attempt ==")

reductors = [
    (a-0)*(a-1),
    (b-0)*(b-1),
    (c-0)*(c-1),
    (d-0)*(d-1),
    2^3*a + 2^2*b + 2^1*c + 2^0*d - x,
]

polys3 = [target_poly] + reductors
I3 = trim_variables(Ideal(polys3))
I3 = Ideal(I3.groebner_basis())
print_gb_fan_stats(I3)

print()
print(" === Unification attempt: Is this a normal form?")
for p in [p for p in I3.basis if not (p in polys3 or -p in polys3)]:
    print(p)

print()
print(" == Variety")
for v in sorted(I3.variety(), key=lambda v: v['x']):
    print(v)

# == comparison of above fans & gbs

elim_ideal_0 = I0.elimination_ideal(I0.ring().gens()[1:]).groebner_basis()
elim_ideal_1 = I1.elimination_ideal(I1.ring().gens()[1:]).groebner_basis()
elim_ideal_2 = I2.elimination_ideal(I2.ring().gens()[1:]).groebner_basis()
elim_ideal_3 = I3.elimination_ideal(I3.ring().gens()[1:]).groebner_basis()

print()
print(f"Elimination Ideal I0: {elim_ideal_0}")
print(f"Elimination Ideal I1: {elim_ideal_1}")
print(f"Elimination Ideal I2: {elim_ideal_2}")
print(f"Elimination Ideal I2: {elim_ideal_3}")
print(f"Elim ideals are same: {elim_ideal_0 == elim_ideal_1 and elim_ideal_0 == elim_ideal_2 and elim_ideal_0 == elim_ideal_3}")

f = elim_ideal_0[0].univariate_polynomial()

print()
print(f"Roots of that poly:   {sorted([r[0] for r in f.roots()])}")
