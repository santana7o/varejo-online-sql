"""
Etapa 6 - Exporta os dados do dashboard web.
Saida: docs/dados.js, com os resultados das consultas lidos por docs/index.html.
"""
from pathlib import Path
import json

import pandas as pd

RAIZ = Path(__file__).resolve().parents[1]
RES = RAIZ / "resultados"
DOCS = RAIZ / "docs"

CONSULTAS = {
    "kpis": "02_kpis_anuais.csv",
    "receita_mensal": "03_receita_mensal.csv",
    "novos_recorrentes": "04_novos_vs_recorrentes.csv",
    "coortes": "05_coortes_retencao.csv",
    "rfm": "06_rfm_segmentacao.csv",
    "cancelamentos": "08_cancelamentos.csv",
    "paises": "10_paises.csv",
    "validacao_rfm": "12_validacao_rfm.csv",
    "dimensionamento": "13_dimensionamento_reativacao.csv",
    "lista_reativacao": "14_lista_reativacao.csv",
}


def exportar_web():
    DOCS.mkdir(exist_ok=True)
    dados = {}
    for chave, arquivo in CONSULTAS.items():
        df = pd.read_csv(RES / arquivo)
        dados[chave] = json.loads(df.to_json(orient="records", force_ascii=False))
    texto = "window.DADOS = " + json.dumps(dados, ensure_ascii=False, separators=(",", ":")) + ";\n"
    (DOCS / "dados.js").write_text(texto, encoding="utf-8")
    print(f"ok docs/dados.js ({len(texto) / 1024:.0f} KB)")


if __name__ == "__main__":
    exportar_web()
