.. _lambda-case:

Lambda-case
-----------

GHC accepts expressions of the form ::

      \case { p1 -> e1; ...; pN -> eN }

which is equivalent to ::

      \freshName -> case freshName of { p1 -> e1; ...; pN -> eN }

It also accepts expressions with multiple scrutinees (see GHC proposal
`#302 <https://github.com/ghc-proposals/ghc-proposals/blob/master/proposals/0302-cases.rst>`_)
of the form ::

      \cases { p11 ... pM1 -> e1; ...; p1N ... pMN -> eN }

which is equivalent to a function defined as ::

      f p11 ... pM1 = e1
      ...
      f p1N ... pMN = eN


Note that both ``\case`` and ``\cases`` start a layout, so you can write ::

      \case
        p1 -> e1
        ...
        pN -> eN

