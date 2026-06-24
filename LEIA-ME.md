# Entrega — Trabalho PCP (EPD035) — Parte 2 [revisão 2.5]
**Grupo 1** — Planejamento Integrado da Cadeia de Suprimentos
(23 integrantes; sub-times funcionais G1 compras, G2 produção, G3 estoques/transporte, G4 entrega, G5 financeiro)

---

## 📋 Estrutura da entrega

### `1_Relatorio/` — Relatório executivo (entregável principal)

| Arquivo | O que é |
|---|---|
| **`Relatorio_Parte2.pdf`** | PDF oficial compilado em LaTeX — capa, resumo, 5 seções (Contexto / Método / Resultados / Discussão / Conclusão), tabelas de parâmetros e restrições R1–R14 descritas individualmente, bibliografia |
| **`main.tex`** | Código-fonte LaTeX do relatório |
| **`referencias.bib`** | Bibliografia BibTeX |
| **`front.html`** | Versão interativa do relatório — tema escuro, KaTeX para fórmulas, navegação por abas, **análise paramétrica em tempo real** (4 sliders + tornado chart + varredura interativa) |
| **`front_projetor.html`** | Versão otimizada para projetor (mesma análise paramétrica) |

### `2_Modelo_MILP/` — Dados de entrada e resultados ótimos

| Arquivo | O que é |
|---|---|
| **`arquivo_base.xlsx`** | Parâmetros do problema (vendas, modal, ei, es, em, ef, bom, lote, cap, eff, etc.) |
| **`Resultados_Otimos.xlsx`** | Resultados ótimos por cenário + aba "Comparativo P1 vs P2" |
| **`resultados.json`** | Saída bruta do solver (3 cenários) |

### `3_Modelo_GLPK/` — **Modelo pronto para apresentação no GUSEK** ⭐

| Arquivo | O que é |
|---|---|
| **`sop_milp.mod`** | Modelo em GNU MathProg — 14 famílias de restrições, função objetivo |
| **`cenario_mais_provavel.dat`** | Dados do cenário Mais Provável (fator demanda 1,00) |
| **`cenario_otimista.dat`** | Dados do cenário Otimista (fator demanda 1,10 / +10 %) |
| **`cenario_pessimista.dat`** | Dados do cenário Pessimista (fator demanda 0,80 / −20 %) |
| **`LEIA-ME.md`** | Passo-a-passo para rodar no GUSEK |

### `Apresentacao/` — Slides macro

| Arquivo | O que é |
|---|---|
| **`Slides_Apresentacao.html`** | Deck 10 slides em HTML (tema escuro) — visão geral macro para a banca |

### `Arquivos_Auxiliares/` — Versões alternativas

| Arquivo | O que é |
|---|---|
| `Relatorio_Parte2_reportlab.pdf` | Versão alternativa do relatório; o oficial é o `1_Relatorio/Relatorio_Parte2.pdf` (LaTeX) |
| `LEIA-ME_Overleaf.md` | Instruções para reeditar o relatório no Overleaf |

### `Overleaf_PCP_Parte2/` — Projeto LaTeX para Overleaf

| Arquivo | O que é |
|---|---|
| `main.tex`, `referencias.bib`, `LEIA-ME.md` | Mesmo conteúdo de `1_Relatorio/`, organizado para upload direto no Overleaf |

---

## 🎯 Como apresentar / o que entregar ao professor

1. **PDF oficial**: `1_Relatorio/Relatorio_Parte2.pdf` — é o documento que o prof vai ler.
2. **Slides**: `Apresentacao/Slides_Apresentacao.html` — abrir no navegador.
3. **Versão online/interativa**: `1_Relatorio/front.html` — análise paramétrica em tempo real.
4. **Código ao vivo (demonstração no GUSEK)**:
   - Abrir `3_Modelo_GLPK/sop_milp.mod` no GUSEK
   - Carregar um dos 3 `.dat` em `Tools → Use Data File...`
   - `Tools → Go (Ctrl+F5)` → resultado aparece na aba de saída
   - Trocar de cenário = só trocar o `.dat`, sem reabrir o `.mod`

## 📊 Resultados-chave

| Cenário | Demanda | Receita líq. | Custos | **Lucro** |
|---|---|---|---|---|
| Mais Provável | 112 un. | R\$ 10.640 | R\$ 9.260 | **R\$ 1.380** |
| Otimista (+10%) | 124 un. | R\$ 11.780 | R\$ 10.190 | **R\$ 1.590** |
| Pessimista (−20%) | 95 un. | R\$ 8.455 | R\$ 7.360 | **R\$ 1.095** |

✅ Demanda 100% atendida (n=0 nos 3 cenários; Big-M é inócuo mas útil para robustez)
✅ Todas as 14 restrições do enunciado respeitadas, incluindo:
   - **R10a** (ativação conjunta): ambas as máquinas da linha pagam custo fixo
   - **R10b** (fluxo sequencial RA→RB / RC→RD)
   - **R_BOM** explícita (Y₁ = 2·X₁ + 1·X₂; Y₂ = 1·X₁ + 2·X₂)
✅ Big-M como rede de segurança (M=10⁴); na prática, n = 0 em todos os cenários
✅ Custo de hora extra: R\$ 100/h (parâmetro `c_ex`)
✅ Solver: GLPK [Makhorin, 2015]

## 🛠️ Como rodar no GUSEK (passo-a-passo)

1. Instale o [GUSEK](http://gusek.sourceforge.net/) (já vem com GLPK embutido).
2. Abra `3_Modelo_GLPK/sop_milp.mod` no GUSEK.
3. `Tools → Use Data File...` → selecione o `.dat` do cenário desejado.
4. `Tools → Go (Ctrl+F5)` — o relatório aparece na aba de saída.

Para alternar entre cenários: repita o passo 3 com outro `.dat` e rode de novo (não precisa reabrir o `.mod`).

## 🔍 Subir o relatório no Overleaf

Acesse https://www.overleaf.com → New Project → Upload Project → selecione `Overleaf_PCP_Parte2/`.

Saída esperada: 3 cenários com lucros R\$ 1.380 / R\$ 1.590 / R\$ 1.095 (linha RA→RB sequencial, Big-M=10⁴ ativo mas inócuo, hora extra R\$ 100/h).
