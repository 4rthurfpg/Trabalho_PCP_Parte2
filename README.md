# PCP — Planejamento Integrado da Cadeia de Suprimentos (S&OP)

**UFMG / DEP — EPD035 — Prof. João Flávio**
**Trabalho Parte 2 — Grupo 1**
Pesquisa Operacional aplicada a um modelo MILP de S&OP para uma cadeia de bioetanol em barris (V → F → DC → C, 2 períodos, 3 cenários).

[![Solver: GLPK](https://img.shields.io/badge/solver-GLPK-blue)](https://www.gnu.org/software/glpk/)
[![Modelo: GMPL](https://img.shields.io/badge/modelo-GMPL%2FMathProg-darkgreen)](https://www.gnu.org/software/glpk/)
[![IDE: GUSEK](https://img.shields.io/badge/IDE-GUSEK-orange)](http://gusek.sourceforge.net/)

---

## Sumário

1. [Estrutura do repositório](#estrutura-do-repositório)
2. [Como rodar (GUSEK)](#como-rodar-gusek)
3. [Resultados-chave](#resultados-chave)
4. [Modelo MILP em uma página](#modelo-milp-em-uma-página)
5. [Como reproduzir o relatório](#como-reproduzir-o-relatório)

---

## Estrutura do repositório

```
Entrega - PCP (revisado 2.5)/
├── 1_Relatorio/                  # Entregável principal
│   ├── Relatorio_Parte2.pdf      # PDF oficial (LaTeX)
│   ├── main.tex                  # Fonte LaTeX
│   ├── referencias.bib           # Bibliografia BibTeX
│   ├── front.html                # Versão interativa (KaTeX + análise paramétrica)
│   └── front_projetor.html       # Versão otimizada para projetor
├── 2_Modelo_MILP/                # Dados e resultados
│   ├── arquivo_base.xlsx         # Parâmetros do problema
│   ├── Resultados_Otimos.xlsx    # Resultados por cenário
│   └── resultados.json           # Saída bruta do solver
├── 3_Modelo_GLPK/                # Modelo GMPL pronto para GUSEK
│   ├── sop_milp.mod              # Modelo (estrutura + 14 restrições)
│   ├── cenario_mais_provavel.dat # Dados — fator 1,00
│   ├── cenario_otimista.dat      # Dados — fator 1,10
│   ├── cenario_pessimista.dat    # Dados — fator 0,80
│   └── LEIA-ME.md                # Como rodar no GUSEK
├── Apresentacao/                 # Slides macro (HTML)
├── Arquivos_Auxiliares/          # PDF alternativo + Overleaf
├── Overleaf_PCP_Parte2/          # Projeto LaTeX pronto para Overleaf
├── LEIA-ME.md                    # Guia geral em PT-BR
└── README.md                     # Este arquivo
```

## Como rodar (GUSEK)

[GUSEK](http://gusek.sourceforge.net/) é uma IDE Windows para o GLPK (já vem com `glpsol` embutido).

1. Instale o GUSEK.
2. **File → Open** → selecione `3_Modelo_GLPK/sop_milp.mod`.
3. **Tools → Use Data File...** → selecione um dos três `.dat`:
   - `cenario_mais_provavel.dat` — fator demanda 1,00
   - `cenario_otimista.dat` — fator demanda 1,10 (+10 %)
   - `cenario_pessimista.dat` — fator demanda 0,80 (−20 %)
4. **Tools → Go (Ctrl+F5)** — resultado aparece na aba de saída.

Para alternar entre cenários: trocar o `.dat` no passo 3 e rodar de novo (não precisa fechar o `.mod`).

### Alternativa via linha de comando (glpsol)

```bash
glpsol -m sop_milp.mod -d cenario_mais_provavel.dat -o resultado.txt
```

## Resultados-chave

| Cenário | Lucro | Status |
|---|---|---|
| Mais Provável | **R$ 1.380** | Optimal |
| Otimista (+10%) | **R$ 1.590** | Optimal |
| Pessimista (−20%) | **R$ 1.095** | Optimal |

- ✅ Demanda atendida 100% nos 3 cenários (n = 0 em todas as combinações)
- ✅ 14 famílias de restrições do enunciado respeitadas, incluindo:
  - **R10a** (ativação conjunta das máquinas da linha)
  - **R10b** (fluxo sequencial RA→RB / RC→RD)
  - **R11** (lotes: Y₁ múltiplo de 5; X múltiplo de 10)
- ✅ Solver retorna status **Optimal** em < 10s/cenário
- ✅ Big-M (M=10⁴) como rede de segurança; nos 3 cenários, n = 0 (demanda 100% atendida)
- ✅ Custo de hora extra: R$ 100/h

## Modelo MILP em uma página

**Objetivo**: maximizar lucro operacional
$$ Z = R - (C_{compra} + C_{log} + C_{var} + C_{fixo} + C_{extra} + C_{est}) $$

**Variáveis principais**:
- `tx[t,x,v,f,m]` — transporte de componentes
- `ty[t,y,o,d,m]` — transporte de acabados (3 sub-grafos)
- `cb[t,p,v]` — compras
- `pr[t,f,y,r]` — produção por máquina
- `a[t,f,r]`, `aLine[t,f]` — ativações binárias
- `if/icd` — estoques

**Restrições** (14 famílias): demanda, capacidade de modal/CD, estoque min/max/final, balanço, BOM, capacidade horária, linha (ativação + fluxo sequencial), lotes, disponibilidade de fornecedor, encadeamento compra↔transporte, domínio.

Detalhamento completo em `1_Relatorio/Relatorio_Parte2.pdf`, seção "Método".

## Como reproduzir o relatório

```bash
cd 1_Relatorio
pdflatex main.tex
bibtex main
pdflatex main.tex
pdflatex main.tex
```

Ou faça upload de `Overleaf_PCP_Parte2/` em https://www.overleaf.com → New Project → Upload Project.

## Referências

[1] Makhorin, A. *GNU Linear Programming Kit — Reference Manual*. Free Software Foundation, 2015.
[2] Shapiro, J. F. *Modeling the Supply Chain*. 2nd ed. Nelson Education, 2006.
[3] Pochet, Y. & Wolsey, L. A. *Production Planning by Mixed Integer Programming*. Springer, 2006.
[4] Lapide, L. *Sales and Operations Planning, Parts I-III*. Journal of Business Forecasting, 2004-2005.
[5] Almeida, J. F. F. et al. *Flexibility evaluation of multiechelon supply chains*. PLoS ONE 13(3), 2018.

---

**Apresentado por**: Grupo 1 (23 integrantes; sub-times G1-G5)
**Contato**: eduardo.toledo@iebtinnovation.com
