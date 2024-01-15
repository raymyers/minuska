From Minuska Require Import
    prelude
    spec_syntax
    flattened
    notations
    default_static_model
    builtins
.


Import default_builtin.
Export default_builtin.Notations.


Arguments ft_unary {Σ} f (t).
Arguments ft_binary {Σ} f (t1) (t2).



Fixpoint OpenTerm_to_ExprTerm'
    {Σ : StaticModel}
    (t : AppliedOperator' symbol BuiltinOrVar)
    : AppliedOperator' symbol Expression
:=
match t with
| ao_operator s => ao_operator s
| ao_app_operand ao (bov_variable x)
    => ao_app_operand (OpenTerm_to_ExprTerm' ao) (ft_variable x)
| ao_app_operand ao (bov_builtin b)
    => ao_app_operand (OpenTerm_to_ExprTerm' ao) (ft_element (aoo_operand b))
| ao_app_ao ao1 ao2
    => ao_app_ao (OpenTerm_to_ExprTerm' ao1) (OpenTerm_to_ExprTerm' ao2)
end
.

Definition OpenTerm_to_ExprTerm
    {Σ : StaticModel}
    (t : AppliedOperatorOr' symbol BuiltinOrVar)
    : AppliedOperatorOr' symbol Expression
:=
match t with
| aoo_operand (bov_variable x) => aoo_operand (ft_variable x)
| aoo_operand (bov_builtin b) => aoo_operand (ft_element (aoo_operand b))
| aoo_app t' => aoo_app (OpenTerm_to_ExprTerm' t')
end
.

Definition label {Σ : StaticModel} :=
    string
.


Record ContextDeclaration {Σ : StaticModel}
:= mkContextDeclaration {
    cd_label : label ;
    cd_variable : variable ;
    cd_pattern : AppliedOperatorOr' symbol BuiltinOrVar ;
}.


Record RuleDeclaration {Σ : StaticModel}
:= mkRuleDeclaration {
    rd_label : label ;
    rd_rule : FlattenedRewritingRule ;
}.

Arguments mkRuleDeclaration {Σ} rd_label rd_rule.

Inductive Declaration {Σ : StaticModel} :=
| decl_rule (r : RuleDeclaration)
| decl_ctx (c : ContextDeclaration)
.

(*Coercion decl_rule : RuleDeclaration >-> Declaration.*)

Notation "'rule' '[' n ']:' l ~> r"
    := ((mkRuleDeclaration
        n (rule (l) ~> (r) requires nil)
    ))
    (at level 200)
.

Notation "'rule' '[' n ']:' l ~> r 'where' s"
    := ((mkRuleDeclaration
        n (rule (l) ~> (r) requires (cons (sc_constraint (apeq ((ft_nullary b_true)) (s))) nil))
    ))
    (at level 200)
.

Definition argument_name
    (idx : nat)
    : string
:=
    "X_" +:+ (pretty idx)
.

Definition argument_sequence
    {Σ : StaticModel}
    (to_var : string -> variable)
    (arity : nat)
    : list variable
:=
    to_var <$> (argument_name <$> (seq 0 arity))
.

Section wsm.
(*
    Context
        {Σ : StaticModel}
        (to_var : string -> variable)
        (to_sym : string -> symbol)
    .
*)
    #[local]
    Instance Σ : StaticModel := default_model (default_builtin.β).

    Definition to_var := fun x:string => x.
    Definition to_sym := fun x:string => x.
    
    Definition REST_SEQ : variable := to_var "$REST_SEQ".

    Definition cseq {T : Type}
    :=
        (@apply_symbol' Σ T (to_sym "cseq"))
    .

    Definition emptyCseq {T : Type}
    :=
        (@apply_symbol' Σ T (to_sym "emptyCseq"))
    .

    Definition freezer
        {T : Type}
        (sym : string)
        (position : nat)
    :=
        (@apply_symbol' Σ T (to_sym ("freezer_" +:+ sym +:+ "_" +:+ (pretty position))))
    .

    Definition heating_rule
        (lbl : label)
        (sym : symbol)
        (arity : nat)
        (position : nat)
        (side_condition : Expression)
        (isResult : Expression -> Expression)
        (cseq_context : AppliedOperatorOr' symbol BuiltinOrVar -> AppliedOperatorOr' symbol BuiltinOrVar)
        : RuleDeclaration
    :=
        let vars : list variable
            := argument_sequence to_var arity in
        let lhs_vars : list (AppliedOperatorOr' symbol BuiltinOrVar)
            := (aoo_operand <$> (bov_variable <$> vars)) in
        let rhs_vars : list (AppliedOperatorOr' symbol Expression)
            := (aoo_operand <$> (ft_variable <$> vars)) in
        let selected_var : variable
            := to_var (argument_name position) in
        let lhs_selected_var : (AppliedOperatorOr' symbol BuiltinOrVar)
            := aoo_operand (bov_variable selected_var) in
        rule [lbl]:
            cseq_context (cseq ([
                (apply_symbol' sym lhs_vars);
                (aoo_operand (bov_variable REST_SEQ))
            ])%list)
         ~> OpenTerm_to_ExprTerm ((cseq_context (cseq ([
                lhs_selected_var;
                cseq ([
                    (freezer lbl position (delete position lhs_vars));
                    (aoo_operand (bov_variable REST_SEQ))
                ])%list
            ])%list)))
            where (( ~~ (isResult (ft_variable selected_var)) ) && side_condition )
    .

End wsm.

Definition NamedFlattenedRewritingRule
    {Σ : StaticModel}
    : Type
:=
    prod label FlattenedRewritingRule
.


Record State {Σ : StaticModel}
:= mkState {
    st_rules : gmap label FlattenedRewritingRule ;
    st_log : string ;
}.

Arguments mkState {Σ} st_rules st_log%string_scope.


Definition initialState
    {Σ : StaticModel}
    : State
:= {|
    st_rules := ∅ ;
    st_log := "";
|}.

Definition process_rule_declaration
    {Σ : StaticModel}
    (s : State)
    (r : RuleDeclaration)
    : State
:=
match (st_rules s) !! (rd_label r) with
| Some _
    => (mkState
        (st_rules s)
        ((st_log s) +:+ ("Rule with name '" +:+ (rd_label r) ++ "' already present"))%string)
| None
    => mkState
        (<[(rd_label r) := (rd_rule r)]>(st_rules s))
        (st_log s)
end
.

(* TODO implement *)
Definition process_context_declaration
    {Σ : StaticModel}
    (s : State)
    (c : ContextDeclaration)
    : State
:= s.

Definition process_declaration
    {Σ : StaticModel}
    (s : State)
    (d : Declaration)
    : State
:=
match d with
| decl_rule rd => process_rule_declaration s rd
| decl_ctx cd => process_context_declaration s cd
end.

Definition process_declarations
    {Σ : StaticModel}
    (ld : list Declaration)
    : State
:=
    fold_left process_declaration ld initialState
.


Definition to_theory
    {Σ : StaticModel}
    (s : State)
    : FlattenedRewritingTheory
:=
    (map_to_list (st_rules s)).*2
.
