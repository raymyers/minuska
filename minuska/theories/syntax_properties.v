From Minuska Require Import
    prelude
    spec_syntax
.

Require Export Minuska.varsof.

Section eqdec.

    #[export]
    Instance PreTerm'_eqdec
        {symbol : Type}
        {symbols : Symbols symbol}
        (builtin : Type)
        {builtin_dec : EqDecision builtin}
        : EqDecision (PreTerm' symbol builtin)
    .
    Proof.
        ltac1:(solve_decision).
    Defined.

    #[export]
    Instance Term'_eqdec
        {A : Type}
        {symbols : Symbols A}
        (T : Type)
        {T_dec : EqDecision T}
        : EqDecision (Term' A T)
    .
    Proof.
        ltac1:(solve_decision).
    Defined.

    #[export]
    Instance Expression_eqdec {Σ : StaticModel}
        : EqDecision (Expression)
    .
    Proof.
        ltac1:(solve_decision).
    Defined.

    #[export]
    Instance LeftRight_eqdec
        : EqDecision LeftRight
    .
    Proof.
        ltac1:(solve_decision).
    Defined.

    #[export]
    Program Instance LeftRight_fin
        : Finite LeftRight
    := {|
        enum := [LR_Left;LR_Right];
    |}.
    Next Obligation.
        ltac1:(compute_done).
    Qed.
    Next Obligation.
        destruct x;
        ltac1:(compute_done).
    Qed.
    Fail Next Obligation.

    #[export]
    Instance atomicProposition_eqdec {Σ : StaticModel}
        : EqDecision AtomicProposition
    .
    Proof.
        ltac1:(solve_decision).
    Defined.

    #[export]
    Instance BuiltinOrVar_eqdec {Σ : StaticModel}
        : EqDecision BuiltinOrVar
    .
    Proof.
        ltac1:(solve_decision).
    Defined.

    #[export]
    Instance GroundTerm_eqdec {Σ : StaticModel}
        : EqDecision GroundTerm
    .
    Proof.
        intros e1 e2.
        apply Term'_eqdec.
        apply builtin_value_eqdec.
    Defined.

    #[export]
    Instance  SymbolicTerm_eqdec {Σ : StaticModel}
        : EqDecision SymbolicTerm
    .
    Proof.
        ltac1:(solve_decision).
    Defined.

    #[export]
    Instance  SideCondition_eqdec {Σ : StaticModel}
        : EqDecision SideCondition
    .
    Proof.
        ltac1:(solve_decision).
    Defined.

    #[export]
    Instance ExpressionTerm_eqdec {Σ : StaticModel}
        : EqDecision ExpressionTerm
    .
    Proof.
        ltac1:(solve_decision).
    Defined.

End eqdec.


Section countable.

    Fixpoint PreTerm'_to_gen_tree
        (symbol : Type)
        {symbols : Symbols symbol}
        (builtin : Type)
        {T_eqdec : EqDecision builtin}
        {T_countable : Countable builtin}
        (a : PreTerm' symbol builtin)
        : gen_tree symbol
    :=
    match a with
    | (pt_operator s) => GenLeaf s
    | (pt_app_operand aps b) =>
        (
            let x := (encode (0, encode b)) in
            GenNode (Pos.to_nat x) ([PreTerm'_to_gen_tree symbol builtin aps;PreTerm'_to_gen_tree symbol builtin aps(* we duplicate it to make the reverse simpler*)])
        )
    | (pt_app_ao aps1 aps2)
        => (
            let xd := (1, encode 0) in
            let x := (encode xd) in
            GenNode (Pos.to_nat x) ([PreTerm'_to_gen_tree _ _ aps1; PreTerm'_to_gen_tree _ _ aps2])
        )
    end.

    Fixpoint PreTerm'_of_gen_tree
        (symbol : Type)
        {symbols : Symbols symbol}
        (builtin : Type)
        {T_eqdec : EqDecision builtin}
        {T_countable : Countable builtin}
        (t : gen_tree symbol)
        : option (PreTerm' symbol builtin)
    :=
    match t with
    | (GenLeaf s)
        => Some (pt_operator s)
    | (GenNode n [gt1;gt2]) =>
        let d := (@decode (nat*positive) _ _ (Pos.of_nat n)) in
        match d with
            | Some (0, pb) =>
                let d' := (@decode builtin _ _ pb) in
                match d' with
                | Some b =>
                    let d'' := (PreTerm'_of_gen_tree symbol builtin gt1) in
                    match d'' with 
                    | Some as1 => Some (pt_app_operand as1 b)
                    | _ => None
                    end
                | _ => None
                end
            | Some (1, _) =>
                let d'1 := PreTerm'_of_gen_tree symbol builtin gt1 in
                let d'2 := PreTerm'_of_gen_tree symbol builtin gt2 in
                match d'1, d'2 with
                | Some aps1, Some aps2 => Some (pt_app_ao aps1 aps2)
                | _, _ => None
                end
            | _ => None
            end
    | _ => None
    end
    .

    Lemma PreTerm'_of_to_gen_tree
        (symbol : Type)
        {symbols : Symbols symbol}
        (builtin : Type)
        {T_eqdec : EqDecision builtin}
        {T_countable : Countable builtin}
        (a : PreTerm' symbol builtin)
        : PreTerm'_of_gen_tree symbol builtin (PreTerm'_to_gen_tree symbol builtin a) = Some a
    .
    Proof.
        induction a; simpl.
        { reflexivity. }
        {
            ltac1:(rewrite ! Pos2Nat.id decode_encode).
            rewrite decode_encode.
            rewrite IHa.
            reflexivity.
        }
        {
            rewrite IHa1.
            rewrite IHa2.
            reflexivity.
        }
    Qed.

    #[export]
    Instance appliedOperator_countable
        (symbol_set : Type)
        {symbols : Symbols symbol_set}
        (builtin_set : Type)
        {builtin_eqdec : EqDecision builtin_set}
        {builtin_countable : Countable builtin_set}
        : Countable (PreTerm' symbol_set builtin_set)
    .
    Proof.
        apply inj_countable
        with
            (f := PreTerm'_to_gen_tree symbol_set builtin_set)
            (g := PreTerm'_of_gen_tree symbol_set builtin_set)
        .
        intros x.
        apply PreTerm'_of_to_gen_tree.
    Qed.

    Definition Term'_to_gen_tree
        (symbol : Type)
        {symbols : Symbols symbol}
        (builtin : Type)
        {T_eqdec : EqDecision builtin}
        {T_countable : Countable builtin}
        (e : Term' symbol builtin)
        : gen_tree (builtin + (PreTerm' symbol builtin))%type
    :=
    match e with
    | (term_operand b) => GenLeaf (inl _ b)
    | (term_preterm s) => GenLeaf (inr _ s)
    end
    .

    Definition Term'_from_gen_tree
        (symbol : Type)
        {symbols : Symbols symbol}
        (builtin : Type)
        {builtin_eqdec : EqDecision builtin}
        {builtin_countable : Countable builtin}
        (t : gen_tree (builtin+(PreTerm' symbol builtin))%type)
        :  option (Term' symbol builtin)
    :=
    match t with
    | (GenLeaf (inl _ b)) => Some (term_operand b)
    | (GenLeaf (inr _ s)) => Some (term_preterm s)
    | _ => None
    end
    .

    Lemma Term'_to_from_gen_tree
        (symbol : Type)
        {symbols : Symbols symbol}
        (builtin : Type)
        {builtin_eqdec : EqDecision builtin}
        {builtin_countable : Countable builtin}
        (e : Term' symbol builtin)
        : Term'_from_gen_tree symbol builtin (Term'_to_gen_tree symbol builtin e) = Some e
    .
    Proof.
        destruct e; reflexivity.
    Qed.

    #[export]
    Instance Term'_countable
        (symbol_set : Type)
        {symbols : Symbols symbol_set}
        (builtin_set : Type)
        {builtin_eqdec : EqDecision builtin_set}
        {builtin_countable : Countable builtin_set}
        : Countable (Term' symbol_set builtin_set)
    .
    Proof.
        apply inj_countable
        with
            (f := Term'_to_gen_tree symbol_set builtin_set)
            (g := Term'_from_gen_tree symbol_set builtin_set)
        .
        intros x.
        apply Term'_to_from_gen_tree.
    Defined.

End countable.


Fixpoint PreTerm'_fmap
    {A B C : Type}
    (f : B -> C)
    (ao : PreTerm' A B)
    : PreTerm' A C
:=
match ao with
| pt_operator o => pt_operator o
| pt_app_operand ao' x => pt_app_operand (PreTerm'_fmap f ao') (f x)
| pt_app_ao ao1 ao2 => pt_app_ao (PreTerm'_fmap f ao1) (PreTerm'_fmap f ao2)
end.

#[export]
Instance PreTerm'_A_B_fmap (A : Type)
    : FMap (PreTerm' A)
    := @PreTerm'_fmap A
.


Definition Term'_fmap
    {A B C : Type}
    (f : B -> C)
    (aoo : Term' A B)
    : Term' A C
:=
match aoo with
| term_preterm ao => term_preterm (f <$> ao)
| term_operand o => term_operand (f o)
end.


#[global]
Instance Term'_A_B_fmap (A : Type)
    : FMap (Term' A)
    := @Term'_fmap A
.

#[global]
Instance Term_symbol_fmap
    {Σ : StaticModel}
    : FMap (Term' symbol)
.
Proof.
    apply Term'_A_B_fmap.
Defined.


Fixpoint PreTerm'_collapse_option
    {A B : Type}
    (ao : PreTerm' A (option B))
    : option (PreTerm' A B)
:=
match ao with
| pt_operator o =>
    Some (pt_operator o)

| pt_app_operand ao' x =>
    ao'' ← PreTerm'_collapse_option ao';
    x'' ← x;
    Some (pt_app_operand ao'' x'')

| pt_app_ao ao1 ao2 =>
    ao1'' ← PreTerm'_collapse_option ao1;
    ao2'' ← PreTerm'_collapse_option ao2;
    Some (pt_app_ao ao1'' ao2'')
end.


Definition Term'_collapse_option
    {A B : Type}
    (aoo : Term' A (option B))
    : option (Term' A B)
:=
match aoo with
| term_preterm ao =>
    tmp ← PreTerm'_collapse_option ao;
    Some (term_preterm tmp)
| term_operand op =>
    tmp ← op;
    Some (term_operand tmp)
end.


Fixpoint PreTerm'_zipWith
    {A B C D : Type}
    (fa : A -> A -> A)
    (fbc : B -> C -> D)
    (f1 : PreTerm' A B -> C -> D)
    (f2 : B -> PreTerm' A C -> D)
    (ao1 : PreTerm' A B)
    (ao2 : PreTerm' A C)
    : PreTerm' A D
:=
match ao1,ao2 with
| pt_operator o1, pt_operator o2 => pt_operator (fa o1 o2)
| pt_operator o1, pt_app_operand app2 op2 =>
    pt_operator o1
| pt_operator o1, pt_app_ao app21 app22 =>
    pt_operator o1
| pt_app_operand app1 op1, pt_app_operand app2 op2 =>
    pt_app_operand
        (PreTerm'_zipWith fa fbc f1 f2 app1 app2)
        (fbc op1 op2)
| pt_app_operand app1 op1, pt_operator o2 =>
    pt_operator o2
| pt_app_operand app1 op1, pt_app_ao app21 app22 =>
    pt_app_operand
        ((PreTerm'_zipWith fa fbc f1 f2 app1 app21))
        (f2 op1 app22)
| pt_app_ao app11 app12, pt_app_ao app21 app22 =>
    pt_app_ao
        (PreTerm'_zipWith fa fbc f1 f2 app11 app21)
        (PreTerm'_zipWith fa fbc f1 f2 app12 app22)
| pt_app_ao app11 app12, pt_operator op2 =>
    pt_operator op2
| pt_app_ao app11 app12, pt_app_operand app21 op22 =>
    pt_app_operand 
        (PreTerm'_zipWith fa fbc f1 f2 app11 app21)
        (f1 app12 op22)
end.

Fixpoint AO'_getOperator {A B : Type}
    (ao : PreTerm' A B)
    : A :=
match ao with
| pt_operator o => o
| pt_app_operand ao' _ => AO'_getOperator ao'
| pt_app_ao ao' _ => AO'_getOperator ao'
end.


