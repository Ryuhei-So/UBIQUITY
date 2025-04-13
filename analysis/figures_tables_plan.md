# 図表計画 (Figures and Tables Plan)

このドキュメントは、UBIQUITY-ADNMA研究の論文Resultsセクションで提示する予定の図表の計画をまとめたものです。

## 図 (Figures)

1.  **Figure 1: PRISMA-NMA フローダイアグラム (PRISMA-NMA Flow Diagram)**
    *   目的: 研究選択プロセス（スクリーニング、適格性評価、最終的に含まれた研究数）を視覚的に示す。
    *   ソース: 文献検索とスクリーニングの結果。

2.  **Figure 2: ネットワークプロット (Network Plot)**
    *   目的: 含まれた介入（No Intervention, UBI-minimal, UBI-feedback, BI）と、それらの間の直接比較が存在する研究の数を示すネットワークの幾何学的構造を視覚化する。
    *   ソース: 含まれた研究の介入アーム情報。
    *   ツール: R `netmeta` パッケージ。

3.  **Figure 3: Primary Outcome (Alcohol Consumption) のフォレストプロット (Forest Plot for Primary Outcome)**
    *   目的: 各直接比較およびネットワークメタアナリシスによる統合効果量（Mean Difference, g/week）と95%信頼区間を視覚的に示す。通常、参照介入（例: No Intervention）に対する各介入の効果を示す。
    *   ソース: DE sheet から抽出された Primary Outcome データ。
    *   ツール: R `netmeta` パッケージ。

4.  **Figure 4: 比較調整ファンネルプロット (Comparison-Adjusted Funnel Plot)**
    *   目的: Primary Outcomeに関する小規模研究効果や出版バイアスの可能性を視覚的に評価する。
    *   ソース: DE sheet から抽出された Primary Outcome データと研究の精度（例: 標準誤差）。
    *   ツール: R `netmeta` パッケージ (十分な研究数が存在する場合)。

5.  **Figure 5: CINeMA 評価結果の要約 (Summary of CINeMA Findings)**
    *   目的: Primary Outcome の主要な比較（例: UBI vs No Intervention）に関するエビデンスの確実性（信頼性）を視覚的に要約して示す。
    *   ソース: CINeMAフレームワークを用いた評価結果。
    *   ツール: CINeMAソフトウェアまたは関連するRパッケージ。

## 表 (Tables)

1.  **Table 1: 含まれた研究の特性 (Characteristics of Included Studies)**
    *   目的: 含まれた各研究の主要な特性をCochraneレビューの形式に準拠して要約して示す。通常、以下の項目を含む：
        *   Study ID (著者, 年)
        *   Methods (国, 設定, デザイン, フォローアップ期間)
        *   Participants (N, 年齢, 性別, ベースライン特性, 適格基準)
        *   Interventions (各アームの詳細な説明, 割り当てられたカテゴリ)
        *   Outcomes (測定されたアウトカム, 測定方法)
        *   Notes (資金源, 特記事項)
        *   Risk of Bias (各ドメインの評価結果, 総合評価)
    *   ソース: DE sheet から抽出された研究特性データ、Risk of Bias評価結果。

2.  **Table 2: 除外された研究とその理由 (Characteristics of Excluded Studies)**
    *   目的: フルテキストレビュー後に除外された研究とその主な除外理由をリストアップし、レビュープロセスの透明性を示す。
    *   ソース: フルテキストスクリーニングの記録。

3.  **Table 3: Primary Outcome (Alcohol Consumption) のリーグテーブル (League Table for Primary Outcome)**
    *   目的: ネットワークメタアナリシスから得られた全ての介入間のペアワイズ比較の結果（統合効果量と95%信頼区間）を表形式で示す。
    *   ソース: NMAの結果。
    *   ツール: R `netmeta` パッケージ。

4.  **Table 4: Secondary Outcome (Binge Drinking) のリーグテーブル (League Table for Secondary Outcome)** (データが利用可能な場合)
    *   目的: Secondary Outcome に関するNMAの結果（利用可能であれば）をリーグテーブル形式で示す。
    *   ソース: NMAの結果 (Secondary Outcome)。
    *   ツール: R `netmeta` パッケージ。

5.  **Table 5: 感度分析およびサブグループ分析の結果要約 (Summary of Sensitivity and Subgroup Analyses)**
    *   目的: 実施された感度分析（例: 高リスク研究の除外）およびサブグループ分析（例: フォローアップ期間別）の結果を要約して示す。
    *   ソース: 感度分析/サブグループ分析の結果。

---
*この計画は研究の進行に応じて更新される可能性があります。*