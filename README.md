`de.lucaswerkmeister.ceylon.factorize`
======================================

This module contains implementations of two integer factorization algorithms.
I wrote them together with a friend to better understand the algorithms,
which we had been studying for university.
The implementation is not perfect, it’s extremely slow
(GNU coreutils `factor`, for example, has it beat by lengths),
and it has bugs
(known and unresolved: factoring 1234 with Dixon’s algorithm fails,
since it appears that finding new 𝑚²=𝑚′² pairs with 𝑚′ ∉ { 𝑚, −𝑚 } is very unlikely,
and so the ten pairs we find are unsuitable for finding 𝑝=gcd(𝑛,𝑚+𝑚′)).
**Do not use.**

License
-------

The content of this repository is released under the LGPLv3
as provided in the `LICENSE` file that accompanied this code.
