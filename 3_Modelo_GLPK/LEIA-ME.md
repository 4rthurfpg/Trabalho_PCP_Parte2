# 4_GLPK_Cenarios — Arquivos prontos para execução

Pasta com o modelo MILP em GMPL pronto para rodar no GUSEK (ou via
linha de comando com `glpsol`) **sem precisar regenerar nada**.

## Estrutura

| Arquivo                       | Função                                                   |
| ----------------------------- | -------------------------------------------------------- |
| `sop_milp.mod`                | **Modelo** (estrutura) — idêntico para os três cenários  |
| `cenario_mais_provavel.dat`   | Dados do cenário Mais Provável (fator demanda 1,00)      |
| `cenario_otimista.dat`        | Dados do cenário Otimista (fator demanda 1,10 / +10 %)   |
| `cenario_pessimista.dat`      | Dados do cenário Pessimista (fator demanda 0,80 / −20 %) |

O `.mod` define conjuntos, parâmetros, variáveis, função objetivo e
as 14 restrições. Os `.dat` carregam só os dados de cada cenário —
diferem entre si essencialmente no `param fator_demanda`.

## Como rodar

### Pelo GUSEK (interface gráfica)
1. Abra `sop_milp.mod` no GUSEK.
2. `Tools → Use Data File...` e selecione um dos `cenario_*.dat`.
3. `Tools → Go (Ctrl+F5)` — o relatório aparece na aba de saída.

Para trocar de cenário, basta repetir o passo 2 com outro `.dat` e
rodar de novo — não precisa reabrir o `.mod`.

### Pelo terminal (glpsol)
```bash
glpsol -m sop_milp.mod -d cenario_mais_provavel.dat -o resultado_mais_provavel.txt
glpsol -m sop_milp.mod -d cenario_otimista.dat     -o resultado_otimista.txt
glpsol -m sop_milp.mod -d cenario_pessimista.dat   -o resultado_pessimista.txt
```

## Variante (Big-M)

Todos os `.dat` saem com `USAR_BIG_M := 1` (FO com penalidade Big-M = 10⁴).
Para gerar a variante sem Big-M (R1 estrita), use o `gerar_dat.py` em
`3_Modelo_GUSEK/` com a flag `--no-big-m`.

## Resultado esperado

| Cenário        | Lucro ótimo  | Não-entregas |
| -------------- | ------------ | ------------ |
| Mais Provável  | R$ 1.380,00  | 0            |
| Otimista       | R$ 1.590,00  | 0            |
| Pessimista     | R$ 1.095,00  | 0            |
