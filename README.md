# UBIQUITY プロジェクト

このリポジトリには、UBIQUITYプロジェクトの研究提案書とコードが含まれています。

## ファイル構成

- `UBIQUITY_ADNMA_proposal.md`: ADNMA（Aggregate Data Network Meta-Analysis）の研究提案書
- `UBIQUITY_ADNMA.r`: ADNMAの実装コード
- `UBIQUITY_ADNMA_fixed.r`: 修正版ADNMAの実装コード
- `UBIQUITY_ADNMA_debug.r`: デバッグ用ADNMAコード
- `UBIQUITY_ADNMA_Report.Rmd`: ADNMAレポート用Rマークダウンファイル
- `UBIQUITY_ADNMA_Report.html`: 生成されたADNMAレポート
- `UBIQUITY_ADNMA_Report_README.md`: ADNMAレポートの説明書
- `run_UBIQUITY_ADNMA_Report.R`: ADNMAレポート実行スクリプト
- `UBIQUITY_IPD_proposal.md`: IPD（Individual Patient Data）の研究提案書
- `todo.md`: プロジェクトのタスクリスト
- `data/`: 分析用データセット
- `references/`: 参考文献や関連資料

## 使用方法

### ADNMAの実行

```r
source("UBIQUITY_ADNMA.r")
# または修正版を使用
source("UBIQUITY_ADNMA_fixed.r")
```

### レポートの生成

```r
source("run_UBIQUITY_ADNMA_Report.R")
```

Rスクリプトの詳細な実行方法や、プロジェクトの詳細については各提案書を参照してください。

## ライセンス

このプロジェクトのライセンス情報については、プロジェクト管理者にお問い合わせください。