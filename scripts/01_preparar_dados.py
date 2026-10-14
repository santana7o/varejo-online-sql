"""
Etapa 1 - Baixa a base Online Retail II (UCI) e carrega no DuckDB.

Fonte: https://archive.ics.uci.edu/dataset/502/online+retail+ii (CC BY 4.0)
Saida: data/varejo.duckdb com a tabela raw_vendas (dados brutos, sem tratamento).
"""
from pathlib import Path
import urllib.error
import urllib.request
import zipfile

import duckdb
import pandas as pd

RAIZ = Path(__file__).resolve().parents[1]
DATA = RAIZ / "data"
URL = "https://archive.ics.uci.edu/static/public/502/online+retail+ii.zip"
ZIP = DATA / "online_retail_ii.zip"
XLSX = DATA / "online_retail_II.xlsx"
DB = DATA / "varejo.duckdb"


def baixar():
    DATA.mkdir(exist_ok=True)
    if not XLSX.exists():
        if not ZIP.exists():
            print("Baixando base da UCI (~45 MB)...")
            try:
                urllib.request.urlretrieve(URL, ZIP)
            except urllib.error.URLError as erro:
                ZIP.unlink(missing_ok=True)
                raise SystemExit(
                    f"Nao foi possivel baixar a base ({erro.reason}).\n"
                    "No Mac com Python do python.org, rode uma vez o 'Install Certificates.command'\n"
                    "da pasta /Applications/Python 3.x/. Ou baixe o zip manualmente em\n"
                    f"{URL}\ne salve em {ZIP}."
                ) from erro
        with zipfile.ZipFile(ZIP) as z:
            z.extractall(DATA)


def carregar():
    print("Lendo Excel (as duas abas, 2009-2010 e 2010-2011). Leva cerca de 30 segundos...")
    abas = pd.read_excel(XLSX, sheet_name=None, dtype={"Invoice": str, "StockCode": str})
    df = pd.concat(abas.values(), ignore_index=True)
    df.columns = ["invoice", "stock_code", "description", "quantity",
                  "invoice_date", "price", "customer_id", "country"]

    con = duckdb.connect(str(DB))
    con.execute("CREATE OR REPLACE TABLE raw_vendas AS SELECT * FROM df")
    n = con.execute("SELECT COUNT(*) FROM raw_vendas").fetchone()[0]
    con.close()
    print(f"raw_vendas carregada: {n:,} linhas em {DB.name}")


if __name__ == "__main__":
    baixar()
    carregar()
