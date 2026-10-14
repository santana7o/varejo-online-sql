"""
Etapa 3 - Roda os testes de dados (sql/testes/testes_dados.sql) sobre o banco ja modelado.
Encerra com erro se alguma regra falhar, para que nenhum resultado seja publicado com dados quebrados.
"""
from pathlib import Path
import sys

import duckdb

RAIZ = Path(__file__).resolve().parents[1]
TESTES = RAIZ / "sql" / "testes" / "testes_dados.sql"
DB = RAIZ / "data" / "varejo.duckdb"


def main():
    con = duckdb.connect(str(DB), read_only=True)
    resultados = con.execute(TESTES.read_text(encoding="utf-8")).fetchall()
    con.close()

    falhas = 0
    for teste, ok in resultados:
        print(f"{'ok   ' if ok else 'FALHA'}  {teste}")
        falhas += not ok
    print(f"\n{len(resultados) - falhas}/{len(resultados)} testes passaram")
    if falhas:
        sys.exit(1)


if __name__ == "__main__":
    main()
