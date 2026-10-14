"""
Etapa 4 - Gera os graficos do README a partir dos CSVs em resultados/.
Saida: assets/*.png
"""
from pathlib import Path

import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import matplotlib.ticker as mtick
from matplotlib.colors import LinearSegmentedColormap
import pandas as pd

RAIZ = Path(__file__).resolve().parents[1]
RES = RAIZ / "resultados"
ASSETS = RAIZ / "assets"

# Paleta (azul = serie principal, laranja = comparacao, cinza = contexto)
AZUL, LARANJA, CINZA = "#2a78d6", "#eb6834", "#a3a29c"
TEXTO, TEXTO_2, GRADE, FUNDO = "#0b0b0b", "#52514e", "#e6e5e0", "#fcfcfb"
SEQ = LinearSegmentedColormap.from_list("seq", ["#eef4fc", "#9cc2ef", "#2a78d6", "#123d73"])

plt.rcParams.update({
    "figure.facecolor": FUNDO, "axes.facecolor": FUNDO, "savefig.facecolor": FUNDO,
    "font.family": "DejaVu Sans", "font.size": 10,
    "axes.edgecolor": GRADE, "axes.labelcolor": TEXTO_2, "axes.titlecolor": TEXTO,
    "axes.titlesize": 13, "axes.titleweight": "bold", "axes.titlelocation": "left",
    "axes.spines.top": False, "axes.spines.right": False, "axes.spines.left": False,
    "axes.grid": True, "axes.grid.axis": "y", "grid.color": GRADE, "grid.linewidth": 0.8,
    "xtick.color": TEXTO_2, "ytick.color": TEXTO_2, "xtick.major.size": 0, "ytick.major.size": 0,
    "legend.frameon": False, "legend.fontsize": 9,
})

MESES = ["dez", "jan", "fev", "mar", "abr", "mai", "jun", "jul", "ago", "set", "out", "nov"]
NOMES_MES = ["jan", "fev", "mar", "abr", "mai", "jun", "jul", "ago", "set", "out", "nov", "dez"]


def rotulo_mes(aaaa_mm):
    """'2010-01' -> 'jan/10' (evita confundir 10/01 com dia/mes)."""
    ano, mes = aaaa_mm.split("-")
    return f"{NOMES_MES[int(mes) - 1]}/{ano[2:]}"


def libras_mil(x, _):
    return f"£{x/1000:,.0f} mil".replace(",", ".")


def salvar(fig, nome, subtitulo=None):
    ax = fig.axes[0]
    ax.set_title(ax.get_title(loc="left"), loc="left", pad=24 if subtitulo else 10)
    if subtitulo:
        ax.text(0, 1.02, subtitulo, transform=ax.transAxes, color=TEXTO_2, fontsize=9.5,
                ha="left", va="bottom")
    fig.savefig(ASSETS / nome, dpi=160, bbox_inches="tight")
    plt.close(fig)
    print("ok", nome)


def receita_mensal():
    df = pd.read_csv(RES / "03_receita_mensal.csv")
    ano1, ano2 = df.iloc[:12], df.iloc[12:24]
    fig, ax = plt.subplots(figsize=(10, 4.6))
    ax.plot(MESES, ano1.receita, color=CINZA, lw=2, marker="o", ms=5, label="Ano 1 (dez/09-nov/10)")
    ax.plot(MESES, ano2.receita, color=AZUL, lw=2.4, marker="o", ms=6, label="Ano 2 (dez/10-nov/11)")
    ax.annotate("set-nov: 37% da receita do ano", xy=(11, ano2.receita.iloc[-1]), xytext=(6.2, 1.38e6),
                color=TEXTO_2, fontsize=9, arrowprops=dict(arrowstyle="-", color=CINZA, lw=0.8))
    ax.yaxis.set_major_formatter(mtick.FuncFormatter(libras_mil))
    ax.set_ylim(0, 1.6e6)
    ax.set_title("Receita mensal: forte sazonalidade de fim de ano")
    ax.legend(loc="upper left", ncols=2)
    salvar(fig, "01_receita_mensal.png", "Receita de vendas validas por mes, ano 1 vs ano 2")


def novos_clientes():
    df = pd.read_csv(RES / "04_novos_vs_recorrentes.csv")
    fig, ax = plt.subplots(figsize=(10, 4.4))
    cores = [CINZA if m < "2010-12" else AZUL for m in df.mes]
    ax.bar(df.mes, df.clientes_novos, color=cores, width=0.75)
    ax.set_xticks(range(len(df)))
    ax.set_xticklabels([rotulo_mes(m) if i % 2 == 0 else "" for i, m in enumerate(df.mes)], fontsize=8)
    ax.set_title("Clientes novos por mes: aquisicao caiu no ano 2")
    for i in (8, 9, 10, 20, 21, 22):
        ax.text(i, df.clientes_novos.iloc[i] + 8, int(df.clientes_novos.iloc[i]),
                ha="center", fontsize=8, color=TEXTO_2)
    ax.text(0.99, 0.92, "set-nov: 940 (2010) vs 600 (2011), -36%", transform=ax.transAxes,
            ha="right", color=TEXTO, fontsize=9.5)
    salvar(fig, "02_clientes_novos.png",
           "Clientes que fizeram a primeira compra no mes (cinza = ano 1, azul = ano 2)")


def coortes():
    df = pd.read_csv(RES / "05_coortes_retencao.csv")
    tab = df.pivot(index="coorte", columns="meses_desde_entrada", values="retencao_pct")
    tam = df.groupby("coorte").tamanho_coorte.first()
    tab = tab.drop(columns=0)
    fig, ax = plt.subplots(figsize=(10.5, 5.2))
    ax.imshow(tab.values, cmap=SEQ, vmin=0, vmax=35, aspect="auto")
    for i in range(tab.shape[0]):
        for j in range(tab.shape[1]):
            v = tab.values[i, j]
            if pd.notna(v):
                ax.text(j, i, f"{v:.0f}", ha="center", va="center", fontsize=8,
                        color="white" if v > 22 else TEXTO)
    ax.set_xticks(range(tab.shape[1]), [f"M{c}" for c in tab.columns])
    ax.set_yticks(range(tab.shape[0]), [f"{rotulo_mes(c)}  (n={tam[c]})" for c in tab.index])
    ax.grid(False)
    ax.set_title("Retencao por coorte de primeira compra (%)")
    salvar(fig, "03_coortes_retencao.png",
           "% dos clientes de cada coorte que compraram de novo N meses depois")


def rfm():
    df = pd.read_csv(RES / "06_rfm_segmentacao.csv").iloc[::-1]
    nomes = [s.split(". ", 1)[1] for s in df.segmento]
    y = range(len(df))
    fig, ax = plt.subplots(figsize=(10, 4.6))
    ax.barh([i + 0.2 for i in y], df.pct_clientes, height=0.38, color=CINZA, label="% dos clientes")
    ax.barh([i - 0.2 for i in y], df.pct_receita, height=0.38, color=AZUL, label="% da receita")
    for i, (c, r) in enumerate(zip(df.pct_clientes, df.pct_receita)):
        ax.text(c + 0.6, i + 0.2, f"{c:.0f}%", va="center", fontsize=8, color=TEXTO_2)
        ax.text(r + 0.6, i - 0.2, f"{r:.0f}%", va="center", fontsize=8, color=TEXTO)
    ax.set_yticks(list(y), nomes)
    ax.grid(axis="x", color=GRADE)
    ax.grid(axis="y", visible=False)
    ax.xaxis.set_major_formatter(mtick.PercentFormatter(decimals=0))
    ax.set_title("Segmentos RFM: 22% dos clientes geram 64% da receita")
    ax.legend(loc="lower right")
    salvar(fig, "04_rfm.png", "Clientes identificados, ultimos 12 meses (dez/10-dez/11)")


def pareto():
    df = pd.read_csv(RES / "07_pareto_produtos.csv")
    a = df[df.classe_abc == "A"].iloc[-1]
    fig, ax = plt.subplots(figsize=(10, 4.6))
    ax.plot(df.pct_produtos_acumulado, df.pct_receita_acumulada, color=AZUL, lw=2.4)
    ax.axhline(80, color=CINZA, lw=1, ls="--")
    ax.scatter([a.pct_produtos_acumulado], [a.pct_receita_acumulada], s=60, color=AZUL,
               edgecolor=FUNDO, linewidth=2, zorder=3)
    ax.annotate(f"{int(a.ranking)} produtos ({a.pct_produtos_acumulado:.0f}% do catalogo)\n= 80% da receita",
                xy=(a.pct_produtos_acumulado, 80), xytext=(32, 55), fontsize=9.5, color=TEXTO,
                arrowprops=dict(arrowstyle="-", color=CINZA, lw=0.8))
    ax.xaxis.set_major_formatter(mtick.PercentFormatter(decimals=0))
    ax.yaxis.set_major_formatter(mtick.PercentFormatter(decimals=0))
    ax.set_xlim(0, 100)
    ax.set_ylim(0, 102)
    ax.set_xlabel("% acumulado de produtos (do mais vendido ao menos vendido)")
    ax.set_title("Curva ABC de produtos")
    salvar(fig, "05_pareto_produtos.png", "% acumulado da receita, ano 2 (dez/10-nov/11)")


def cancelamentos():
    df = pd.read_csv(RES / "08_cancelamentos.csv")
    fig, ax = plt.subplots(figsize=(10, 4.2))
    ax.plot(df.mes, df.taxa_cancelamento_pct, color=AZUL, lw=2, marker="o", ms=5)
    ax.axhline(df.taxa_cancelamento_pct.median(), color=CINZA, lw=1, ls="--")
    i = df.taxa_cancelamento_pct.idxmax()
    ax.annotate("jan/11: um unico pedido de 74 mil potes\nvendido e cancelado no mesmo dia",
                xy=(i, df.taxa_cancelamento_pct[i]), xytext=(i + 1.5, 11), fontsize=9, color=TEXTO,
                arrowprops=dict(arrowstyle="-", color=CINZA, lw=0.8))
    ax.set_xticks(range(len(df)))
    ax.set_xticklabels([rotulo_mes(m) if i % 2 == 0 else "" for i, m in enumerate(df.mes)], fontsize=8)
    ax.yaxis.set_major_formatter(mtick.PercentFormatter(decimals=0))
    ax.set_title("Taxa de cancelamento mensal")
    salvar(fig, "06_cancelamentos.png", f"Valor cancelado / receita bruta do mes. Tracejado = mediana ({df.taxa_cancelamento_pct.median():.1f}%)")


def dia_hora():
    df = pd.read_csv(RES / "11_dia_hora.csv")
    df = df[(df.hora >= 7) & (df.hora <= 20)]
    tab = df.pivot_table(index=["dia_semana_num", "dia_semana"], columns="hora",
                         values="pedidos", aggfunc="sum").fillna(0)
    fig, ax = plt.subplots(figsize=(10, 3.8))
    ax.imshow(tab.values, cmap=SEQ, aspect="auto")
    ax.set_yticks(range(len(tab)), [d for _, d in tab.index])
    ax.set_xticks(range(tab.shape[1]), [f"{h}h" for h in tab.columns])
    ax.grid(False)
    ax.set_title("Pedidos por dia da semana e hora")
    salvar(fig, "07_dia_hora.png", "Pico entre 10h e 15h, de terca a quinta. Quase nenhum pedido aos sabados")


def paises():
    df = pd.read_csv(RES / "10_paises.csv")
    df = df[df.pais != "United Kingdom"].head(10).iloc[::-1]
    fig, ax = plt.subplots(figsize=(10, 4.6))
    ax.barh(df.pais, df.receita, color=AZUL, height=0.6)
    for i, (r, t) in enumerate(zip(df.receita, df.ticket_medio)):
        ax.text(r + 3000, i, f"ticket £{t:,.0f}".replace(",", "."), va="center", fontsize=8, color=TEXTO_2)
    ax.xaxis.set_major_formatter(mtick.FuncFormatter(libras_mil))
    ax.grid(axis="x", color=GRADE)
    ax.grid(axis="y", visible=False)
    ax.set_title("Fora do Reino Unido: 15% da receita (top 10 paises)")
    salvar(fig, "08_paises.png", "Receita e ticket medio por pedido, ano 2. Ticket medio no Reino Unido: £475")


def validacao_rfm():
    df = pd.read_csv(RES / "12_validacao_rfm.csv").iloc[::-1].reset_index(drop=True)
    nomes = [s.split(". ", 1)[1] for s in df.segmento]
    fig, ax = plt.subplots(figsize=(10, 4.6))
    for i, row in df.iterrows():
        destaque = row.segmento.startswith("4.")
        cor = LARANJA if destaque else AZUL
        ax.plot([row.receita_antes_por_cliente, row.receita_depois_por_cliente], [i, i],
                color=cor if destaque else GRADE, lw=3 if destaque else 2, zorder=1)
        ax.scatter(row.receita_antes_por_cliente, i, s=55, color=CINZA, zorder=2)
        ax.scatter(row.receita_depois_por_cliente, i, s=70, color=cor, zorder=3)
        x_txt = max(row.receita_antes_por_cliente, row.receita_depois_por_cliente) + 150
        ax.text(x_txt, i, f"{row.pct_voltou_a_comprar:.0f}% voltaram  |  receita/cliente {row.var_receita_por_cliente_pct:+.0f}%",
                va="center", fontsize=8.5, color=TEXTO if destaque else TEXTO_2,
                fontweight="bold" if destaque else "normal")
    ax.set_yticks(range(len(df)), nomes)
    ax.scatter([], [], s=55, color=CINZA, label="12 meses antes de dez/10")
    ax.scatter([], [], s=70, color=AZUL, label="12 meses depois")
    ax.xaxis.set_major_formatter(mtick.FuncFormatter(lambda x, _: f"£{x:,.0f}".replace(",", ".")))
    ax.set_xlim(0, 9000)
    ax.grid(axis="x", color=GRADE)
    ax.grid(axis="y", visible=False)
    ax.legend(loc="lower right")
    ax.set_title("Validacao do RFM: os segmentos preveem o ano seguinte")
    salvar(fig, "09_validacao_rfm.png",
           "Receita por cliente antes e depois de segmentar em dez/2010. 'Em risco' perde metade do valor")


if __name__ == "__main__":
    ASSETS.mkdir(exist_ok=True)
    receita_mensal()
    novos_clientes()
    coortes()
    rfm()
    pareto()
    cancelamentos()
    dia_hora()
    paises()
    validacao_rfm()
