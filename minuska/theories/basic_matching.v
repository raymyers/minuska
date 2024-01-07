
From Minuska Require Import
    prelude
    tactics
    spec_syntax
    spec_semantics
    syntax_properties
.

Require Import Logic.PropExtensionality.
Require Import Setoid.
Require Import Coq.Classes.Morphisms.
Require Import Coq.Classes.Morphisms_Prop.



Class Matches
    {Σ : Signature}
    (V A B var : Type)
    {_SV : SubsetEq V}
    {_varED : EqDecision var}
    {_varCnt : Countable var}
    {_VA : VarsOf B var}
    {_VV : VarsOf V var}
    {_SAB : Satisfies V A B var} :=
{
    matchesb:
        V -> A -> B -> bool ;

    matchesb_satisfies :
        ∀ (v : V) (a : A) (b : B),
            reflect (satisfies v a b) (matchesb v a b) ;

    matchesb_vars_of :
        ∀ (v : V) (a : A) (b : B),
            matchesb v a b = true ->
            vars_of b ⊆ vars_of v ;
}.

Arguments satisfies : simpl never.
Arguments matchesb : simpl never.

Lemma matchesb_implies_satisfies
    {Σ : Signature}
    (V A B var : Type)
    {_varED : EqDecision var}
    {_varCnt : Countable var}
    {_SV : SubsetEq V}
    {_VA : VarsOf B var}
    {_VV : VarsOf V var}
    {_SAB : Satisfies V A B var}
    {_MAB : Matches V A B var}
    :
    forall (v : V) (a : A) (b : B),
        matchesb v a b = true ->
        satisfies v a b
.
Proof.
    intros.
    assert (HR := matchesb_satisfies v a b).
    apply reflect_iff in HR.
    ltac1:(naive_solver).
Qed.

Lemma satisfies_implies_matchesb
    {Σ : Signature}
    (V A B var : Type)
    {_varED : EqDecision var}
    {_varCnt : Countable var}
    {_SV : SubsetEq V}
    {_VA : VarsOf B var}
    {_VV : VarsOf V var}
    {_SAB : Satisfies V A B var}
    {_MAB : Matches V A B var}
    :
    forall (v : V) (a : A) (b : B),
        satisfies v a b ->
        matchesb v a b = true
.
Proof.
    intros.
    assert (HR := matchesb_satisfies v a b).
    apply reflect_iff in HR.
    ltac1:(naive_solver).
Qed.

Lemma matchesb_ext
    {Σ : Signature}
    (V A B var : Type)
    {_varED : EqDecision var}
    {_varCnt : Countable var}
    {_SV : SubsetEq V}
    {_VA : VarsOf B var}
    {_VV : VarsOf V var}
    {_SAB : Satisfies V A B var}
    {_MAB : Matches V A B var}
    :
    forall (v1 v2 : V),
        v1 ⊆ v2 ->
        forall (a : A) (b : B),
            matchesb v1 a b = true ->
            matchesb v2 a b = true
.
Proof.
    intros.
    apply matchesb_implies_satisfies in H0.
    apply satisfies_implies_matchesb.
    eapply satisfies_ext.
    { exact H. }
    { assumption. }
Qed.

Section with_signature.
    Context
        {Σ : Signature}
    .
(*
    #[global]
    Instance Vars_of_id
        {var T : Type}
        {_TED : EqDecision T}
        {_varED : EqDecision var}
        {_varCnt : Countable var}
        : VarsOf (gmap var T) var
    := {|
        vars_of := fun x => dom x
    |}.
*)
  
    Fixpoint ApppliedOperator'_matches_AppliedOperator'
        {V Operand1 Operand2 var : Type}
        {_varED : EqDecision var}
        {_varCnt : Countable var}
        {_SV : SubsetEq V}
        {_VVv : VarsOf V var}
        {_S1 : Satisfies V (symbol) Operand2 var}
        {_S2 : Satisfies V (Operand1) Operand2 var}
        {_S3 : Satisfies V (Operand1) (AppliedOperator' symbol Operand2) var}
        {_S4 : Satisfies V (AppliedOperator' symbol Operand1) Operand2 var}
        {_V1 : VarsOf Operand1 var}
        {_V2 : VarsOf Operand2 var}
        {_M1 : Matches V (symbol) Operand2 var}
        {_M2 : Matches V (Operand1) Operand2 var}
        {_M3 : Matches V (Operand1) (AppliedOperator' symbol Operand2) var}
        {_M4 : Matches V (AppliedOperator' symbol Operand1) Operand2 var}
        (ρ : V)
        (x : (AppliedOperator' symbol Operand1))
        (y : AppliedOperator' symbol Operand2)
        : bool :=
    match x, y with
    | ao_operator a1, ao_operator a2 =>
        bool_decide (a1 = a2)
    | ao_operator _, ao_app_operand _ _ => false
    | ao_operator _, ao_app_ao _ _ => false
    | ao_app_operand _ _ , ao_operator _ => false
    | ao_app_operand app1 o1, ao_app_operand app2 o2 =>
        ApppliedOperator'_matches_AppliedOperator' 
            ρ (app1)
            app2
        && matchesb ρ (o1) o2
    | ao_app_operand app1 o1, ao_app_ao app2 o2 =>
        ApppliedOperator'_matches_AppliedOperator' ρ app1 app2
        && matchesb ρ o1 o2
    | ao_app_ao app1 o1, ao_operator _ => false
    | ao_app_ao app1 o1, ao_app_operand app2 o2 =>
        ApppliedOperator'_matches_AppliedOperator' 
            ρ app1
            app2
        && matchesb ρ o1 o2
    | ao_app_ao app1 o1, ao_app_ao app2 o2 =>
        ApppliedOperator'_matches_AppliedOperator' 
            ρ app1
            app2
        &&
        ApppliedOperator'_matches_AppliedOperator' 
            ρ o1
            o2
    end.

    #[export]
    Program Instance reflect__satisfies__ApppliedOperator'_matches_AppliedOperator'
        {V Operand1 Operand2 var : Type}
        {_varED : EqDecision var}
        {_varCnt : Countable var}
        {_SV : SubsetEq V}
        {_VVv : VarsOf V var}
        {_V1v : VarsOf Operand1 var}
        {_V2v : VarsOf Operand2 var}
        {_S1 : Satisfies V (symbol) Operand2 var}
        {_S2 : Satisfies V (Operand1) Operand2 var}
        {_S3 : Satisfies V (Operand1) (AppliedOperator' symbol Operand2) var}
        {_S4 : Satisfies V (AppliedOperator' symbol Operand1) Operand2 var}
        {_M1 : Matches V (symbol) Operand2 var}
        {_M2 : Matches V (Operand1) Operand2 var}
        {_M3 : Matches V (Operand1) (AppliedOperator' symbol Operand2) var}
        {_M4 : Matches V (AppliedOperator' symbol Operand1) Operand2 var}
        :
        Matches
            V
            ((AppliedOperator' symbol Operand1))
            (AppliedOperator' symbol Operand2)
            var
        := {|
            matchesb :=
                ApppliedOperator'_matches_AppliedOperator' ;
            matchesb_satisfies := _;
        |}.
    Next Obligation.
        simpl.
        ltac1:(rename v into ρ).
        ltac1:(rename a into x).
        ltac1:(rename b into y).
        revert y.
        induction x; intros y; destruct y.
        {
            simpl.
            unfold bool_decide.
            ltac1:(case_match).
            {
                apply ReflectT.
                subst.
                constructor.
            }
            {
                apply ReflectF.
                intros HContra.
                inversion HContra; subst; clear HContra.
                ltac1:(contradiction).
            }
        }
        {

            apply ReflectF.
            intros HContra.
            inversion HContra.
        }
        {
            apply ReflectF.
            intros HContra.
            inversion HContra.
        }
        {
            apply ReflectF.
            intros HContra.
            inversion HContra.
        }
        {
            simpl.
            specialize (IHx y).
            simpl in IHx.
            destruct ((ApppliedOperator'_matches_AppliedOperator' ρ x y)) eqn:Heqm1.
            {
                simpl.
                apply reflect_iff in IHx.
                apply proj2 in IHx.
                specialize (IHx eq_refl).
                destruct (matchesb ρ b b0) eqn:Heqm.
                {
                    apply ReflectT.
                    constructor.
                    apply IHx.
                    assert(reflect_matches := matchesb_satisfies ρ b b0).
                    apply reflect_iff in reflect_matches.
                    apply reflect_matches.
                    exact Heqm.
                }
                {
                    apply ReflectF.
                    intros HContra.
                    inversion HContra; subst; clear HContra.
                    assert(reflect_matches := matchesb_satisfies ρ b b0).
                    apply reflect_iff in reflect_matches.
                    apply reflect_matches in H5.
                    rewrite Heqm in H5.
                    inversion H5.
                }
            }
            {
                simpl.
                apply ReflectF.
                intros HContra.
                inversion HContra; subst; clear HContra.
                simpl in H5.
                apply reflect_iff in IHx.
                apply proj1 in IHx.
                specialize (IHx ltac:(assumption)).
                inversion IHx.
            }
        }
        {
            simpl.
            specialize (IHx y1).
            simpl in IHx.
            unfold satisfies; simpl.
            destruct ((ApppliedOperator'_matches_AppliedOperator' ρ x y1)) eqn:Heqm1.
            {
                simpl.
                apply reflect_iff in IHx.
                apply proj2 in IHx.
                specialize (IHx eq_refl).
                destruct (matchesb ρ b y2) eqn:Heqm.
                {
                    apply ReflectT.
                    constructor.
                    apply IHx.
                    assert(reflect_matches := matchesb_satisfies ρ b y2).
                    apply reflect_iff in reflect_matches.
                    apply reflect_matches.
                    exact Heqm.
                }
                {
                    apply ReflectF.
                    intros HContra.
                    inversion HContra; subst; clear HContra.
                    assert(reflect_matches := matchesb_satisfies ρ b y2).
                    apply reflect_iff in reflect_matches.
                    apply reflect_matches in H5.
                    rewrite Heqm in H5.
                    inversion H5.
                }
            }
            {
                simpl.
                apply ReflectF.
                intros HContra.
                inversion HContra; subst; clear HContra.
                simpl in H5.
                apply reflect_iff in IHx.
                apply proj1 in IHx.
                specialize (IHx ltac:(assumption)).
                inversion IHx.
            }
        }
        {
            simpl.
            apply ReflectF.
            intros HContra.
            inversion HContra.
        }
        {
            simpl.
            specialize (IHx1 y).
            apply reflect_iff in IHx1.
            simpl in IHx1.
            apply iff_reflect.
            rewrite andb_true_iff.
            rewrite <- IHx1.
            ltac1:(cut ((satisfies ρ x2 b) <-> (matchesb ρ x2 b = true))).
            {
                intros HH0. rewrite <- HH0.
                simpl.    
                split; intros HH.
                {
                    inversion HH; subst; clear HH.
                    split; assumption.
                }
                {
                    constructor;
                    destruct HH; assumption.
                }
            }
            assert(reflect_matches_app_2 := matchesb_satisfies ρ x2 b).
            apply reflect_iff in reflect_matches_app_2.
            apply reflect_matches_app_2.
        }
        {
            specialize (IHx1 y1).
            specialize (IHx2 y2).
            apply reflect_iff in IHx1.
            apply reflect_iff in IHx2.
            apply iff_reflect.
            simpl.
            rewrite andb_true_iff.
            rewrite <- IHx1.
            rewrite <- IHx2.
            simpl.
            split; intros HH; inversion HH; subst; clear HH; constructor; assumption.
        }
    Qed.
    Next Obligation.
        revert b H.
        unfold vars_of; simpl.
        induction a; simpl; intros b' H.
        { 
            destruct b'; simpl in *.
            { ltac1:(set_solver). }
            { inversion H. }
            { inversion H. }
        }
        {
            destruct b'.
            { inversion H. }
            {
                rewrite andb_true_iff in H.
                destruct H as [H1 H2].
                specialize (IHa b' H1).
                apply matchesb_vars_of in H2.
                clear -IHa H2.
                ltac1:(set_solver).
            }
            {
                rewrite andb_true_iff in H.
                destruct H as [H1 H2].
                assert (IH1 := IHa b'1 H1).
                apply matchesb_vars_of in H2.
                clear -IH1 H2.
                ltac1:(set_solver).
            }
        }
        {
            destruct b'.
            { inversion H. }
            {
                rewrite andb_true_iff in H.
                destruct H as [H1 H2].
                specialize (IHa1 b' H1).
                apply matchesb_vars_of in H2.
                clear -IHa1 H2.
                ltac1:(set_solver).
            }
            {
                rewrite andb_true_iff in H.
                destruct H as [H1 H2].
                specialize (IHa1 b'1 H1).
                specialize (IHa2 b'2 H2).
                clear - IHa1 IHa2.
                ltac1:(set_solver).
            }
        }
    Qed.
    Fail Next Obligation.

    Definition ApppliedOperatorOr'_matches_AppliedOperatorOr'
        {V Operand1 Operand2 var : Type}
        {_EDv : EqDecision var}
        {_Cv : Countable var}
        {_SV : SubsetEq V}
        {_Vv : VarsOf V var}
        {_V1 : VarsOf Operand1 var}
        {_V2 : VarsOf Operand2 var}
        {_S1 : Satisfies V (symbol) Operand2 var}
        {_S2 : Satisfies V (Operand1) Operand2 var}
        {_S3 : Satisfies V (Operand1) (AppliedOperator' symbol Operand2) var}
        {_S4 : Satisfies V ((AppliedOperator' symbol Operand1)) Operand2 var}
        {_M1 : Matches V (symbol) Operand2 var}
        {_M2 : Matches V (Operand1) Operand2 var}
        {_M3 : Matches V (Operand1) (AppliedOperator' symbol Operand2) var}
        {_M4 : Matches V ((AppliedOperator' symbol Operand1)) Operand2 var}
        (ρ : V)
        (x : (AppliedOperatorOr' symbol Operand1))
        (y : AppliedOperatorOr' symbol Operand2)
        : bool :=
    match x, y with
    | aoo_app _ _ app1, aoo_app _ _ app2 =>
        matchesb ρ app1 app2
    | aoo_app _ _ app1, aoo_operand _ _ o2 =>
        matchesb ρ app1 o2
    | aoo_operand _ _ o1, aoo_app _ _ app2 =>
        false (*matchesb (ρ, o1) app2*)
    | aoo_operand _ _ o1, aoo_operand _ _ o2 =>
        matchesb ρ o1 o2
    end.

    #[export]
    Program Instance
        reflect__satisfies__ApppliedOperatorOr'_matches_AppliedOperatorOr'
        {V Operand1 Operand2 var : Type}
        {_EDv : EqDecision var}
        {_Cv : Countable var}
        {_SV : SubsetEq V}
        {_Vv : VarsOf V var}
        {_V1 : VarsOf Operand1 var}
        {_V2 : VarsOf Operand2 var}
        {_S1 : Satisfies V (symbol) Operand2 var}
        {_S2 : Satisfies V (Operand1) Operand2 var}
        {_S3 : Satisfies V (Operand1) (AppliedOperator' symbol Operand2) var}
        {_S4 : Satisfies V ((AppliedOperator' symbol Operand1)) Operand2 var}
        {_M1 : Matches V (symbol) Operand2 var}
        {_M2 : Matches V (Operand1) Operand2 var}
        {_M3 : Matches V (Operand1) (AppliedOperator' symbol Operand2) var}
        {_M4 : Matches V ((AppliedOperator' symbol Operand1)) Operand2 var}
        :
        Matches
            V
            (AppliedOperatorOr' symbol Operand1)
            (AppliedOperatorOr' symbol Operand2)
            var
        := {|
            matchesb := 
                ApppliedOperatorOr'_matches_AppliedOperatorOr';
            matchesb_satisfies := _;
        |}.
    Next Obligation.
        ltac1:(rewrite /fst).
        ltac1:(rewrite /snd).
        ltac1:(rename v into ρ).
        ltac1:(rename a into x).
        ltac1:(rename b into y).
        
        simpl.
        destruct x; simpl.
        {
            destruct y; simpl.
            {
                unfold ApppliedOperatorOr'_matches_AppliedOperatorOr'.
                simpl.
                unfold satisfies; simpl.

                apply iff_reflect.
                split; intros HH.
                {
                    inversion HH; subst; clear HH.
                    eapply introT.
                    { apply matchesb_satisfies. }
                    { assumption. }
                }
                {
                    constructor.
                    eapply elimT.
                    { apply matchesb_satisfies. }
                    { assumption. }
                }
            }
            {
                unfold ApppliedOperatorOr'_matches_AppliedOperatorOr'.
                simpl.
                apply iff_reflect.
                split; intros HH.
                {
                    inversion HH; subst; clear HH.
                    eapply introT.
                    { apply matchesb_satisfies. }
                    { assumption. }
                }
                {
                    constructor.
                    eapply elimT.
                    { apply matchesb_satisfies. }
                    { assumption. }
                }
            }
        }
        {
            unfold ApppliedOperatorOr'_matches_AppliedOperatorOr'.
            simpl.
            destruct y; simpl.
            {
                unfold satisfies.
                simpl.
                apply iff_reflect.
                split; intros HH.
                {
                    inversion HH; subst; clear HH.
                }
                {
                    ltac1:(exfalso).
                    inversion HH.
                }
            }
            {
                unfold satisfies.
                simpl.
                apply iff_reflect.
                split; intros HH.
                {
                    inversion HH; subst; clear HH.
                    eapply introT.
                    { apply matchesb_satisfies. }
                    { assumption. }
                }
                {
                    constructor.
                    eapply elimT.
                    { apply matchesb_satisfies. }
                    { assumption. }
                }
            }
        }
    Qed.
    Next Obligation.
        destruct a,b; simpl in *.
        {
            apply matchesb_vars_of in H.
            assumption.
        }
        {
            apply matchesb_vars_of in H.
            assumption.
        }
        { inversion H. }
        {
            apply matchesb_vars_of in H.
            assumption.
        }
    Qed.
    Fail Next Obligation.

    Definition builtin_value_matches_BuiltinOrVar
        : Valuation -> builtin_value -> BuiltinOrVar -> bool :=
    fun ρ b bv =>
    match bv with
    | bov_builtin b' => bool_decide (b = b')
    | bov_variable x =>
        match ρ !! x with
        | None => false
        | Some (aoo_app _ _ _) => false
        | Some (aoo_operand _ _ b') => bool_decide (b = b')
        end
    end.

    #[export]
    Program Instance
        reflect__matches__builtin_value__BuiltinOrVar
        :
        Matches
            (gmap variable GroundTerm)
            (builtin_value)
            BuiltinOrVar
            variable
        := {|
            matchesb := 
                builtin_value_matches_BuiltinOrVar;
            matchesb_satisfies := _;
        |}.
    Next Obligation.
        unfold satisfies; simpl.
        destruct b; unfold builtin_satisfies_BuiltinOrVar'; simpl.
        {
            apply iff_reflect.
            split; intros HH.
            {
                inversion HH; subst; clear HH.
                unfold bool_decide.
                ltac1:(case_match; subst; naive_solver).
            }
            {
                unfold bool_decide in HH.
                ltac1:(case_match; subst; try contradiction; try constructor; naive_solver).
            }
        }
        {
            unfold Valuation in *.
            destruct (v !! x) eqn:Hvx; simpl.
            {
                destruct a0; simpl.
                {
                    apply ReflectF.
                    intros HContra.
                    inversion HContra; subst; clear HContra.
                    ltac1:(rewrite Hvx in H1).
                    inversion H1.
                }
                {
                    unfold bool_decide.
                    ltac1:(case_match).
                    {
                        apply ReflectT.
                        constructor. subst. assumption.
                    }
                    {
                        apply ReflectF.
                        intros HContra.
                        inversion HContra; subst; clear HContra.
                        ltac1:(rewrite Hvx in H2).
                        inversion H2.
                        ltac1:(congruence).
                    }
                }
            }
            {
                apply ReflectF.
                intros HContra.
                inversion HContra; subst; clear HContra.
                ltac1:(rewrite Hvx in H1).
                inversion H1.
            }
        }
    Qed.
    Next Obligation.
        unfold vars_of; destruct b; simpl.
        { ltac1:(clear; set_solver). }
        {
            simpl in H.
            unfold Valuation in *.
            destruct (v !! x) eqn:Hvx.
            {
                rewrite elem_of_subseteq.
                intros x0 Hx0.
                rewrite elem_of_singleton in Hx0.
                subst.
                rewrite elem_of_dom.
                exists a0. assumption.
            }
            {
                inversion H.
            }
        }
    Qed.
    Fail Next Obligation.

    (* Can this be simplified? *)
    Definition builtin_value_matches_OpenTerm
        : Valuation -> builtin_value -> OpenTerm -> bool :=
    fun ρ b t =>
    match t with
    | aoo_app _ _ _ => false
    | aoo_operand _ _ (bov_variable x) =>
        match ρ !! x with
        | None => false
        | Some (aoo_app _ _ _) => false
        | Some (aoo_operand _ _ b') => bool_decide (b = b')
        end
    | aoo_operand _ _ (bov_builtin b') =>
        bool_decide (b = b')
    end.

    #[export]
    Program Instance
        reflect__matches__builtin_value__OpenTerm
        :
        Matches
            Valuation
            (builtin_value)
            OpenTerm
            variable
        := {|
            matchesb := builtin_value_matches_OpenTerm;
            matchesb_satisfies := _;
        |}.
    Next Obligation.
        destruct b; simpl.
        {
            apply ReflectF.
            intros HContra.
            inversion HContra.
        }
        {
            unfold bool_decide.
            ltac1:((repeat case_match); simplify_eq/=);
                try (apply ReflectF; intros HContra; inversion HContra; subst; clear HContra;
                    ltac1:(simplify_eq/=)).
            {
                apply ReflectT.
                constructor.
            }
            {
                apply ReflectT.
                constructor.
                simpl.
                assumption.
            }
        }
    Qed.
    Next Obligation.
        destruct b; unfold vars_of at 1; simpl in *.
        {
            inversion H.
        }
        {
            ltac1:(repeat case_match); subst; unfold vars_of; simpl.
            { ltac1:(set_solver). }
            { inversion H. }
            {
                rewrite elem_of_subseteq.
                intros x0 Hx0.
                rewrite elem_of_singleton in Hx0.
                subst.
                unfold Valuation in *.
                rewrite elem_of_dom.
                eexists. ltac1:(eassumption).
            }
            { inversion H. }
        }
    Qed.
    Fail Next Obligation.

    Definition GroundTerm'_matches_BuiltinOrVar
        : Valuation -> (AppliedOperator' symbol builtin_value) ->
            BuiltinOrVar ->
            bool
    := fun ρ t bov =>
    match bov with
    | bov_builtin b => false
    | bov_variable x =>
        bool_decide (ρ !! x = Some (aoo_app _ _ t))
    end.

    #[export]
    Program Instance
        matches__builtin_value__OpenTerm
        :
        Matches
            Valuation
            (AppliedOperator' symbol builtin_value)
            BuiltinOrVar
            variable
        := {|
            matchesb := GroundTerm'_matches_BuiltinOrVar;
            matchesb_satisfies := _;
        |}.
    Next Obligation.
        destruct b; simpl.
        {
            apply ReflectF.
            intros HContra.
            inversion HContra.
        }
        {
            unfold bool_decide.
            apply iff_reflect.
            ltac1:(case_match; split; intros HH; inversion HH; simplify_eq/=).
            { reflexivity. }
            { 
                unfold satisfies. simpl. assumption.
            }
        }
    Qed.
    Next Obligation.
        destruct b; simpl in *.
        { inversion H. }
        {
            rewrite bool_decide_eq_true in H.
            unfold vars_of; simpl.
            rewrite elem_of_subseteq.
            intros x0 Hx0.
            rewrite elem_of_singleton in Hx0.
            subst.
            unfold Valuation in *.
            rewrite elem_of_dom.
            eexists. ltac1:(eassumption).
        }
    Qed.
    Fail Next Obligation.

    #[export]
    Program Instance Matches_bv_ao'
        {V B var : Type}
        {_SV : SubsetEq V}
        {_EDv : EqDecision var}
        {_Cv : Countable var}
        {_VV : VarsOf V var}
        {_VB : VarsOf B var}
        :
        Matches
            V
            builtin_value
            (AppliedOperator' symbol B)
            var
    := {|
        matchesb := fun _ _ _ => false ;
    |}.
    Next Obligation.
        unfold satisfies. simpl.
        apply ReflectF.
        intros HContra.
        inversion HContra.
    Qed.
    Fail Next Obligation.

    #[export]
    Instance VarsOf_LocalRewriteOrOpenTermOrBOV
        :
        VarsOf
            LocalRewriteOrOpenTermOrBOV
            (LeftRight*variable)
    := {|
        vars_of := fun (x : LocalRewriteOrOpenTermOrBOV) =>
            match x with
            | lp_rewrite r =>
                let v1 := (vars_of (lr_from r)) in
                let v2 := (vars_of (lr_to r)) in
                let v1' := (set_map (fun x : variable => (LR_Left, x)) v1) in
                let v2' := (set_map (fun x : variable => (LR_Right, x)) v2) in
                v1' ∪ v2'
                (*v1' ∪ v2'*)
            | lp_basicpat b =>
                let vs := (vars_of b) in
                let v1' := (set_map (fun x : variable => (LR_Left, x)) vs) in
                let v2' := (set_map (fun x : variable => (LR_Right, x)) vs) in
                v1' ∪ v2'
            | lp_bov bov =>
                let vs := (vars_of bov) in
                let v1' := (set_map (fun x : variable => (LR_Left, x)) vs) in
                let v2' := (set_map (fun x : variable => (LR_Right, x)) vs) in
                v1' ∪ v2'
            end
    |}.

    #[export]
    Instance VarsOf_LeftRight
        {_VO : VarsOf Valuation (LeftRight * variable)}
        :
        VarsOf (Valuation * LeftRight) variable
    := {|
        vars_of := fun ρd =>
            let ρ := ρd.1 in
            let d := ρd.2 in
            let vs : gset (LeftRight * variable) := vars_of ρ in
            let vs' := filter (fun x => x.1 = d) vs in
            set_map (fun x : LeftRight * variable => x.2) vs'
    |}.

    (*
    Set Typeclasses Debug.
    #[export]
    Program Instance Matches_vlrblrootob
        :
        Matches
            (Valuation * LeftRight)
            (builtin_value)
            (AppliedOperator' symbol LocalRewriteOrOpenTermOrBOV)
            (variable)
    := {|
        matchesb := fun _ _ _ => false ;
    |}.
    Next Obligation.
        unfold satisfies; simpl.
        apply ReflectF. ltac1:(tauto).
    Qed.
    Fail Next Obligation.
    *)


    Search (Satisfies _ symbol _ _).
    Set Typeclasses Debug.
    #[export]
    Program Instance
        Matches_symbol_B
        {V B var : Type}
        {_VarED : EqDecision var}
        {_VarCnt : Countable var}
        {_SV : SubsetEq V}
        {_VB : VarsOf B var}
        {_VV : VarsOf V var}
        :
        Matches V symbol B var
    := {|
        matchesb := fun _ _ _ => false
    |}.
    Next Obligation.
        apply ReflectF.
        unfold satisfies; simpl.
        ltac1:(tauto).
    Qed.
    Fail Next Obligation.
    (*
    #[export]
    Program Instance Matches_sym_bov
        :
        Matches (Valuation * symbol) BuiltinOrVar
    := {|
        matchesb := fun _ _ => false ;
    |}.
    Next Obligation.
        unfold satisfies; simpl.
        apply ReflectF. ltac1:(tauto).
    Qed.
    Fail Next Obligation.
    *)

    (*
    #[export]
    Program Instance Matches__builtin__aosbov
        :
        Matches
            (Valuation * builtin_value)
            (AppliedOperator' symbol BuiltinOrVar)
    := {|
        matchesb := fun _ _ => false ;
    |}.
    Next Obligation.
        apply ReflectF.
        unfold satisfies; simpl.
        intros HContra. inversion HContra.
    Qed.
    Fail Next Obligation.
    *)

    #[export]
    Instance
        matches__GroundTerm__OpenTerm
        :
        Matches
            Valuation
            GroundTerm
            OpenTerm
            variable
    .
    Proof.
        unfold GroundTerm.
        unfold GroundTerm'.
        unfold OpenTerm.
        apply reflect__satisfies__ApppliedOperatorOr'_matches_AppliedOperatorOr'.
    Defined.

End with_signature.

Class ComputableSignature {Σ : Signature} := {
    builtin_unary_predicate_interp_bool :
        builtin_unary_predicate -> GroundTerm -> bool ; 

    builtin_binary_predicate_interp_bool :
        builtin_binary_predicate -> GroundTerm -> GroundTerm -> bool ;         

    cs_up :
        forall p e,
            reflect
                (builtin_unary_predicate_interp p e)
                (builtin_unary_predicate_interp_bool p e) ;

    cs_bp :
        forall p e1 e2,
            reflect
                (builtin_binary_predicate_interp p e1 e2)
                (builtin_binary_predicate_interp_bool p e1 e2) ;
}.

Definition val_satisfies_ap_bool
    `{ComputableSignature}
    (ρ : Valuation)
    (ap : AtomicProposition)
    : bool :=
match ap with
| apeq e1 e2 => 
    let v1 := Expression_evaluate ρ e1 in
    let v2 := Expression_evaluate ρ e2 in
    bool_decide (v1 = v2) && isSome v1
| ap1 p e =>
    let v := Expression_evaluate ρ e in
    match v with
    | Some vx => builtin_unary_predicate_interp_bool p vx
    | None => false
    end
| ap2 p e1 e2 =>
    let v1 := Expression_evaluate ρ e1 in
    let v2 := Expression_evaluate ρ e2 in
    match v1,v2 with
    | Some vx, Some vy => builtin_binary_predicate_interp_bool p vx vy
    | _,_ => false
    end
end
.

Lemma expression_evaluate_some_valuation
    {Σ : Signature} ρ e x
    :
    Expression_evaluate ρ e = Some x ->
    vars_of e ⊆ vars_of ρ.
Proof.
    revert x.
    induction e; unfold vars_of; simpl; intros x' H.
    {
        ltac1:(set_solver).
    }
    {
        rewrite elem_of_subseteq.
        intros x1 Hx1.
        rewrite elem_of_singleton in Hx1.
        subst.
        unfold Valuation in *.
        rewrite elem_of_dom.
        exists x'. assumption.
    }
    {
        rewrite bind_Some in H.
        destruct H as [x0 [H1x0 H2x0]].
        inversion H2x0; subst; clear H2x0.
        rewrite H1x0 in IHe. simpl in IHe.
        specialize (IHe x0 eq_refl).
        apply IHe.
    }
    {
        rewrite bind_Some in H.
        destruct H as [x0 [H1x0 H2x0]].
        inversion H2x0; subst; clear H2x0.

        rewrite bind_Some in H0.
        destruct H0 as [x1 [H1x1 H2x1]].
        inversion H2x1; subst; clear H2x1.
        specialize (IHe1 _ H1x0).
        specialize (IHe2 _ H1x1).
        rewrite union_subseteq.
        split; assumption.
    }
Qed.

#[export]
Program Instance Matches_val_ap
    `{ComputableSignature}
    : Matches Valuation unit AtomicProposition variable
:= {|
    matchesb := fun a b c => val_satisfies_ap_bool a c;
|}.
Next Obligation.
    induction b; simpl.
    {
        unfold satisfies.
        simpl.
        unfold is_Some, bool_decide.
        ltac1:(case_match).
        {
            simpl.
            apply iff_reflect.
            split; intros HH.
            {
                destruct HH as [HH1 [x HHx]].
                rewrite HHx.
                reflexivity.
            }
            {
                split.
                {
                    assumption.
                }
                {
                    unfold isSome in *|-.
                    ltac1:(case_match).
                    {
                        exists g. reflexivity.
                    }
                    {
                        inversion HH.
                    }
                }
            }
        }
        {
            simpl.
            apply ReflectF.
            intros [HContra1 [x HContrax]].
            ltac1:(simplify_eq/=).
        }
    }
    {
        unfold satisfies.
        simpl.
        ltac1:(case_match).
        {
            apply cs_up.
        }
        {
            apply ReflectF. intros HContra. exact HContra.
        }
    }
    {
        unfold satisfies.
        simpl.
        ltac1:(repeat case_match).
        {
            apply cs_bp.
        }
        {
            apply ReflectF. intros HContra. exact HContra.
        }
        {
            apply ReflectF. intros HContra. exact HContra.
        }
    }
Qed.
Next Obligation.
    destruct b; unfold vars_of in *; simpl in *.
    {
        rewrite andb_true_iff in H0.
        rewrite bool_decide_eq_true in H0.
        destruct H0 as [H1 H2].
        unfold isSome in *.
        destruct (Expression_evaluate v e1) eqn:Heq2>[|inversion H2].
        clear H2. symmetry in H1.
        unfold vars_of. simpl.
        apply expression_evaluate_some_valuation in Heq2.
        apply expression_evaluate_some_valuation in H1.
        rewrite union_subseteq.
        split; assumption.
    }
    {
        destruct (Expression_evaluate v e1) eqn:Heq>[|inversion H0].
        apply expression_evaluate_some_valuation in Heq.
        assumption.
    }
    {
        destruct (Expression_evaluate v e1) eqn:Heq1>[|inversion H0].
        destruct (Expression_evaluate v e2) eqn:Heq2>[|inversion H0].
        apply expression_evaluate_some_valuation in Heq1.
        apply expression_evaluate_some_valuation in Heq2.
        rewrite union_subseteq.
        split; assumption.
    }
Qed.
Fail Next Obligation.

Fixpoint val_satisfies_c_bool
    {Σ : Signature}
    {CΣ : ComputableSignature}
    (ρ : Valuation)
    (c : Constraint)
    : bool :=
match c with
| c_True => true
| c_atomic ap => matchesb ρ () ap
| c_and c1 c2 => val_satisfies_c_bool ρ c1 && val_satisfies_c_bool ρ c2
(* | c_not c' => ~~ val_satisfies_c_bool ρ c' *)
end.

Lemma val_satisfies_valuation
    {Σ : Signature}
    {CΣ : ComputableSignature}
    ρ c
    :
    val_satisfies_c_bool ρ c = true ->
    vars_of c ⊆ vars_of ρ.
Proof.
    induction c; unfold vars_of; simpl; intros H.
    { ltac1:(set_solver). }
    {
        apply matchesb_vars_of in H.
        exact H.
    }
    {
        rewrite union_subseteq.
        rewrite andb_true_iff in H.
        destruct H as [H1 H2].
        auto with core.
    }
Qed.

#[export]
Program Instance Matches_val_c
    `{CΣ : ComputableSignature}
    : Matches Valuation unit Constraint variable
:= {|
    matchesb := fun a b c => val_satisfies_c_bool a c;
|}.
Next Obligation.
    induction b.
    {
        apply ReflectT. exact I.
    }
    {
        unfold satisfies; simpl.
        apply matchesb_satisfies.
    }
    {
        apply reflect_iff in IHb1.
        apply reflect_iff in IHb2.
        unfold satisfies; simpl.
        unfold val_satisfies_c_bool; simpl.
        fold (@val_satisfies_c_bool Σ CΣ).
        unfold satisfies in IHb1.
        unfold satisfies in IHb2.
        simpl in *|-.
        apply iff_reflect.
        rewrite -> IHb1.
        rewrite -> IHb2.
        symmetry.
        apply andb_true_iff.
    }
    (*
    {
        apply reflect_iff in IHb.
        unfold satisfies in *; simpl in *.
        apply iff_reflect.
        rewrite IHb.
        split; intros HH.
        {
            apply not_true_is_false in HH.
            rewrite HH.
            reflexivity.
        }
        {
            intros HContra.
            rewrite HContra in HH.
            inversion HH.
        }
    }
    *)
Qed.
Next Obligation.
    destruct b; unfold vars_of; simpl in *.
    { ltac1:(set_solver). }
    {
        apply matchesb_vars_of in H.
        assumption.
    }
    {
        rewrite andb_true_iff in H.
        destruct H as [H1 H2].
        apply val_satisfies_valuation in H1.
        apply val_satisfies_valuation in H2.
        ltac1:(set_solver).
    }
Qed.
Fail Next Obligation.

Definition valuation_satisfies_match_bool
    {Σ : Signature}
    (ρ : Valuation)
    (m : Match) : bool :=
match m with
| mkMatch _ x φ =>
    match ρ !! x with
    | Some g
        => matchesb ρ g φ
    | _ => false
    end
end.

#[export]
Program Instance Matches_val_match
    {Σ : Signature}
    :
    Matches Valuation unit Match variable
:= {|
    matchesb := fun a b c => valuation_satisfies_match_bool a c;
|}.
Next Obligation.
    destruct b; unfold satisfies; simpl.
    ltac1:(case_match).
    {
        apply matchesb_satisfies.
    }
    {
        apply ReflectF.
        ltac1:(tauto).
    }
Qed.
Next Obligation.
    destruct b; unfold vars_of; simpl in *.
    unfold Valuation in *.
    ltac1:(case_match).
    {
        apply matchesb_vars_of in H.
        apply elem_of_dom_2 in H0.
        ltac1:(set_solver).
    }
    { inversion H. }
Qed.
Fail Next Obligation.


Definition valuation_satisfies_sc_bool
    `{CΣ : ComputableSignature}
    (ρ : Valuation)
    (sc : SideCondition) : bool :=
match sc with
| sc_constraint c => matchesb ρ () c
| sc_match m => matchesb ρ () m
end.

#[export]
Program Instance Matches_valuation_sc
    `{CΣ : ComputableSignature}
    :
    Matches Valuation unit SideCondition variable
:= {|
    matchesb := fun a b c => valuation_satisfies_sc_bool a c;
|}.
Next Obligation.
    destruct b.
    {
        unfold satisfies; simpl.
        apply matchesb_satisfies.
    }
    {
        unfold satisfies; simpl.
        apply matchesb_satisfies.
    }
Qed.
Next Obligation.
    destruct b; unfold vars_of; simpl in *.
    {
        apply matchesb_vars_of in H.
        exact H.
    }
    {
        apply matchesb_vars_of in H.
        exact H.
    }
Qed.
Fail Next Obligation.


#[export]
Program Instance VarsOf_list_SideCondition
    {Σ : Signature}
    : VarsOf (list SideCondition) variable
:= {|
    vars_of := fun scs => ⋃ (vars_of <$> scs)
|}.

#[export]
Program Instance Matches_valuation_scs
    {Σ : Signature}
    {CΣ : ComputableSignature}
    :
    Matches Valuation unit (list SideCondition) variable
:= {|
    matchesb := fun ρ b c => forallb (matchesb ρ ()) c;
|}.
Next Obligation.
    unfold satisfies. simpl.
    apply iff_reflect.
    rewrite Forall_forall.
    rewrite forallb_forall.
    split; intros H' x Hin; specialize (H' x Hin).
    {
        eapply introT.
        { apply matchesb_satisfies. }
        {
            apply H'.
        }
    }
    {
        eapply elimT.
        { apply matchesb_satisfies. }
        {
            apply H'.
        }
    }
Qed.
Next Obligation.
    unfold vars_of; simpl.
    rewrite forallb_forall in H.
    rewrite elem_of_subseteq.
    intros x Hx. 
    rewrite elem_of_union_list in Hx.
    destruct Hx as [X [H1X H2X]].
    unfold Valuation in *.
    rewrite elem_of_list_fmap in H1X.
    destruct H1X as [y [H1y H2y]].
    subst.
    
    specialize (H y).
    rewrite <- elem_of_list_In in H.
    specialize (H ltac:(assumption)).
    apply matchesb_vars_of in H.
    
    rewrite elem_of_subseteq in H.
    specialize (H x H2X).
    exact H.
Qed.
Fail Next Obligation.



#[export]
Program Instance Matches__builtin__Expr
   `{CΣ : ComputableSignature}
    :
    Matches Valuation builtin_value (Expression) variable
:= {|
    matchesb := (fun ρ b e =>
        bool_decide (Expression_evaluate ρ e = Some (aoo_operand _ _ b))
    ) ;
|}.
Next Obligation.
    unfold satisfies. simpl.
    apply bool_decide_reflect.
Qed.
Next Obligation.
    apply bool_decide_eq_true in H.
    apply expression_evaluate_some_valuation in H.
    assumption.
Qed.
Fail Next Obligation.

#[export]
Program Instance Matches_asb_expr
    {Σ : Signature}:
    Matches
        Valuation
        ((AppliedOperator' symbol builtin_value))
        Expression
        variable
:= {|
    matchesb := (fun ρ x e =>
        bool_decide (Expression_evaluate ρ e = Some (aoo_app _ _ x))   ) ;
|}.
Next Obligation.
    unfold satisfies. simpl.
    apply bool_decide_reflect.
Qed.
Next Obligation.
    apply bool_decide_eq_true in H.
    apply expression_evaluate_some_valuation in H.
    assumption.
Qed.
Fail Next Obligation.

