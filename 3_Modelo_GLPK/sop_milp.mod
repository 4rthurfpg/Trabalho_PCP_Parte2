###############################################################################
# MILP S&OP - Planejamento Integrado da Cadeia de Suprimentos
# Disciplina: PCP - EPD035 (UFMG) | Prof. Joao Flavio
# Grupo 1 - Parte 2
#
# Formulacao em GNU MathProg (GMPL), compativel com GLPK e GUSEK.
# Separacao canonica:
#   sop_milp.mod  -> modelo (sets, params, vars, FO, restricoes)
#   sop_milp.dat  -> dados de UM cenario
#
# Para rodar via linha de comando (GLPK):
#   glpsol -m sop_milp.mod -d sop_milp.dat -o resultado.txt
###############################################################################

# =====================================================================
# CONJUNTOS
# =====================================================================
set T;            # periodos: {1, 2}
set V;            # fornecedores: {V1, V2}
set F;            # fabricas:   {F1, F2}
set D;            # CDs:        {DC1, DC2}
set C;            # clientes:   {C1, C2}
set Y;            # produtos acabados: {Y1, Y2}
set X;            # componentes:       {X1, X2}
set M;            # modais: {M1 trem, M2 caminhao}
set R;            # maquinas: {RA, RB, RC, RD}
set MAQ_F{F};     # maquinas da fabrica f
set LINHA_IN{F};  # entrada da linha sequencial (RA em F1, RC em F2)
set PROD_MAQ within {F, Y, R};  # combinacoes (f,y,r) habilitadas

# =====================================================================
# PARAMETROS (todos os numeros fixos do enunciado)
# =====================================================================
param USAR_BIG_M;               # 1 = COM Big-M (default); 0 = SEM (R1 estrita)
param BIG_M;                    # valor da penalidade (10^4 = 10000)
param fator_demanda;            # 1.0 (provavel), 1.10 (otimista), 0.80 (pessimista)
param cap_h;                    # capacidade horaria base por maquina (h/periodo)

param dem_base{T, C, Y} >= 0;   # demanda base por (t, c, y)
param preco{Y} >= 0;            # preco de venda
param tax{C, Y} >= 0, <= 1;     # carga tributaria por (c, y)
param ei{(F union D), (X union Y)} >= 0;        # estoque inicial
param es{(F union D), (X union Y), T} >= 0;     # estoque minimo (seguranca)
param em{(F union D), (X union Y), T} >= 0;     # estoque maximo
param ef{(F union D), (X union Y)} >= 0;        # estoque final exigido
param cap_in{D, T} >= 0;        # manuseio CD entrada
param cap_out{D, T} >= 0;       # manuseio CD saida
param cap_modal{V, F, M} >= 0;  # capacidade modal por rota VF
param cap_modal_FD{F, D, M} >= 0;
param cap_modal_DC{D, C, M} >= 0;
param bom{Y, X} >= 0;           # BOM: Y = sum_x bom[y,x] * X
param lote_Y{F, Y} >= 1;        # lote de producao (Y1=5, Y2=1)
param lote_X{V, X} >= 1;        # lote de compra (10)
param temp{F, Y, R} >= 0;       # tempo h/un por (f, y, r)
param eff{F, R, T} >= 0;        # eficiencia
param manut{F, R, T} >= 0;      # horas de manutencao
param ex_cap{F, R, T} >= 0;     # horas extras maximas
param c_log_VF{V, F, M} >= 0;
param c_log_FD{F, D, M} >= 0;
param c_log_DC{D, C, M} >= 0;
param c_est{(F union D), (X union Y)} >= 0;
param c_var{F, Y} >= 0;
param c_fix{F, R} >= 0;
param c_ex{F, R} >= 0;          # custo da hora extra (R$/h) - vale 100
param p_compra{V, (X union Y)} >= 0;
param disp{T, (X union Y), V} >= 0;

# Demanda efetiva (aplicando o fator do cenario)
param dem{t in T, c in C, y in Y} := round(dem_base[t,c,y] * fator_demanda);

# =====================================================================
# VARIAVEIS DE DECISAO
# =====================================================================
var tx{T, X, V, F, M} integer, >= 0;
var ty_VF{T, Y, V, F, M} integer, >= 0;
var ty_FD{T, Y, F, D, M} integer, >= 0;
var ty_DC{T, Y, D, C, M} integer, >= 0;
var cb_X{T, X, V} integer, >= 0;
var cb_Y{T, Y, V} integer, >= 0;
var pr{T, F, Y, R} integer, >= 0;
var a{T, F, R} binary;
var aLine{T, F} binary;
var ex{T, F, R} >= 0;
var if_X{T, F, X} >= 0;
var if_Y{T, F, Y} >= 0;
var icd{T, D, Y} >= 0;
var pr_lot{T, F, Y, R} integer, >= 0;
var cb_X_lot{T, X, V} integer, >= 0;
var n{T, C, Y} integer, >= 0;   # nao-entrega (penalizada por Big-M; forcada a 0 se USAR_BIG_M=0)

# =====================================================================
# FUNCAO OBJETIVO (sem Big-M)
# =====================================================================
var receita;
s.t. def_receita:
    receita = sum{t in T, c in C, y in Y} (dem[t,c,y] - n[t,c,y]) * preco[y] * (1 - tax[c,y]);

var custo_compra;
s.t. def_compra:
    custo_compra = sum{t in T, x in X, v in V} cb_X[t,x,v] * p_compra[v,x]
                 + sum{t in T, y in Y, v in V} cb_Y[t,y,v] * p_compra[v,y];

# Custo logistico DESTRINCHADO por fluxo x rota x modal
var custo_log;
s.t. def_log:
    custo_log = sum{t in T, x in X, v in V, f in F, m in M} tx[t,x,v,f,m] * c_log_VF[v,f,m]
              + sum{t in T, y in Y, v in V, f in F, m in M} ty_VF[t,y,v,f,m] * c_log_VF[v,f,m]
              + sum{t in T, y in Y, f in F, d in D, m in M} ty_FD[t,y,f,d,m] * c_log_FD[f,d,m]
              + sum{t in T, y in Y, d in D, c in C, m in M} ty_DC[t,y,d,c,m] * c_log_DC[d,c,m];

# Custo variavel cobrado UMA vez por unidade da linha (entrada r_in)
var custo_var_prod;
s.t. def_var:
    custo_var_prod = sum{t in T, f in F, y in Y, r in LINHA_IN[f]:
                          (f,y,r) in PROD_MAQ} pr[t,f,y,r] * c_var[f,y];

var custo_fixo;
s.t. def_fixo:
    custo_fixo = sum{t in T, f in F, r in MAQ_F[f]} a[t,f,r] * c_fix[f,r];

# Custo extra: c_ex ja esta em R$/hora (=100). Multiplicacao direta por ex (horas).
var custo_extra;
s.t. def_extra:
    custo_extra = sum{t in T, f in F, r in MAQ_F[f]} ex[t,f,r] * c_ex[f,r];

var custo_estoque;
s.t. def_est:
    custo_estoque = sum{t in T, f in F, x in X} if_X[t,f,x] * c_est[f,x]
                  + sum{t in T, f in F, y in Y} if_Y[t,f,y] * c_est[f,y]
                  + sum{t in T, d in D, y in Y} icd[t,d,y] * c_est[d,y];

# Maximizar lucro (COM termo Big-M; se USAR_BIG_M=0, R1_estrita forca n=0 e o termo zera)
maximize Z:
    receita - custo_compra - custo_log - custo_var_prod
    - custo_fixo - custo_extra - custo_estoque
    - USAR_BIG_M * BIG_M * sum{t in T, c in C, y in Y} n[t,c,y];

# =====================================================================
# R1 - Atendimento de demanda
# ---------------------------------------------------------------------
# Para cada (t, c, y), tudo que sai dos CDs e chega ao cliente, somado a
# eventual nao-entrega n, iguala a demanda. A variavel n e penalizada por
# Big-M na FO, entao na pratica n=0 sempre que possivel - a R1 funciona
# como atendimento obrigatorio. Se USAR_BIG_M=0, R1_estrita forca n=0 e
# a R1 vira igualdade estrita "sum ty_DC = dem".
# =====================================================================
s.t. R1{t in T, c in C, y in Y}:
    sum{d in D, m in M} ty_DC[t,y,d,c,m] + n[t,c,y] = dem[t,c,y];

s.t. R1_estrita{t in T, c in C, y in Y: USAR_BIG_M = 0}:
    n[t,c,y] = 0;

# =====================================================================
# R2 - Capacidade do modal por rota (X e Y compartilham veiculo)
# ---------------------------------------------------------------------
# Cada modal (M1 trem ou M2 caminhao) numa rota especifica tem capacidade
# limitada. Componentes (X) e acabados (Y) SOMAM no mesmo veiculo. Se um
# trem leva 6 X1 + 4 Y1, ocupa 10 unidades (= capacidade do trem).
# Tres familias: R2_VF (Fornecedor->Fabrica), R2_FD (Fabrica->CD),
# R2_DC (CD->Cliente).
# =====================================================================
s.t. R2_VF{t in T, v in V, f in F, m in M}:
    sum{x in X} tx[t,x,v,f,m] + sum{y in Y} ty_VF[t,y,v,f,m] <= cap_modal[v,f,m];
s.t. R2_FD{t in T, f in F, d in D, m in M}:
    sum{y in Y} ty_FD[t,y,f,d,m] <= cap_modal_FD[f,d,m];
s.t. R2_DC{t in T, d in D, c in C, m in M}:
    sum{y in Y} ty_DC[t,y,d,c,m] <= cap_modal_DC[d,c,m];

# =====================================================================
# R3 / R4 - Manuseio operacional do CD (entrada e saida)
# ---------------------------------------------------------------------
# R3 limita o total que ENTRA em cada CD por periodo (cap_in = 50 un).
# R4 limita o total que SAI do CD para os clientes (cap_out = 50 un).
# Sao gargalos INDEPENDENTES - o CD pode receber muito e despachar pouco
# (ou vice-versa). Modela docas fisicas e capacidade de movimentacao.
# =====================================================================
s.t. R3{t in T, d in D}:
    sum{y in Y, f in F, m in M} ty_FD[t,y,f,d,m] <= cap_in[d,t];
s.t. R4{t in T, d in D}:
    sum{y in Y, c in C, m in M} ty_DC[t,y,d,c,m] <= cap_out[d,t];

# =====================================================================
# R5 / R6 - Niveis de estoque (limites min e max por local-produto)
# ---------------------------------------------------------------------
# R5: estoque final >= es (=10 un). Cobre incertezas de demanda/atraso.
# R6: estoque final <= em (=100 un). Limite fisico de armazenagem.
# Aplicada a TRES tipos de estoque: X na fabrica, Y na fabrica, Y no CD.
# Sao 12 restricoes ao todo (3 locais x 2 produtos x 2 periodos para min,
# idem para max).
# =====================================================================
s.t. R5_IFx{t in T, f in F, x in X}:  if_X[t,f,x] >= es[f,x,t];
s.t. R5_IFy{t in T, f in F, y in Y}:  if_Y[t,f,y] >= es[f,y,t];
s.t. R5_ICD{t in T, d in D, y in Y}:  icd[t,d,y]  >= es[d,y,t];
s.t. R6_IFx{t in T, f in F, x in X}:  if_X[t,f,x] <= em[f,x,t];
s.t. R6_IFy{t in T, f in F, y in Y}:  if_Y[t,f,y] <= em[f,y,t];
s.t. R6_ICD{t in T, d in D, y in Y}:  icd[t,d,y]  <= em[d,y,t];

# =====================================================================
# R7 - Estoque final no fim do horizonte (so no ultimo periodo)
# ---------------------------------------------------------------------
# No ultimo periodo (T=2), o estoque tem que ser >= ef (=10 un). Garante
# que terminamos o horizonte com nivel minimo, sem "passar problema" para
# o horizonte seguinte. Diferente de R5 (que vale TODO periodo), R7 e
# checada apenas no fim - garantia de fechamento.
# =====================================================================
s.t. R7_IFx{f in F, x in X}:  if_X[2,f,x] >= ef[f,x];
s.t. R7_IFy{f in F, y in Y}:  if_Y[2,f,y] >= ef[f,y];
s.t. R7_ICD{d in D, y in Y}:  icd[2,d,y]  >= ef[d,y];

# =====================================================================
# R8 - Balanco de estoque + R_BOM (consumo via lista de materiais)
# ---------------------------------------------------------------------
# Conservacao de massa em cada local-produto-periodo:
#   estoque_final = estoque_inicial + entradas - saidas
#
# Para componentes X na fabrica (R8_IFx):
#   entradas = transporte vindo dos fornecedores
#   saidas   = R_BOM (consumo: pr[entrada_linha] * bom[y,x])
#                     ^ multiplicacao variavel * parametro
#
# Para acabados Y na fabrica (R8_IFy):
#   entradas = producao (pr na entrada da linha) + Y comprado pronto
#   saidas   = envio para CDs
#
# Para acabados Y no CD (R8_ICD):
#   entradas = vindo das fabricas
#   saidas   = enviado aos clientes
#
# IMPORTANTE: producao e consumo so contam UMA vez (na entrada da linha,
# RA em F1 / RC em F2), porque a R10b garante que a peca eh a mesma nas
# duas maquinas - nao podemos contar duas vezes.
# =====================================================================
s.t. R8_IFx{t in T, f in F, x in X}:
    if_X[t,f,x] =
      (if t = 1 then ei[f,x] else if_X[t-1,f,x])
      + sum{v in V, m in M} tx[t,x,v,f,m]
      - sum{y in Y, r in LINHA_IN[f]: (f,y,r) in PROD_MAQ} pr[t,f,y,r] * bom[y,x];

s.t. R8_IFy{t in T, f in F, y in Y}:
    if_Y[t,f,y] =
      (if t = 1 then ei[f,y] else if_Y[t-1,f,y])
      + sum{r in LINHA_IN[f]: (f,y,r) in PROD_MAQ} pr[t,f,y,r]
      + sum{v in V, m in M} ty_VF[t,y,v,f,m]
      - sum{d in D, m in M} ty_FD[t,y,f,d,m];

s.t. R8_ICD{t in T, d in D, y in Y}:
    icd[t,d,y] =
      (if t = 1 then ei[d,y] else icd[t-1,d,y])
      + sum{f in F, m in M} ty_FD[t,y,f,d,m]
      - sum{c in C, m in M} ty_DC[t,y,d,c,m];

# =====================================================================
# R9 - Capacidade horaria da maquina (com hora extra opcional)
# ---------------------------------------------------------------------
# horas_usadas = sum(producao * tempo_unitario) por maquina
# horas_usadas <= (cap_h - manut) * eff * a[t,f,r] + ex[t,f,r]
#                  ^         ^      ^      ^                ^
#                  |         |      |      |                +-- horas extras
#                  |         |      |      +-- BINARIA: se a=0, cap=0
#                  |         |      +-- eficiencia (=1.0 default)
#                  |         +-- horas de manutencao (subtraidas)
#                  +-- capacidade base (=50 h/periodo)
#
# R9_ex_cap impede pedir hora extra se a maquina nem esta ativa (ex<=10*a).
# Hora extra custa R$ 100/h - cara, entao o solver evita.
# =====================================================================
s.t. R9_cap{t in T, f in F, r in MAQ_F[f]}:
    sum{y in Y: (f,y,r) in PROD_MAQ} pr[t,f,y,r] * temp[f,y,r]
    <= (cap_h - manut[f,r,t]) * eff[f,r,t] * a[t,f,r] + ex[t,f,r];

s.t. R9_ex_cap{t in T, f in F, r in MAQ_F[f]}:
    ex[t,f,r] <= ex_cap[f,r,t] * a[t,f,r];

# =====================================================================
# R10a / R10b - Linha de producao sequencial (CRITICO)
# ---------------------------------------------------------------------
# Este eh o ponto que a Parte 1 do trabalho violou.
#
# R10a (ativacao conjunta): se a linha F1 esta ligada, AS DUAS maquinas
# (RA e RB) estao ligadas - paga custo fixo das duas. A variavel auxiliar
# aLine[t,f] e o "interruptor da linha" - quando =1, forca a[t,f,RA]=1
# e a[t,f,RB]=1. Idem para F2 (RC e RD).
#
# R10b (fluxo sequencial): a mesma peca passa por RA e depois por RB.
# Nao sao maquinas paralelas - sao em LINHA. Producao em RA = producao
# em RB (a peca atravessa as duas). Capacidade efetiva da linha cai pela
# metade vs paralelo: min(cap_RA, cap_RB) ao inves de cap_RA + cap_RB.
# =====================================================================
s.t. R10a_F1A{t in T}: a[t,'F1','RA'] = aLine[t,'F1'];
s.t. R10a_F1B{t in T}: a[t,'F1','RB'] = aLine[t,'F1'];
s.t. R10a_F2C{t in T}: a[t,'F2','RC'] = aLine[t,'F2'];
s.t. R10a_F2D{t in T}: a[t,'F2','RD'] = aLine[t,'F2'];

s.t. R10b_F1{t in T, y in Y: ('F1',y,'RA') in PROD_MAQ and ('F1',y,'RB') in PROD_MAQ}:
    pr[t,'F1',y,'RA'] = pr[t,'F1',y,'RB'];
s.t. R10b_F2{t in T, y in Y: ('F2',y,'RC') in PROD_MAQ and ('F2',y,'RD') in PROD_MAQ}:
    pr[t,'F2',y,'RC'] = pr[t,'F2',y,'RD'];

# =====================================================================
# R11 - Lotes inteiros (producao em multiplos de lote_Y; compra de X em
#       multiplos de lote_X)
# ---------------------------------------------------------------------
# Y1 so e produzido em lotes de 5 unidades (lote_Y[F,Y1]=5). Y2 e
# unitario (lote_Y[F,Y2]=1). X eh comprado em lotes de 10 unidades
# (lote_X[V,X]=10).
#
# Como impor isso em MILP? Introduzindo uma variavel auxiliar inteira
# pr_lot[t,f,y,r] (o "k" da matematica) e fazendo:
#       pr = lote_Y * pr_lot
# Como pr_lot e inteira (pode ser 0, 1, 2, 3, ...), pr so pode ser 0,
# lote_Y, 2*lote_Y, 3*lote_Y, ... (multiplos do lote).
#
# Mesmo principio para compras: cb_X = lote_X * cb_X_lot.
# Corrige a violacao da Parte 1, que tinha Y1 = 11 (nao-multiplo de 5).
# =====================================================================
s.t. R11_pr{t in T, f in F, y in Y, r in R: (f,y,r) in PROD_MAQ}:
    pr[t,f,y,r] = lote_Y[f,y] * pr_lot[t,f,y,r];
s.t. R11_cb{t in T, x in X, v in V}:
    cb_X[t,x,v] = lote_X[v,x] * cb_X_lot[t,x,v];

# =====================================================================
# R12 - Disponibilidade contratual do fornecedor
# ---------------------------------------------------------------------
# Nao da pra comprar mais do que o fornecedor consegue entregar. O
# parametro disp[t,produto,fornecedor] e o limite superior do contrato.
# Se V1 so pode entregar 80 un de X1 no periodo 1, entao
# cb_X[1,X1,V1] <= 80. Modela escassez de oferta.
#
# Duas restricoes separadas (R12_X e R12_Y) porque X e Y sao variaveis
# diferentes (cb_X vs cb_Y).
# =====================================================================
s.t. R12_X{t in T, x in X, v in V}:  cb_X[t,x,v] <= disp[t,x,v];
s.t. R12_Y{t in T, y in Y, v in V}:  cb_Y[t,y,v] <= disp[t,y,v];

# =====================================================================
# R13 - Encadeamento compra <-> transporte (consistencia cruzada)
# ---------------------------------------------------------------------
# "Tudo que e comprado tem que ser transportado, e vice-versa."
#
# Em palavras: para cada (t, x, v), o total comprado de X no fornecedor v
# (cb_X[t,x,v]) tem que ser EXATAMENTE igual ao que sai de v como
# transporte tx para qualquer fabrica/modal:
#       cb_X[t,x,v] = sum{f, m} tx[t,x,v,f,m]
#
# Se voce comprou 60 un de X1 de V1, entao a soma de tx[1,X1,V1,*,*]
# tem que dar 60 - distribuidos entre F1/F2 e modais M1/M2 como o solver
# preferir, mas o TOTAL bate.
#
# Por que isso e importante? Porque na Parte 1 (planilhas), os sub-times
# G1 (compras) e G3 (logistica) decidiam separadamente. Era possivel
# "comprar" 60 un e so "transportar" 50 (sumir 10 no caminho). A R13
# IMPEDE essa inconsistencia - sem ela, o modelo seria fisicamente
# impossivel.
# =====================================================================
s.t. R13_X{t in T, x in X, v in V}:
    cb_X[t,x,v] = sum{f in F, m in M} tx[t,x,v,f,m];
s.t. R13_Y{t in T, y in Y, v in V}:
    cb_Y[t,y,v] = sum{f in F, m in M} ty_VF[t,y,v,f,m];

# R14 - dominio (ja declarado nas variaveis: integer/binary/>=0)

solve;

# =====================================================================
# RELATORIO DE SAIDA
# =====================================================================
printf "\n===== RESULTADO MILP S&OP =====\n";
printf "Fator demanda: %.2f\n", fator_demanda;
printf "Variante:      %s\n", if USAR_BIG_M = 1 then "COM Big-M" else "SEM Big-M (R1 estrita)";
printf "\nLucro: R$ %.2f\n", Z;
printf "Nao-entregas:  %d\n", sum{t in T, c in C, y in Y} n[t,c,y];
printf "Receita liquida: R$ %.2f\n", receita;
printf "Custo de compras: R$ %.2f\n", custo_compra;
printf "Custo logistico:  R$ %.2f\n", custo_log;
printf "Custo variavel:   R$ %.2f\n", custo_var_prod;
printf "Custo fixo:       R$ %.2f\n", custo_fixo;
printf "Custo extra:      R$ %.2f\n", custo_extra;
printf "Custo estoque:    R$ %.2f\n", custo_estoque;

printf "\n--- Producao otima por (t, f, y, r) ---\n";
for {t in T, f in F, y in Y, r in R: (f,y,r) in PROD_MAQ and pr[t,f,y,r] > 0}
    printf "  P%d  %s  %s  %s = %d un.\n", t, f, y, r, pr[t,f,y,r];

printf "\n--- Compras de componentes (t, x, v) ---\n";
for {t in T, x in X, v in V: cb_X[t,x,v] > 0}
    printf "  P%d  %s  %s = %d un.\n", t, x, v, cb_X[t,x,v];

printf "\n--- Ativacao de maquinas (t, f, r) ---\n";
for {t in T, f in F, r in MAQ_F[f]: a[t,f,r] = 1}
    printf "  P%d  %s  %s  ativa  (ex = %.1f h)\n", t, f, r, ex[t,f,r];

end;
