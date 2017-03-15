import ceylon.whole {
    ...
}

"Factor a product *n* of two primes *p*, *q* using Pollard’s *p - 1* method.
 This function is efficient if *p - 1* has only small prime factors."
shared Factorization factorizePollardP1(Whole n) {
    log.trace(() => "Factoring ``n``...");
    variable value k = one;
    variable value twoPowKFac = wholeNumber(2);
    
    while (true) {
        k += one;
        twoPowKFac = twoPowKFac.moduloPower { exponent = k; modulus = n; };
        value candidate = gcd(twoPowKFac - one, n);
        if (candidate != one) {
            value p = candidate;
            value q = n / candidate;
            log.debug(() => "Factored ``n`` to ``p`` * ``q`` in `` k - one `` iterations.");
            return [p, q];
        }
    }
}
