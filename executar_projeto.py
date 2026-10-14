"""Executa o projeto inteiro: dados -> SQL -> testes -> graficos -> relatorio Excel -> dashboard."""
import runpy
from pathlib import Path

ETAPAS = [
    "01_preparar_dados",
    "02_rodar_analises",
    "03_testar_dados",
    "04_gerar_graficos",
    "05_gerar_relatorio_excel",
    "06_exportar_dashboard",
]

for etapa in ETAPAS:
    print(f"\n=== {etapa} ===")
    runpy.run_path(str(Path(__file__).parent / "scripts" / f"{etapa}.py"), run_name="__main__")
