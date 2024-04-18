@frames: [
   fr(X): u_cfg [ u_state [ u_cseq [ X, REST ], VALUES ] ]
];

@value(X): (bool.false()) ;

@strictness: [
	if of_arity 3 in [0]
];


@rule/fr [if.true]: if[true[], T, F] => T where bool.true();
@rule/fr [if.false]: if[false[], T, F] => B where bool.true();

@rule/fr [decrement]:
	succ[X] => X where bool.true()
    ;

@rule [decrement]:
	succ[X] => X where bool.true()
    ;



