# UBIQUITY プロジェクト

このリポジトリには、UBIQUITYプロジェクトの研究関連ファイルとコードが含まれています。

## ディレクトリ構成

- `analysis/`: pilotで抽出したデータを用いて実施したRスクリプトや分析結果など、データ分析に関連するファイルが含まれます。
    - `UBIQUITY_ADNMA.r`: ADNMA（Aggregate Data Network Meta-Analysis）の主要な実装コード。
    - `UBIQUITY_ADNMA_fixed.r`: 修正版ADNMAの実装コード。
    - `UBIQUITY_ADNMA_debug.r`: デバッグ用ADNMAコード。
    - `generate_results.Rmd`: 分析結果を生成するためのR Markdownファイル。
    - `render_to_reports.R`: `generate_results.Rmd`をレンダリングして`reports`ディレクトリにPDFを生成するスクリプト。
    - その他、分析結果のプロット（`.pdf`）やデータ（`.RData`）など。
- `data/`: 分析に使用するデータセットが含まれます。
- `reports/`: 分析結果のレポート（PDF）が生成されるディレクトリです。
    - `generate_results.pdf`: `generate_results.Rmd`から生成されたPDFレポート。
    - `generate_results_files/`: レポートに含まれる図表などのファイルが保存されるディレクトリ。
- `documents/`: 研究提案書、プロトコル、計画書、ToDoリストなどのドキュメントが含まれます。
    - `UBIQUITY_ADNMA/`: ADNMA関連のドキュメント。
        - `UBIQUITY_ADNMA_proposal.md`: ADNMAの研究提案書。
        - `UBIQUITY_ADNMA_protocol.md`: ADNMAの研究プロトコル。
        - `UBIQUITY_ADNMA_project_plan.md`: ADNMAのプロジェクト計画。
        - `UBIQUITY_ADNMA_protocol_review.md`: ADNMAプロトコルのレビュー。
    - `UBIQUITY_IPDNMA/`: IPDNMA（Individual Patient Data Network Meta-Analysis）関連のドキュメント。（内容は未確認）
    - `todo.md`: プロジェクト全体のタスクリスト。
    - `nma_protocol_template.md`: NMAプロトコルのテンプレート。
- `references/`: 参考文献や関連資料が含まれます。
- `README.md`: このファイル。プロジェクトの概要と構成について説明します。
- `.gitignore`: Gitで追跡しないファイルを指定します。

## 使用方法

### ADNMAの実行

分析を実行するには、`analysis/` ディレクトリ内のRスクリプトを使用します。

```r
# analysis ディレクトリに移動してから実行する場合
source("UBIQUITY_ADNMA.r")
# または修正版を使用
source("UBIQUITY_ADNMA_fixed.r")

# プロジェクトルートから実行する場合
source("analysis/UBIQUITY_ADNMA.r")
# または修正版を使用
source("analysis/UBIQUITY_ADNMA_fixed.r")
```

### 分析結果レポートの生成

分析結果のレポート（PDF）を生成するには、`analysis/` ディレクトリ内の `render_to_reports.R` スクリプトを使用します。

```bash
# analysis ディレクトリに移動してから実行する場合
cd analysis
Rscript render_to_reports.R

# プロジェクトルートから実行する場合
Rscript analysis/render_to_reports.R
```

または、直接 `rmarkdown::render` 関数を使用することもできます。

```r
# R コンソールから実行する場合
rmarkdown::render("analysis/generate_results.Rmd", output_file = "reports/generate_results.pdf")

# コマンドラインから実行する場合
Rscript -e "rmarkdown::render('analysis/generate_results.Rmd', output_file = 'reports/generate_results.pdf')"
```

生成されたPDFレポートは `reports/generate_results.pdf` に保存されます。

Rスクリプトの詳細な実行方法や、プロジェクトの詳細については `documents/` 内の各提案書やプロトコルを参照してください。
