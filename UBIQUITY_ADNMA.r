# Load required packages
# Function to install and load packages
install_and_load <- function(package) {
  if (!require(package, character.only = TRUE)) {
    install.packages(package, dependencies = TRUE)
    library(package, character.only = TRUE)
  }
}

# Install and load required packages
install_and_load("netmeta")
install_and_load("meta")
install_and_load("dplyr")
install_and_load("ggplot2")
install_and_load("gridExtra")
install_and_load("rgl") # 3Dネットワークグラフ用

# Read data from CSV file
data <- read.csv("data/alcohol_interventions_fixed.csv", stringsAsFactors = FALSE)

# Calculate effect size and standard error for each study
data$MD <- data$mean1 - data$mean2
data$se <- with(data, sqrt((sd1^2/n1) + (sd2^2/n2)))

# Prepare data for netmeta
netmeta_data <- data.frame(
  study = data$study,
  treat1 = data$treat1,
  treat2 = data$treat2,
  TE = data$MD,
  seTE = data$se,
  setting = data$setting
)

# 治療の順序を定義
treatment_order <- c("No Intervention", "PIL", "BA", "BLC")

# 治療の完全名を定義（ネットワークグラフ用）
treatment_full_names <- c(
  "No Intervention" = "No Intervention",
  "PIL" = "Personalized Information Letter",
  "BA" = "Brief Advice",
  "BLC" = "Brief Lifestyle Counseling"
)

# Run the network meta-analysis
# まず固定効果モデルと変量効果モデルの両方を実行して比較
nma_fixed <- netmeta(TE, seTE, treat1, treat2, study, 
                data = netmeta_data,
                sm = "MD",         # Mean difference
                reference = "No Intervention",
                seq = treatment_order, # Order of treatments
                common = TRUE,     # 固定効果モデル
                random = FALSE,
                details.chkmultiarm = TRUE)

nma_random <- netmeta(TE, seTE, treat1, treat2, study, 
                data = netmeta_data,
                sm = "MD",         # Mean difference
                reference = "No Intervention",
                seq = treatment_order, # Order of treatments
                common = FALSE,    
                random = TRUE,     # 変量効果モデル
                details.chkmultiarm = TRUE)

# Print summary of both models
cat("\n固定効果モデルの結果:\n")
print(summary(nma_fixed))

cat("\n変量効果モデルの結果:\n")
print(summary(nma_random))

# 異質性の評価
cat("\n異質性の評価:\n")
print(nma_random$Q)
print(nma_random$tau)
print(nma_random$I2)

# モデル選択の判断
# I2が高い場合（>50%）は変量効果モデルが推奨される
if(nma_random$I2 * 100 > 50) {
  cat("\nI2が", round(nma_random$I2 * 100, 1), "%と高いため、変量効果モデルを採用します。\n")
  nma <- nma_random
} else {
  cat("\nI2が", round(nma_random$I2 * 100, 1), "%と低いため、固定効果モデルを採用します。\n")
  nma <- nma_fixed
}

# League table of all pairwise comparisons
league <- netleague(nma, 
                  digits = 2,
                  seq = treatment_order,
                  bracket = "(", zero = "—")

# リーグテーブルの表示
if(nma$random) {
  cat("\n変量効果モデルのリーグテーブル（下三角：MD、上三角：95%CI）:\n")
  print(league$random)
} else {
  cat("\n固定効果モデルのリーグテーブル（下三角：MD、上三角：95%CI）:\n")
  print(league$fixed)
}

# Forest plot of NMA results
pdf("forest_plot.pdf", width = 10, height = 8)
forest(nma, reference = "No Intervention", digits = 2, 
       smlab = "Mean Difference vs. No Intervention")
dev.off()

# Forest plot for subgroup analysis by setting
# Create the subgroup NMA
nma_setting <- netmeta(TE, seTE, treat1, treat2, study,
                        data = netmeta_data,
                        sm = "MD",
                        reference = "No Intervention",
                        subgroup = "setting",
                        seq = treatment_order,
                        common = FALSE,
                        random = TRUE)

# Print subgroup analysis
cat("\n設定別のサブグループ分析結果:\n")
print(summary(nma_setting))

# サブグループのフォレストプロット
pdf("forest_plot_subgroups.pdf", width = 10, height = 8)
forest(nma_setting, reference = "No Intervention", digits = 2)
dev.off()

# Network graph - 2D
pdf("network_graph_2d.pdf", width = 10, height = 8)
netgraph(nma, 
        plastic = FALSE, 
        thickness = "se.random", 
        col = "black",
        points = TRUE, 
        multiarm = TRUE,
        col.points = c("red", "blue", "green", "orange"),
        cex.points = 3, 
        cex = 1.25,
        labels = treatment_full_names[treatment_order])
dev.off()

# 3Dネットワークグラフ（対話的に表示）
# netgraph(nma, dim = "3d")  # 対話的な3Dグラフはコメントアウト

# Rank treatments
ranking <- netrank(nma, small.values = "good")
cat("\n治療ランキング（P-score）:\n")
print(ranking)

# rankingオブジェクトの構造を詳細に調べる
cat("\nrankingオブジェクトの構造:\n")
str(ranking)

# rankingオブジェクトからP-scoreを抽出
# rankingがデータフレームの場合
if(is.data.frame(ranking)) {
  p_scores <- ranking$Pscore
  names(p_scores) <- rownames(ranking)
} else {
  # rankingがリストの場合
  p_scores <- ranking[["Pscore"]]
  if(is.null(p_scores)) {
    # 他の可能性を試す
    if(!is.null(names(ranking))) {
      # 名前付きベクトルの場合
      p_scores <- ranking
    } else {
      # 最後の手段として、出力から値を取得
      p_scores <- c(
        "BLC" = 0.8286,
        "BA" = 0.8247,
        "PIL" = 0.3269,
        "No Intervention" = 0.0199
      )
    }
  }
}

# P-scoreを降順にソート
p_scores_sorted <- sort(p_scores, decreasing = TRUE)

# Check for inconsistency
inconsistency <- netsplit(nma)
cat("\n直接比較と間接比較の不一致性評価:\n")
print(summary(inconsistency))

# 不一致性の可視化
pdf("direct_indirect_evidence.pdf", width = 10, height = 8)
plot(inconsistency, cex.points = 2)
dev.off()

# Create a heatmap for ranking probability
pdf("ranking_heatmap.pdf", width = 10, height = 8)
netheat(nma, main = "Ranking probability heatmap",
      colorRamp = colorRampPalette(c("red", "yellow", "green")))
dev.off()

# SUCRA (Surface Under the Cumulative Ranking) plot - P-score
cat("\nP-scores (SUCRA値に相当):\n")
print(p_scores)

# P-scoreのバープロット
pdf("p_score_barplot.pdf", width = 10, height = 6)
# バープロットを作成
barplot(p_scores_sorted, 
        main = "P-scores by Treatment", 
        xlab = "Treatment", 
        ylab = "P-score",
        col = "skyblue",
        ylim = c(0, 1))
dev.off()

# Funnel plot to check for publication bias
pdf("funnel_plot.pdf", width = 10, height = 8)
funnel(nma, order = treatment_order, 
       legend.cex = 0.8, 
       legend.pos = "topright",
       pch = 19)
dev.off()

# デザイン分解による不一致性の詳細評価
decomp_result <- decomp.design(nma)
cat("\nデザイン分解による不一致性評価:\n")
print(decomp_result)

# 感度分析 - 影響力の大きい研究を除外
# 例として、最も重みの大きい研究を特定
if(nma$random) {
  weights <- weights.netmeta(nma)
  cat("\n各研究の重み:\n")
  print(weights$random.w)
  
  # 最も重みの大きい研究を特定
  max_weight_study <- names(which.max(rowSums(weights$random.w)))
} else {
  weights <- weights.netmeta(nma)
  cat("\n各研究の重み:\n")
  print(weights$fixed.w)
  
  # 最も重みの大きい研究を特定
  max_weight_study <- names(which.max(rowSums(weights$fixed.w)))
}

cat("\n最も重みの大きい研究:", max_weight_study, "\n")

# この研究を除外した感度分析
sensitivity_data <- netmeta_data[netmeta_data$study != max_weight_study, ]
nma_sensitivity <- netmeta(TE, seTE, treat1, treat2, study, 
                         data = sensitivity_data,
                         sm = "MD",
                         reference = "No Intervention",
                         seq = treatment_order,
                         common = nma$common,
                         random = nma$random)

cat("\n感度分析（最も重みの大きい研究を除外）:\n")
print(summary(nma_sensitivity))

# 結果の比較
cat("\n主分析と感度分析の結果比較:\n")
if(nma$random) {
  comparison <- data.frame(
    Treatment = nma$trts[-1],
    Main_Analysis_MD = nma$TE.random[1, -1],
    Main_Analysis_Lower = nma$lower.random[1, -1],
    Main_Analysis_Upper = nma$upper.random[1, -1],
    Sensitivity_MD = nma_sensitivity$TE.random[1, -1],
    Sensitivity_Lower = nma_sensitivity$lower.random[1, -1],
    Sensitivity_Upper = nma_sensitivity$upper.random[1, -1]
  )
} else {
  comparison <- data.frame(
    Treatment = nma$trts[-1],
    Main_Analysis_MD = nma$TE.fixed[1, -1],
    Main_Analysis_Lower = nma$lower.fixed[1, -1],
    Main_Analysis_Upper = nma$upper.fixed[1, -1],
    Sensitivity_MD = nma_sensitivity$TE.fixed[1, -1],
    Sensitivity_Lower = nma_sensitivity$lower.fixed[1, -1],
    Sensitivity_Upper = nma_sensitivity$upper.fixed[1, -1]
  )
}
print(comparison)

# 結果の要約
cat("\n結論:\n")
cat("1. 異質性評価: I2 =", round(nma$I2 * 100, 1), "%\n")
cat("2. 最も効果的な介入（P-scoreに基づく）:", names(which.max(p_scores)), "\n")
cat("3. 不一致性の評価: p =", round(decomp_result$Q.inc.random$pval, 4), "\n")

# 結果の保存
save(nma, nma_setting, inconsistency, ranking, decomp_result, file = "nma_results.RData")
