
### **研究タイトル**

**Implementable but Effective?**  
**Evaluating and Predicting Individual-Level Benefits of Ultra-Brief Alcohol Intervention**  
（通称：**UBIQUITY study**：_Ultra-Brief Interventions for Qualifying Individual-level Treatment responsivity_）

---

### **研究計画概要（約300字）**

アルコール関連問題は医療現場における重要な介入対象であるが、時間的制約からBrief Intervention（BI）の実施は困難であり、1分以内のUltra-brief intervention（UBI）の実装可能性が注目されている。しかし、UBIに特化した系統的な効果検証は未だ行われておらず、また効果の有無が個人特性によって左右される可能性がある。本研究「UBIQUITY (Ultra-Brief Interventions for Qualifying Individual-level Treatment responsivity) study」では、医療機関で行われたRCTの個別参加者データ（IPD）を統合し、UBIの全体としての効果と効果修飾因子（effect modifier）を検討する。さらに、機械学習を用いて個人単位の治療反応性予測モデルを構築することで、科学的根拠に基づく個別化介入の基盤構築を目指す。

---

### **学術的背景**

アルコール関連問題は、身体・精神疾患や社会的損失に直結する世界的な公衆衛生課題であり、医療機関はその早期介入の好機とされている。従来のBrief Intervention（BI）は一定の有効性が報告されてきたが、5〜20分以上を要することも多く、時間的制約のある一般診療現場では普及率が極めて低い。このような背景から、1分以内で実施可能なUltra-brief intervention（UBI）が注目されている。UBIはその実装可能性の高さにもかかわらず、これまでにUBIの効果を主対象とした系統的メタ解析は存在せず、科学的根拠の整理は進んでいない。

我々が実施した大規模クラスターRCT、**EASY (Education on Alcohol after Screening to Yield moderated drinking) study** では、UBIの全体的な有効性は確認されなかった。一方で、inpatient setting を対象とした研究では肯定的な結果も報告されており、これらの結果のばらつきは、単なる偶然誤差や研究条件の違いにとどまらず、対象集団における効果修飾因子（effect modifier）の分布の差異が影響している可能性がある。たとえば、EASY studyにおいては、若年であることがUBIのeffect modifierであることが示唆された。

---

### **学術的「問い」**

Ultra-brief intervention（UBI）は、1分以内で完結する簡潔な介入であり、医療現場での実装可能性が極めて高いという利点を持つ。近年、アルコール関連問題への介入手段として注目を集めているが、その効果に関する科学的根拠は未だ不十分であり、効果の存在やばらつきの原因は解明されていない。

我々が実施したEASY studyでは、UBIの全体的な有効性は確認されなかったが、20〜39歳の若年層では飲酒量の有意な減少が観察された。また、inpatient settingでの研究では肯定的な結果も報告されており、対象集団や医療環境の違いが効果に影響している可能性がある。

したがって、本研究で解明する問いは、  
**「Ultra-brief interventionは全体として有効なのか？」**  
そして、  
**「特定の集団において、UBIの効果は修飾されるのか？」**  
という2つの問いである。

---

### **研究の目的**

本研究の目的は、Ultra-brief intervention（UBI）の科学的根拠を再構築することである。具体的には、医療機関におけるランダム化比較試験の個別参加者データ（IPD）を用いて、UBIの全体としての有効性を評価するとともに、年齢・性別・飲酒リスクなどの個人特性による効果修飾因子（effect modifier）の存在を明らかにする。また、機械学習を用いて個人単位の治療反応性予測モデルを構築することで、精密かつ実装可能な介入戦略の基盤を構築する。

---

### **学術的独自性・創造性**

本研究は、Ultra-brief intervention（UBI）という極めて簡便で実装性の高い介入に対して、全体的効果と個人特性による効果の異質性を、個別参加者データ（IPD）と機械学習を用いて明らかにする初の研究である。従来、UBIはBrief Interventionの一部として扱われてきたが、UBI単体を評価対象とした系統的なメタ解析は存在せず、平均的な効果すら十分に検証されていない。

また、本研究はMetaForestやCausal Forestを活用し、「誰にUBIが有効か」という予測モデルを構築し、介入の個別化に資する知見を提供する。UBIという最小構成の行動介入に対し、精密化・層別化のアプローチを適用する試みは前例が少なく、介入研究と実装科学、予測モデリングの融合的アプローチとして学術的にも先進性が高い。

---

### **研究計画・方法（概要）**

本研究では、医療機関におけるUltra-brief intervention（UBI）の効果を検証するため、個別参加者データ（IPD）を収集し、統合解析を実施する。具体的には以下のステップで進める。

- **対象研究の選定**：UBIを含む医療機関でのランダム化比較試験（RCT）からIPDを取得
- **主要アウトカム**：週あたりの飲酒量、heavy drinking daysなど
- **主解析①**：1-stage IPDメタ解析（Generalized Linear Mixed Model）を用いて、UBI vs No intervention の全体効果および効果修飾因子（effect modifier）を評価
- **補足解析②**：MetaForest／Causal Forest による個人単位の治療反応性（individual treatment effect, ITE）の予測モデル構築
- **データ管理**：匿名化データを用い、セキュアな研究サーバ上で管理

---

### **研究計画・方法（詳細）**

#### ■ 初年度（Months 1–6）：

- 対象研究の選定とデータ提供依頼（EASY study含む）
- 共通変数コードブック作成、データ前処理（欠損補完・単位変換）
- 1-stage IPDメタ解析（GLMM）による全体効果と交互作用（effect modifier）評価

#### ■ 2年目（Months 7–12）：

- MetaForest / Causal Forest による反応性予測モデル構築
- Cross-validation・部分依存プロットによる性能評価と解釈
- 図表作成・結果統合・論文化・学会発表

---

### **論文タイムテーブル**

|月|作業内容|
|---|---|
|1–3|IPD取得、DTA契約、IRB申請、変数統一|
|4–6|GLMMによる主解析、効果修飾因子の検出|
|7–9|MLモデル構築、交差検証、ITE推定|
|10–12|結果統合、図表作成、論文執筆・投稿準備|

---

### **計画通りに進まない時の対応**

IPD取得が困難な場合は、利用可能なEASY studyデータのみで主要解析を先行する。効果修飾因子が特定できない場合は、subgroup記述統計と感度分析で補完する。MLモデルの予測性能が低い場合は、他のアルゴリズム（Elastic Net, Gradient Boosting等）に切り替え、性能指標と解釈性のバランスを確保する。いずれの場合も、研究目的を明確に保持し、柔軟な方法選択で対応する。

---

### **研究体制**

|役割|氏名（所属）|担当内容|
|---|---|---|
|研究代表者（PI）|Ryuhei So（精神科医・研究員）|研究統括、EASY studyデータ、設計・論文化|
|統計解析担当|Yuki Kataoka（京都大学）|IPD解析、GLMM設計|
|統計解析協力者|Yasushi Tsujimoto（大阪大学）|メタ解析全般、解析理論支援|
|メンター|Toshi A. Furukawa（京都大学）|SR/MA指導、国際論文化支援|
|国際共同研究者|Ethan Sahker（米国）|行動科学・実装科学的知見|
|データ提供協力者|Eileen Kaner（英国）|UBI vs BI含むデータ提供|
|ML支援（予定）|未定（外部連携予定）|MetaForest/Causal Forest モデル設計|
|研究補助者（RA）|所属機関内で任命予定|データ整理、文献管理、変数統一|

---

### **準備状況**

EASY studyの個別データはすでに利用可能であり、研究代表者自身が筆頭著者として全構造を把握している。Eileen Kanerらとの連絡を通じて他RCTのIPD提供も検討中。解析環境（R, Stan, セキュアサーバ）も整備済みで、IRB申請準備も進行中。統計・MLに精通した協力者がすでに参画しており、開始後速やかに解析作業に移行可能である。

> **本研究は、既存データと研究チームの整備により、迅速かつ着実な実施が可能である。得られる成果は、精密化されたアルコール介入の実装に向けた新たなエビデンス基盤となる。**

---
[ChatGPT - IPD Meta-Analysis Research Plan](https://chatgpt.com/share/67de3736-75c0-8000-bdad-9a75f6273f99)
[ChatGPT](https://chatgpt.com/g/g-6790b6c30b248191a4f91925b891a695-scigen-yan-jiu-ji-hua-shu-zuo-cheng-esiento/c/67de28c2-efd0-8000-b005-7ea977d024d1)
[elicit.com/review/07c9e7f2-020f-4520-a7da-033541432c6b](https://elicit.com/review/07c9e7f2-020f-4520-a7da-033541432c6b)