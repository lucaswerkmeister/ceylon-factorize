import ceylon.whole {
    ...
}
import ceylon.random {
    ...
}
import ceylon.collection {
    ...
}
import ceylon.numeric.float {
    exp,
    ln=log,
    sqrt
}

{Whole+} wholes() => object satisfies Iterable<Whole,Nothing> {
    shared actual Iterator<Whole> iterator() => object satisfies Iterator<Whole> {
        variable Whole current = -one; // start at -1 so the first next() call returns 0
        shared actual Whole next() {
            current += one;
            return current;
        }
    };
};
{Whole+} primes() => { two, *wholes().skip(3).filter((n) => !any(primes().takeWhile((p) => p^two <= n)*.divides(n))) };

Whole randomWholeOfLengthUpTo(Whole upperLimit, Integer bits, Random random = DefaultRandom()) {
    while (true) {
        value bytes = random.bytes().take((bits + 7) / 8);
        value hex = "".join { for (byte in bytes) Integer.format { byte.unsigned; radix = 16; } };
        assert (exists whole = parseWhole { hex; radix = 16; });
        if (whole < upperLimit) {
            return whole;
        }
    }
}

Integer countBits(variable Whole n) {
    variable value bits = 0;
    while (n != zero) {
        bits++;
        n = n.rightArithmeticShift(1);
    }
    return bits;
}

"Solves a system of linear equations.
 The [[map]] contains a set of numbers with their decomposition across the [[factorBase]],
 given itself as a map of index into the [[factorBase]] to exponent.
 Each number and decomposition yields one equation;
 we want to arrive at some numbers with a composition of exclusively **even** exponents,
 which we do by combining the equations as necessary
 (a system of equations over 𝔽₂)."
{<Whole->Whole>*} solve(Whole modulus, Whole[] factorBase, Map<Whole,Map<Integer,Integer>> map) {
    
    "Combining equations can result in very large exponents,
     so this class encapsulates a single factor (base and exponent),
     but does not expose the exponent (it is not directly needed).
     This allows us to perform calculations on the factor modulo *n*,
     keeping all involved numbers small.
    
     (Factors are [[Summable]] and [[Ordinal]] in the exponent;
     adding two factors means adding their exponents, that is, multiplying the factors themselves
     (only legal for factors of the same [[base]]),
     and incrementing a factor means incrementing its exponent.)"
    class Factor satisfies Summable<Factor> & Ordinal<Factor> {
        // represents an x as val = base^(x/2) if x is even, or base^(x/2)*base if x is odd
        shared Whole base;
        shared Whole val;
        shared Boolean odd;
        shared Whole modulus;
        
        shared new (Whole base, Integer exponent, Whole modulus) {
            this.base = base;
            val = base.moduloPower { exponent = wholeNumber(exponent / 2); modulus = modulus; };
            odd = !exponent.even;
            this.modulus = modulus;
        }
        new internal(Whole base, Whole val, Boolean odd, Whole modulus) {
            this.base = base;
            this.val = val;
            this.odd = odd;
            this.modulus = modulus;
        }
        
        shared actual Factor plus(Factor other) {
            assert (base == other.base);
            return Factor.internal(base, (val * other.val).modulo(modulus) * (odd && other.odd then base else one), odd != other.odd, modulus);
        }
        
        shared actual Factor successor {
            return Factor.internal(base, odd then val * base else val, !odd, modulus);
        }
        shared actual Factor predecessor {
            return Factor.internal(base, odd then val else val / base, !odd, modulus);
        }
        
        shared Boolean even => !odd;
    }
    
    Integer nVars = factorBase.size;
    MutableList<Whole->[Factor+]> lines = ArrayList<Whole->[Factor+]>();
    for (whole->exponents in map) {
        MutableList<Factor> line = ArrayList<Factor>();
        for (index in 0:nVars) {
            "check correct insertion/addition index"
            assert (line.size == index);
            assert (exists factor = factorBase[index]);
            line.add(Factor(factor, exponents[index] else 0, modulus));
        }
        assert (nonempty lineSeq = line.sequence());
        lines.add(whole->lineSeq);
    }
    
    Factor factor(Integer row, Integer column) {
        assert (exists line = lines[row],
            exists val = line.item[column]);
        return val;
    }
    
    "Swap lines *i* and *j*."
    void swap(Integer i, Integer j) {
        assert (exists l1 = lines[i],
            exists l2 = lines[j]);
        lines[i] = l2;
        lines[j] = l1;
    }
    
    "Add line *j* onto line *i*."
    void add(Integer i, Integer j) {
        assert (exists l1 = lines[i],
            exists l2 = lines[j]);
        T assertExists<T>(T? t) given T satisfies Object {
            assert (exists t);
            return t;
        }
        assert (nonempty newLine = [
                for (index in 0:nVars)
                    assertExists(l1.item[index]) + assertExists(l2.item[index])
            ]);
        lines[i] = (l1.key * l2.key).modulo(modulus) -> newLine;
    }
    
    void solveVar(Integer index) {
        // 1. ensure an odd exponent at line and column *index*
        if (factor(index, index).even) {
            for (lineIndex in (index + 1) : (lines.size - index - 1)) {
                if (!factor(lineIndex, index).even) {
                    swap(index, lineIndex);
                    break;
                }
            } else {
                // no odd exponents in the entire line, nothing more to do
                return;
            }
        }
        // 2. ensure even exponents in column *index* in all lines below line *index*
        for (lineIndex in (index + 1) : (lines.size - index - 1)) {
            if (!factor(lineIndex, index).even) {
                add(lineIndex, index);
            }
        }
    }
    
    for (index in 0:nVars) {
        solveVar(index);
    }
    "sanity check: the bottom lines should be all even"
    assert (lines.skip(nVars).every((evenLine) => evenLine.item.every(Factor.even)));
    return {
        for (evenLine in lines.skip(nVars))
            evenLine.key -> product(evenLine.item*.val).modulo(modulus)
    };
}

"Factor a product *n* of two primes *p*, *q* using Dixon’s method."
shared Factorization factorizeDixon(Whole n) {
    log.trace(() => "Factoring ``n``...");
    value nBits = countBits(n);
    value factorBaseLimit = wholeNumber(exp(0.5 * sqrt(nBits * ln(nBits.float))).integer);
    value factorBase = primes().takeWhile((p) => p <= factorBaseLimit).sequence();
    log.trace(() => "Chose factor base of size ``factorBase.size``.");
    "Map from *m* to map from base index (into [[factorBase]]) to exponent."
    MutableMap<Whole,MutableMap<Integer,Integer>> ms = HashMap<Whole,MutableMap<Integer,Integer>>();
    
    while (ms.size < factorBase.size+10) {
        value m = randomWholeOfLengthUpTo { upperLimit = n; bits = nBits; };
        if (m in ms.keys || m.zero) {
            continue;
        }
        variable value m2 = m.moduloPower { exponent = two; modulus = n; };
        for (i->p in factorBase.indexed) {
            while (p.divides(m2)) {
                value exponents = ms[m] else HashMap<Integer,Integer>();
                exponents[i] = exponents[i]?.plus(1) else 1;
                m2 = m2 / p;
                ms[m] = exponents;
            }
            if (m2 == one) {
                break;
            }
        } else {
            // did not decompose over factorBase
            ms.remove(m);
        }
        
        if (exists exponents = ms[m]) {
            "sanity check"
            assert (m.moduloPower { exponent = two; modulus = n; } == product {
                    one, // guarantee nonempty stream
                    for (i->p in factorBase.indexed)
                        p ^ wholeNumber(exponents[i] else 0)
                });
        }
    }
    log.trace(() => "Found values of m with decomposition over the factor base.");
    
    value candidates = solve(n, factorBase, ms);
    value realCandidates = candidates.filter((m->m_) => m!=m_ && m != n-m_);
    assert (exists solutionCandidate = realCandidates.first);
    value p = gcd(n, solutionCandidate.key + solutionCandidate.item);
    value q = n / p;
    log.debug(() => "Factored ``n`` to ``p`` * ``q``.");
    return [p, q];
}
