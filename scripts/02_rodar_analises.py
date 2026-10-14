"""
Etapa 2 - Executa a modelagem (sql/00) e todas as consultas de analise (sql/01..).
Cada consulta gera um CSV em resultados/ com o mesmo nome do arquivo .sql.
"""
from pathlib import Path

import duckdb

RAIZ = Path(__file__).resolve().parents[1]
SQL = RAIZ / "sql"
RESULTADOS = RAIZ / "resultados"
DB = RAIZ / "data" / "varejo.duckdb"


def main():
    RESULTADOS.mkdir(exist_ok=True)
    con = duckdb.connect(str(DB))

    print("Modelagem: 00_modelagem.sql")
    con.execute((SQL / "00_modelagem.sql").read_text(encoding="utf-8"))

    for arquivo in sorted(SQL.glob("[0-9][0-9]_*.sql")):
        if arquivo.name.startswith("00_"):
            continue
        df = con.execute(arquivo.read_text(encoding="utf-8")).df()
        destino = RESULTADOS / f"{arquivo.stem}.csv"
        df.to_csv(destino, index=False)
        print(f"{arquivo.name:<32} -> {destino.name} ({len(df)} linhas)")

    con.close()


if __name__ == "__main__":
    main()
