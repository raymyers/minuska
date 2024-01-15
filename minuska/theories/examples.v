From Coq.Logic Require Import ProofIrrelevance.


From Minuska Require Import
    prelude
    spec_syntax
    spec_semantics
    string_variables
    builtins
    flattened
    naive_interpreter
    default_static_model
    notations
    frontend
.

Fixpoint interp_loop
    {Σ : StaticModel}
    (interp : GroundTerm -> option GroundTerm)
    (fuel : nat)
    (g : GroundTerm)
    : (nat*GroundTerm)
:=
match fuel with
| 0 => (0,g)
| S fuel' =>
    match interp g with
    | None => (fuel', g)
    | Some g' => interp_loop interp fuel' g'
    end
end
.

Module example_1.

    (*
    Import empty_builtin.*)
    #[local]
    Instance Σ : StaticModel :=
        default_model (empty_builtin.β)
    .
    
    Definition X : variable := "X".

    Definition cfg {_br : BasicResolver} := (apply_symbol "cfg").
    Arguments cfg {_br} _%rs.

    Definition s {_br : BasicResolver} := (apply_symbol "s").
    Arguments s {_br} _%rs.

    Definition Decls : list Declaration := [
        decl_rule (
            rule ["my_rule"]:
                cfg [ s [ s [ ($X) ] ] ]
                ~> cfg [ $X ]
        )
    ].

    Definition Γ : FlattenedRewritingTheory
        := Eval vm_compute in (to_theory (process_declarations (Decls))).

    Definition interp :=
        naive_interpreter Γ
    .

    Fixpoint interp_loop
        (fuel : nat)
        (g : GroundTerm)
        : (nat*GroundTerm)
    :=
    match fuel with
    | 0 => (0,g)
    | S fuel' =>
        match interp g with
        | None => (fuel', g)
        | Some g' => interp_loop fuel' g'
        end
    end
    .

    Fixpoint my_number' (n : nat) : AppliedOperator' symbol builtin_value  :=
    match n with
    | 0 => ao_operator "0"
    | S n' => ao_app_ao (ao_operator "s") (my_number' n')
    end
    .

    Fixpoint my_number'_inv
        (g : AppliedOperator' symbol builtin_value)
        : option nat
    :=
    match g with
    | ao_operator s => if bool_decide (s = "0") then Some 0 else None
    | ao_app_ao s arg =>
        match s with
        | ao_operator s => if bool_decide (s = "s") then
            n ← my_number'_inv arg;
            Some (S n)
        else None
        | _ => None
        end
    | ao_app_operand _ _ => None
    end
    .

    Definition my_number (n : nat) : GroundTerm :=
        aoo_app (ao_app_ao (ao_operator "cfg") (my_number' n))
    .

    Definition my_number_inv (g : GroundTerm) : option nat
    :=
    match g with
    | aoo_app (ao_app_ao (ao_operator "cfg") g') => my_number'_inv g'
    | _ => None
    end
    .

    Lemma my_number_inversion' : forall n,
        my_number'_inv (my_number' n) = Some n
    .
    Proof.
        induction n; simpl.
        { reflexivity. }
        {
            rewrite bind_Some.
            exists n.
            auto.
        }
    Qed.

    Lemma my_number_inversion : forall n,
        my_number_inv (my_number n) = Some n
    .
    Proof.
        intros n. simpl. apply my_number_inversion'.
    Qed.

    Compute (my_number 2).
    Compute (interp (my_number 2)).

    Definition interp_loop_number fuel := 
        fun n =>
        let fg' := ((interp_loop fuel) ∘ my_number) n in
        my_number_inv fg'.2
    .

End example_1.


Module two_counters.

    Import empty_builtin.

    #[local]
    Instance Σ : StaticModel := default_model (empty_builtin.β).


    Definition M : variable := "M".
    Definition N : variable := "N".
    
    Definition cfg {_br : BasicResolver} := (apply_symbol "cfg").
    Arguments cfg {_br} _%rs.

    Definition state {_br : BasicResolver} := (apply_symbol "state").
    Arguments state {_br} _%rs.

    Definition s {_br : BasicResolver} := (apply_symbol "s").
    Arguments s {_br} _%rs.

    Definition Γ : FlattenedRewritingTheory :=
    Eval vm_compute in (to_theory (process_declarations ([
        decl_rule (
            rule ["my-rule"]:
                cfg [ state [ s [ $M ], $N ] ]
            ~> cfg [ state [ $M, s [ $N ]  ] ]
        )
    ]))).
    

    Definition interp :=
        naive_interpreter Γ
    .

    Definition pair_to_state (mn : nat*nat) : GroundTerm :=
        aoo_app (ao_app_ao (ao_operator "cfg")
        (
            ao_app_ao
                (
                ao_app_ao (ao_operator "state")
                    (example_1.my_number' mn.1)
                )
                (example_1.my_number' mn.2)
        )
        )
    .

    Definition state_to_pair (g : GroundTerm) : option (nat*nat) :=
    match g with
    | aoo_app (ao_app_ao (ao_operator "cfg")
        (ao_app_ao (ao_app_ao (ao_operator "state") (m')) n'))
        => 
            m ← example_1.my_number'_inv m';
            n ← example_1.my_number'_inv n';
            Some (m, n)
    | _ => None
    end
    .

    Lemma pair_state_inversion : forall m n,
        state_to_pair (pair_to_state (m,n)) = Some (m,n)
    .
    Proof.
        intros m n.
        simpl.
        rewrite bind_Some.
        exists m.
        split.
        { rewrite example_1.my_number_inversion'. reflexivity. }
        rewrite bind_Some.
        exists n.
        split.
        { rewrite example_1.my_number_inversion'. reflexivity. }
        reflexivity.
    Qed.

    Definition interp_loop_number fuel := 
        fun (m n : nat) =>
        let fg' := ((interp_loop interp fuel) ∘ pair_to_state) (m,n) in
        state_to_pair fg'.2
    .

End two_counters.

Module arith.

    Import default_builtin.
    Import default_builtin.Notations.

    #[local]
    Instance Σ : StaticModel := default_model (default_builtin.β).

    Definition X : variable := "X".
    Definition Y : variable := "Y".
    Definition REST_SEQ : variable := "$REST_SEQ".
    
    Definition cseq {_br : BasicResolver} := (apply_symbol "cseq").
    Arguments cseq {_br} _%rs.

    Definition emptyCseq {_br : BasicResolver} := (apply_symbol "emptyCseq").
    Arguments emptyCseq {_br} _%rs.

    Definition plus {_br : BasicResolver} := (apply_symbol "plus").
    Arguments plus {_br} _%rs.

    Definition cfg {_br : BasicResolver} := (apply_symbol "cfg").
    Arguments cfg {_br} _%rs.

    Definition state {_br : BasicResolver} := (apply_symbol "state").
    Arguments state {_br} _%rs.

    Definition s {_br : BasicResolver} := (apply_symbol "s").
    Arguments s {_br} _%rs.

    Definition freezer {_br : BasicResolver} (sym : symbol) (position : nat)
    :=
        (apply_symbol ("freezer_" +:+ sym +:+ "_" +:+ (pretty position)))
    .
    Arguments freezer {_br} _%rs.


    Declare Scope LangArithScope.
    Delimit Scope LangArithScope with larith.

    Notation "x '+' y" := (plus [ x, y ]).

    Definition isResult (x : Expression) : Expression :=
        (isNat x)
    .



    Definition Decls : list Declaration := [
        decl_rule (
            rule ["plus-nat-nat"]:
                cfg [ cseq [ ($X + $Y), $REST_SEQ ] ]
            ~> (cfg [ (cseq [ ($X +Nat $Y) , $REST_SEQ ])%rs ])%rs
                where (
                    (isNat ($X))
                    &&
                    (isNat ($Y))
                )
        );
        decl_rule (
            rule ["plus-heat-1"]:
                cfg [ cseq [ plus [ $X, $Y ], $REST_SEQ ]]
            ~> cfg [ cseq [$X, cseq [ (freezer "plus" 0) [$Y] , $REST_SEQ ]]]
                where ( ~~ (isResult ($X)) )
        );
        decl_rule (
            rule ["plus-cool-1"]: 
                cfg [ cseq [$X, cseq [ (freezer "plus" 0) [$Y] , $REST_SEQ ]]]
            ~> cfg [ cseq [ plus [ $X, $Y ], $REST_SEQ ]]
                where ((isResult ($X)) )
        );
        decl_rule (
            rule ["plus-heat-2"]:
                cfg [ cseq [ plus [ $X, $Y ], $REST_SEQ ]]
            ~> cfg [ cseq [$Y, cseq [ (freezer "plus" 1) [$X] , $REST_SEQ ]]]
                where ( isResult ($X) && ~~ (isResult ($Y)) )
        );
        decl_rule (
            rule ["plus-cool-2"]: 
                cfg [ cseq [$Y, cseq [ (freezer "plus" 1) [$X] , $REST_SEQ ]]]
            ~> cfg [ cseq [ plus [ $X, $Y ], $REST_SEQ ]]
                where ((isResult ($Y)) )
        )
    ].

    Definition Γ : FlattenedRewritingTheory := Eval vm_compute in 
    (to_theory (process_declarations (Decls))).

    Definition initial1 (x y : nat) :=
        (ground (cfg [ cseq [ ((@aoo_operand symbol _ (bv_nat x)) + (@aoo_operand symbol _ (bv_nat y))), emptyCseq [] ] ]))
    .

    Definition initial (x: nat) (ly : list nat) :=
        (ground (
            cfg [
                cseq [ 
                    (foldr 
                        (fun a (b : AppliedOperatorOr' symbol builtin_value) =>
                            plus [((bv_nat a)) , b]
                        )
                        (@aoo_operand symbol builtin_value (bv_nat x))
                        ly
                    ),
                    emptyCseq []
                    ]
                ]
            )
        )
    .

    Definition interp_list (fuel : nat) (x : nat) (ly : list nat)
    :=
        interp_loop (naive_interpreter Γ) fuel (initial x ly)
    .

    Eval vm_compute in (interp_list 20 1 [20;30;40]).

End arith.

