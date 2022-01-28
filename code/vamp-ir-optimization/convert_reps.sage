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

R = PolynomialRing(field, 'x,a,b,c,d,e,f,g')
R.inject_variables()

target_constraints_met = lambda system : all([poly.degree() <= 2 for poly in system])

num_variables_in_gb = lambda gb : len(set.union(*[set(p.variables()) for p in gb]))

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
    print(f"mean #polys in GB:      {mean(lens_of_gbs).n(digits=3)}")
    print(f"#GBs in Fan (cnstrd):   {len(gbs_cnstrd)}")
    print(f"min #polys (cnstrd):    {min(lens_of_gbs_cnstrd)}")
    print(f"max #polys (cnstrd):    {max(lens_of_gbs_cnstrd)}")


print(" ================")
print(" == 3 ≤ x < 12 ==")
print(" ================")

target_poly = prod([x-i for i in range(3,12)])
print(f"Target polynomial: {target_poly}")

print()
print(" == Gröbner Fan of 'roots of nullifier' ==")

polys0 = [
    (x- 3) * (x- 4) - a,
    (x- 5) * a - b,
    (x- 6) * b - c,
    (x- 7) * c - d,
    (x- 8) * d - e,
    (x- 9) * e - f,
    (x-10) * f - g,
    (x-11) * g,
]
I0 = Ideal(polys0)
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
    # ((1-a) * (1-b) * (1-c)) + ((1-a) * (1-b) * (1-d)) + (a * b),
    # the following is weird:
    # ((1-a) + (1-b) + (1-c)) * ((1-a) + (1-b) + (1-d)) * (a + b),

    # CNF
    # (a or not b) and (not a or b) and (a or not c or not d)
    (a + 1-b) * (1-a + b) - e,
    e * (a + 1-c + 1-d)
    # the following is weird:
    # (a * (1-b)) + ((1-a) * b) + (a * (1-c) * (1-d))
]
I1 = Ideal(polys1)
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
I2 = Ideal(polys2)
print_gb_fan_stats(I2)

# == comparison of above fans & gbs

elim_ideal_0 = I0.elimination_ideal(R.gens()[1:]).groebner_basis()
elim_ideal_1 = I1.elimination_ideal(R.gens()[1:]).groebner_basis()
elim_ideal_2 = I2.elimination_ideal(R.gens()[1:]).groebner_basis()

print()
print(f"Elimination Ideal I0: {elim_ideal_0}")
print(f"Elimination Ideal I1: {elim_ideal_1}")
print(f"Elimination Ideal I2: {elim_ideal_2}")
print(f"Elim ideals are same: {elim_ideal_0 == elim_ideal_1 and elim_ideal_1 == elim_ideal_2}")

f = elim_ideal_0[0].univariate_polynomial()

print()
print(f"Roots of that poly:   {sorted([r[0] for r in f.roots()])}")
