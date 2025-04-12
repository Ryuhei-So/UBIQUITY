# LLMを活用したネットワークメタアナリシス（NMA）プロトコル作成ガイドライン
## 1. はじめに

- **目的**: LLMを用いてNMAプロトコルを効率的かつ一貫性のある形式で作成する。
- **背景**: 近年、LLMは臨床試験プロトコルの作成において、効率性と正確性の向上に寄与している。
- **Citation**: Hutton, B., Salanti, G., Caldwell, D. M., Chaimani, A., Schmid, C. H., Cameron, C., Ioannidis, J. P., Straus, S., Thorlund, K., Jansen, J. P., Mulrow, C., Catalá-López, F., Gøtzsche, P. C., Dickersin, K., Boutron, I., Altman, D. G., & Moher, D. (2015). The PRISMA extension statement for reporting of systematic reviews incorporating network meta-analyses of health care interventions: checklist and explanations. Annals of internal medicine, 162(11), 777–784. https://doi.org/10.7326/M14-2385

## 2. プロトコル作成のステップ

### 2.1. 研究課題の定義

- **PICOの明確化**: 対象となる患者（Population）、介入（Intervention）、比較（Comparator）、アウトカム（Outcome）を明確にする。
- **研究の範囲**: 対象とする疾患、介入方法、評価期間などを具体的に設定する。

### 2.2. 文献検索戦略

- **データベースの選定**: PubMed、Embase、Cochrane Libraryなど、信頼性の高いデータベースを選定する。
- **検索式の作成**: LLMを活用して、包括的かつ効率的な検索式を作成する。
- **検索期間の設定**: 適切な検索期間を設定し、最新の研究を網羅する。

### 2.3. 研究の選定とデータ抽出

- **選定基準の明確化**: 包括基準と除外基準を明確にし、選定の一貫性を保つ。
- **データ抽出フォームの作成**: LLMを用いて、標準化されたデータ抽出フォームを作成する。
- **データの検証**: 抽出されたデータの正確性を確認するため、複数の研究者によるクロスチェックを行う。

### 2.4. バイアスの評価

- **リスクオブバイアスの評価**: Cochraneの「Risk of Bias」ツールを用いて、各研究のバイアスリスクを評価する。
- **LLMの活用**: LLMを用いて、バイアス評価の一貫性と効率性を向上させる。

### 2.5. データの統合と解析

- **統計モデルの選定**: ベイズモデルや頻度主義モデルなど、適切な統計モデルを選定する。
- **ネットワーク構造の可視化**: ネットワーク図を作成し、介入間の関係性を視覚的に示す。
- **LLMの活用**: LLMを用いて、解析結果の解釈や報告書の作成を支援する。

### 2.6. エビデンスの確実性評価

- **GRADEアプローチの適用**: GRADEアプローチを用いて、エビデンスの確実性を評価する。
- **CINeMAの活用**: Confidence in Network Meta-Analysis（CINeMA）ツールを使用して、ネットワーク全体のエビデンスの確実性を評価する。

## 3. プロトコルの登録と公開

- **登録の推奨**: PROSPEROやClinicalTrials.govなどの公的レジストリにプロトコルを登録する。
- **透明性の確保**: プロトコルの公開により、研究の透明性と再現性を高める。

## 4. LLMの活用における留意点

- **倫理的配慮**: LLMの使用に際しては、データのプライバシーと倫理的配慮を遵守する。
- **人間の監督**: LLMが生成した内容は、必ず専門家による確認と修正を行う。
- **使用の明示**: LLMを使用した場合は、その旨を明示し、使用方法を詳細に記載する。

## 5. 参考文献

- Cochrane Handbook for Systematic Reviews of Interventions
- GRADE Working Group. GRADE guidelines.
- Institute of Medicine. Standards for Developing Trustworthy Clinical Practice Guidelines.
- Guidelines International Network (G-I-N).
- CINeMA: Confidence in Network Meta-Analysis.