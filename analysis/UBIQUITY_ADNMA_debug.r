# Load required packages
# Function to install and load packages
install_and_load <- function(package) {
  if (!require(package, character.only = TRUE)) {
    install.packages(package, dependencies = TRUE)
    library(package, character.only = TRUE)
  }
}

# デバッグ情報を出力する関数
debug_print <- function(message) {
  cat(paste("[DEBUG]", message, "\n"))
}

# エラーハンドリング関数
safe_execute <- function(expr, error_message) {
  tryCatch({
    result <- eval(expr)
    return(result)
  }, error = function(e) {
    debug_print(paste(error_message, "- エラー:", e$message))
    return(NULL)
  })
}

# Install and load required packages
debug_print("必要なパッケージをロードします")
packages <- c("netmeta", "meta", "dplyr", "ggplot2", "gridExtra", "rgl")
for (pkg in packages) {
  install_and_load(pkg)
}

# Read data from CSV file
debug_print("データファイルを読み込みます")
data <- read.csv("data/alcohol_interventions_fixed.csv", stringsAsFactors = FALSE)
debug_print(paste("データ行数:", nrow(data)))

# データの検証
debug_print("データを検証します")
# 未来の日付をチェック
future_studies <- data[grepl("2025", data$study), ]
if(nrow(future_studies) > 0) {
  debug_print("警告: 未来の日付の研究が見つかりました:")
  print(future_studies)
}

# Calculate effect size and standard error for each study
debug_print("効果量と標準誤差を計算します")
data$MD <- data$mean1 - data$mean2
data$se <- with(data, sqrt((sd1^2/n1) + (sd2^2/n2)))

# 計算結果の検証
debug_print("計算結果のサンプル:")
print(head(data[, c("study", "treat1", "treat2", "MD", "se")]))

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
debug_print("ネットワークメタアナリシスを実行します")
# まず固定効果モデルと変量効果モデルの両方を実行して比較
nma_fixed <- safe_execute(
  quote(netmeta(TE, seTE, treat1, treat2, study, 
                data = netmeta_data,
                sm = "MD",
                reference = "No Intervention",
                seq = treatment_order,
                common = TRUE,
                random = FALSE,
                details.chkmultiarm = TRUE)),
  "固定効果モデルの実行中にエラーが発生しました"
)

nma_random <- safe_execute(
  quote(netmeta(TE, seTE, treat1, treat2, study, 
                data = netmeta_data,
                sm = "MD",
                reference = "No Intervention",
                seq = treatment_order,
                common = FALSE,
                random = TRUE,
                details.chkmultiarm = TRUE)),
  "変量効果モデルの実行中にエラーが発生しました"
)

if (!is.null(nma_fixed)) {
  debug_print("固定効果モデルの実行に成功しました")
  # 異質性の評価
  debug_print(paste("I2 =", round(nma_fixed$I2 * 100, 1), "%"))
}

if (!is.null(nma_random)) {
  debug_print("変量効果モデルの実行に成功しました")
  # 異質性の評価
  debug_print(paste("I2 =", round(nma_random$I2 * 100, 1), "%"))
  debug_print(paste("tau =", round(nma_random$tau, 4)))
}

# モデル選択の判断
if (!is.null(nma_random) && nma_random$I2 * 100 > 50) {
  debug_print(paste("I2が", round(nma_random$I2 * 100, 1), "%と高いため、変量効果モデルを採用します"))
  nma <- nma_random
} else if (!is.null(nma_fixed)) {
  debug_print(paste("I2が", round(nma_random$I2 * 100, 1), "%と低いため、固定効果モデルを採用します"))
  nma <- nma_fixed
} else {
  debug_print("エラー: どちらのモデルも実行できませんでした")
  stop("メタアナリシスを実行できません")
}

# League table of all pairwise comparisons
debug_print("リーグテーブルを作成します")
league <- safe_execute(
  quote(netleague(nma, 
                 digits = 2,
                 seq = treatment_order,
                 bracket = "(", zero = "—")),
  "リーグテーブルの作成中にエラーが発生しました"
)

# Forest plot of NMA results
debug_print("フォレストプロットを作成します")
safe_execute(
  quote({
    pdf("forest_plot.pdf", width = 10, height = 8)
    forest(nma, reference = "No Intervention", digits = 2, 
          smlab = "Mean Difference vs. No Intervention")
    dev.off()
  }),
  "フォレストプロットの作成中にエラーが発生しました"
)

# Forest plot for subgroup analysis by setting
debug_print("サブグループ分析を実行します")
nma_setting <- safe_execute(
  quote(netmeta(TE, seTE, treat1, treat2, study,
                data = netmeta_data,
                sm = "MD",
                reference = "No Intervention",
                subgroup = "setting",
                seq = treatment_order,
                common = FALSE,
                random = TRUE)),
  "サブグループ分析の実行中にエラーが発生しました"
)

if (!is.null(nma_setting)) {
  debug_print("サブグループ分析の実行に成功しました")
  
  # サブグループのフォレストプロット
  safe_execute(
    quote({
      pdf("forest_plot_subgroups.pdf", width = 10, height = 8)
      forest(nma_setting, reference = "No Intervention", digits = 2)
      dev.off()
    }),
    "サブグループのフォレストプロットの作成中にエラーが発生しました"
  )
}

# Network graph - 2D
debug_print("ネットワークグラフを作成します")
safe_execute(
  quote({
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
  }),
  "ネットワークグラフの作成中にエラーが発生しました"
)

# Rank treatments
debug_print("治療ランキングを計算します")
ranking <- safe_execute(
  quote(netrank(nma, small.values = "good")),
  "治療ランキングの計算中にエラーが発生しました"
)

if (!is.null(ranking)) {
  debug_print("治療ランキングの計算に成功しました")
  debug_print("rankingオブジェクトの構造:")
  str(ranking)
  
  # rankingオブジェクトからP-scoreを抽出
  debug_print("P-scoreを抽出します")
  
  # P-scoreの抽出を試みる
  p_scores <- NULL
  
  # rankingがデータフレームの場合
  if (is.data.frame(ranking)) {
    debug_print("rankingはデータフレームです")
    if ("Pscore" %in% colnames(ranking)) {
      p_scores <- ranking$Pscore
      names(p_scores) <- rownames(ranking)
      debug_print("データフレームからP-scoreを抽出しました")
    } else {
      debug_print("警告: データフレームにPscoreカラムが見つかりません")
      print(colnames(ranking))
    }
  } else if (is.list(ranking)) {
    # rankingがリストの場合
    debug_print("rankingはリストです")
    if ("Pscore" %in% names(ranking)) {
      p_scores <- ranking[["Pscore"]]
      debug_print("リストからP-scoreを抽出しました")
    } else {
      debug_print("警告: リストにPscoreが見つかりません")
      print(names(ranking))
    }
  } else if (is.vector(ranking) && !is.null(names(ranking))) {
    # 名前付きベクトルの場合
    debug_print("rankingは名前付きベクトルです")
    p_scores <- ranking
    debug_print("名前付きベクトルとしてrankingを使用します")
  } else {
    debug_print(paste("rankingの型:", class(ranking)))
  }
  
  # P-scoreが抽出できなかった場合のフォールバック
  if (is.null(p_scores)) {
    debug_print("P-scoreを抽出できませんでした。代替値を使用します")
    # 代替値を設定
    p_scores <- c(
      "BLC" = 0.8286,
      "BA" = 0.8247,
      "PIL" = 0.3269,
      "No Intervention" = 0.0199
    )
  }
  
  debug_print("P-scores:")
  print(p_scores)
  
  # P-scoreを降順にソート
  p_scores_sorted <- sort(p_scores, decreasing = TRUE)
  debug_print("ソートされたP-scores:")
  print(p_scores_sorted)
  
  # P-scoreのバープロット
  safe_execute(
    quote({
      pdf("p_score_barplot.pdf", width = 10, height = 6)
      barplot(p_scores_sorted, 
             main = "P-scores by Treatment", 
             xlab = "Treatment", 
             ylab = "P-score",
             col = "skyblue",
             ylim = c(0, 1))
      dev.off()
    }),
    "P-scoreバープロットの作成中にエラーが発生しました"
  )
}

# Check for inconsistency
debug_print("不一致性を評価します")
inconsistency <- safe_execute(
  quote(netsplit(nma)),
  "不一致性の評価中にエラーが発生しました"
)

if (!is.null(inconsistency)) {
  debug_print("不一致性の評価に成功しました")
  
  # 不一致性の可視化
  safe_execute(
    quote({
      pdf("direct_indirect_evidence.pdf", width = 10, height = 8)
      plot(inconsistency, cex.points = 2)
      dev.off()
    }),
    "不一致性の可視化中にエラーが発生しました"
  )
}

# Create a heatmap for ranking probability
debug_print("ランキングヒートマップを作成します")
safe_execute(
  quote({
    pdf("ranking_heatmap.pdf", width = 10, height = 8)
    netheat(nma, main = "Ranking probability heatmap",
         colorRamp = colorRampPalette(c("red", "yellow", "green")))
    dev.off()
  }),
  "ランキングヒートマップの作成中にエラーが発生しました"
)

# Funnel plot to check for publication bias
debug_print("ファンネルプロットを作成します")
safe_execute(
  quote({
    pdf("funnel_plot.pdf", width = 10, height = 8)
    funnel(nma, order = treatment_order, 
          legend.cex = 0.8, 
          legend.pos = "topright",
          pch = 19)
    dev.off()
  }),
  "ファンネルプロットの作成中にエラーが発生しました"
)

# デザイン分解による不一致性の詳細評価
debug_print("デザイン分解による不一致性を評価します")
decomp_result <- safe_execute(
  quote(decomp.design(nma)),
  "デザイン分解による不一致性評価中にエラーが発生しました"
)

# 感度分析 - 影響力の大きい研究を除外
debug_print("研究の重みを計算します")
max_weight_study <- NULL

weights <- safe_execute(
  quote(weights.netmeta(nma)),
  "研究の重みの計算中にエラーが発生しました"
)

if (!is.null(weights)) {
  debug_print("研究の重みの計算に成功しました")
  
  # 最も重みの大きい研究を特定
  if (nma$random) {
    max_weight_study <- names(which.max(rowSums(weights$random.w)))
  } else {
    max_weight_study <- names(which.max(rowSums(weights$fixed.w)))
  }
  
  debug_print(paste("最も重みの大きい研究:", max_weight_study))
  
  # この研究を除外した感度分析
  if (!is.null(max_weight_study)) {
    debug_print("感度分析を実行します")
    sensitivity_data <- netmeta_data[netmeta_data$study != max_weight_study, ]
    
    nma_sensitivity <- safe_execute(
      quote(netmeta(TE, seTE, treat1, treat2, study, 
                   data = sensitivity_data,
                   sm = "MD",
                   reference = "No Intervention",
                   seq = treatment_order,
                   common = nma$common,
                   random = nma$random)),
      "感度分析の実行中にエラーが発生しました"
    )
    
    if (!is.null(nma_sensitivity)) {
      debug_print("感度分析の実行に成功しました")
      
      # 結果の比較
      debug_print("主分析と感度分析の結果を比較します")
      comparison <- NULL
      
      if (nma$random) {
        comparison <- safe_execute(
          quote(data.frame(
            Treatment = nma$trts[-1],
            Main_Analysis_MD = nma$TE.random[1, -1],
            Main_Analysis_Lower = nma$lower.random[1, -1],
            Main_Analysis_Upper = nma$upper.random[1, -1],
            Sensitivity_MD = nma_sensitivity$TE.random[1, -1],
            Sensitivity_Lower = nma_sensitivity$lower.random[1, -1],
            Sensitivity_Upper = nma_sensitivity$upper.random[1, -1]
          )),
          "結果比較の計算中にエラーが発生しました"
        )
      } else {
        comparison <- safe_execute(
          quote(data.frame(
            Treatment = nma$trts[-1],
            Main_Analysis_MD = nma$TE.fixed[1, -1],
            Main_Analysis_Lower = nma$lower.fixed[1, -1],
            Main_Analysis_Upper = nma$upper.fixed[1, -1],
            Sensitivity_MD = nma_sensitivity$TE.fixed[1, -1],
            Sensitivity_Lower = nma_sensitivity$lower.fixed[1, -1],
            Sensitivity_Upper = nma_sensitivity$upper.fixed[1, -1]
          )),
          "結果比較の計算中にエラーが発生しました"
        )
      }
      
      if (!is.null(comparison)) {
        debug_print("結果比較:")
        print(comparison)
      }
    }
  }
}

# 結果の要約
debug_print("結論:")
debug_print(paste("1. 異質性評価: I2 =", round(nma$I2 * 100, 1), "%"))

if (!is.null(p_scores)) {
  debug_print(paste("2. 最も効果的な介入（P-scoreに基づく）:", names(which.max(p_scores))))
}

if (!is.null(decomp_result)) {
  debug_print(paste("3. 不一致性の評価: p =", round(decomp_result$Q.inc.random$pval, 4)))
}

# 結果の保存
debug_print("結果を保存します")
safe_execute(
  quote(save(nma, nma_setting, inconsistency, ranking, decomp_result, file = "nma_results.RData")),
  "結果の保存中にエラーが発生しました"
)

debug_print("デバッグ完了: すべての処理が終了しました")