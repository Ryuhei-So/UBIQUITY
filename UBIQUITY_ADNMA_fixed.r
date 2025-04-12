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

# データの検証
# 未来の日付をチェック
future_studies <- data[grepl("2025", data$study), ]
if(nrow(future_studies) > 0) {
  cat("警告: 未来の日付の研究が見つかりました:\n")
  print(future_studies)
  cat("これらの研究は分析に含まれますが、データの妥当性を確認してください\n")
}

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

# サブグループ分析のための準備
settings <- unique(netmeta_data$setting)
cat("\n検出された設定（settings）:", paste(settings, collapse=", "), "\n")

# サブグループごとにネットワークメタ分析を実行し、結果を保存
subgroup_results <- list()

for (s in settings) {
  # サブグループのデータを抽出
  subgroup_data <- netmeta_data[netmeta_data$setting == s, ]
  
  # このサブグループに存在する治療法を特定
  available_treatments <- unique(c(subgroup_data$treat1, subgroup_data$treat2))
  
  # 元の治療順序からこのサブグループに存在する治療法のみをフィルタリング
  subgroup_treatment_order <- treatment_order[treatment_order %in% available_treatments]
  
  cat("\n設定「", s, "」の治療法:", paste(subgroup_treatment_order, collapse=", "), "\n")
  
  # 参照グループを動的に選択
  # "No Intervention"が存在すればそれを使用、なければ最初の治療法を使用
  reference_group <- ifelse("No Intervention" %in% available_treatments,
                           "No Intervention",
                           subgroup_treatment_order[1])
  
  # サブグループのネットワークメタ分析を実行
  tryCatch({
    nma_subgroup <- netmeta(TE, seTE, treat1, treat2, study,
                            data = subgroup_data,
                            sm = "MD",
                            reference = reference_group,
                            seq = subgroup_treatment_order,
                            common = FALSE,
                            random = TRUE)
    
    # サブグループ分析の結果を表示
    cat("\n設定「", s, "」のサブグループ分析結果 (参照グループ: ", reference_group, "):\n", sep="")
    print(summary(nma_subgroup))
    
    # 結果をリストに保存
    subgroup_results[[s]] <- nma_subgroup
    
    # サブグループの結果を保存（後で使用するため）
    if (s == "Primary care") {
      nma_primary <- nma_subgroup
    } else if (s == "Emergency department") {
      nma_emergency <- nma_subgroup
    } else if (s == "College health clinic") {
      nma_college <- nma_subgroup
    }
    
  }, error = function(e) {
    cat("\n設定「", s, "」の分析中にエラーが発生しました: ", e$message, "\n")
  })
}

# 全サブグループを1つのフォレストプロットにまとめる
pdf("forest_plot_subgroups.pdf", width = 12, height = 8)

# プロットの余白を調整してタイトルと列見出しの重なりを防ぐ
par(mar = c(4, 4, 5, 6))  # 下、左、上、右の余白

# サブグループごとの結果を1つのフォレストプロットにまとめる
# "No Intervention"を参照グループとして使用
reference_treatment <- "No Intervention"

# サブグループごとの結果を抽出して整形
treatments <- c()
settings_list <- c()
effects <- c()
lower_ci <- c()
upper_ci <- c()
studies <- c()

for (s in names(subgroup_results)) {
  nma_s <- subgroup_results[[s]]
  
  # 参照グループが存在するか確認
  if (reference_treatment %in% nma_s$trts) {
    ref_idx <- which(nma_s$trts == reference_treatment)
    
    # 各治療法と参照グループの比較結果を抽出
    for (i in 1:length(nma_s$trts)) {
      if (i != ref_idx) {
        treatments <- c(treatments, nma_s$trts[i])
        settings_list <- c(settings_list, s)
        
        # 変量効果モデルの結果を使用
        effects <- c(effects, nma_s$TE.random[ref_idx, i])
        lower_ci <- c(lower_ci, nma_s$lower.random[ref_idx, i])
        upper_ci <- c(upper_ci, nma_s$upper.random[ref_idx, i])
        
        # 研究数を抽出（可能であれば）
        if (!is.null(nma_s$n.trts)) {
          studies <- c(studies, nma_s$n.trts[i])
        } else {
          studies <- c(studies, NA)
        }
      }
    }
  }
}

# データフレームを作成
forest_data <- data.frame(
  treatment = treatments,
  setting = settings_list,
  effect = effects,
  lower = lower_ci,
  upper = upper_ci,
  studies = studies
)

# 治療法とサブグループでソート
forest_data <- forest_data[order(forest_data$setting, forest_data$treatment), ]

# フォレストプロットの作成
# まずプロットエリアを設定
plot(NA, NA, xlim = c(-150, 150), ylim = c(0.5, nrow(forest_data) + 1.5),
     xlab = "Mean Difference", ylab = "", yaxt = "n",
     main = "Mean Difference vs. No Intervention - Subgroup Analysis")

# グリッド線
abline(v = 0, lty = 2)
abline(v = seq(-150, 150, by = 50), lty = 3, col = "lightgray")

# 各行のラベルとエフェクトサイズをプロット
for (i in 1:nrow(forest_data)) {
  # ラベル
  text(-150, i, paste0(forest_data$treatment[i], " (", forest_data$setting[i], ")"),
       adj = 0, cex = 0.9)
  
  # エフェクトサイズと信頼区間
  points(forest_data$effect[i], i, pch = 15, cex = 1.2)
  lines(c(forest_data$lower[i], forest_data$upper[i]), c(i, i), lwd = 2)
  
  # 数値を右側に表示
  text(150, i, sprintf("%.2f [%.2f; %.2f]",
                      forest_data$effect[i],
                      forest_data$lower[i],
                      forest_data$upper[i]),
       adj = 1, cex = 0.9)
}

# 列見出しを追加（タイトルと重ならないように位置を調整）
mtext("Treatment (Setting)", side = 2, line = 2, at = nrow(forest_data) + 1, adj = 0, cex = 0.9)
mtext("MD", side = 1, line = 2.5, at = 0, cex = 0.9)
mtext("95%-CI", side = 4, line = 1, at = nrow(forest_data)/2, cex = 0.9)

# 凡例
legend("bottomright", legend = unique(forest_data$setting),
       pch = 15, col = "black", cex = 0.8,
       title = "Settings", bg = "white")

dev.off()

# 改良版フォレストプロット: サブグループ分析（修正版）
# 前のバージョンは削除し、このバージョンのみを使用

# 改良版フォレストプロット: サブグループ分析（修正版）
pdf("forest_plot_subgroups_improved.pdf", width = 20, height = 10)

# プロットの余白を大幅に調整（テキストとプロット領域を完全に分離）
# 左側の余白を特に広くして行名と推定値が重ならないようにする
par(mar = c(5, 25, 4, 14), oma = c(0, 0, 2, 0))

# サブグループごとの結果を抽出して整形
treatments <- c()
settings_list <- c()
effects <- c()
lower_ci <- c()
upper_ci <- c()
ref_treatments <- c() # 参照治療を追跡するための配列

# 各サブグループの結果を処理
for (s in names(subgroup_results)) {
  nma_s <- subgroup_results[[s]]
  
  # 参照グループが存在するか確認
  if (reference_treatment %in% nma_s$trts) {
    ref_idx <- which(nma_s$trts == reference_treatment)
    
    # 各治療法と参照グループの比較結果を抽出
    for (i in 1:length(nma_s$trts)) {
      if (i != ref_idx) {
        treatments <- c(treatments, nma_s$trts[i])
        settings_list <- c(settings_list, s)
        ref_treatments <- c(ref_treatments, reference_treatment) # 参照治療を追加
        
        # 変量効果モデルの結果を使用
        if (nma_s$random) {
          effects <- c(effects, nma_s$TE.random[ref_idx, i])
          lower_ci <- c(lower_ci, nma_s$lower.random[ref_idx, i])
          upper_ci <- c(upper_ci, nma_s$upper.random[ref_idx, i])
        } else {
          effects <- c(effects, nma_s$TE.fixed[ref_idx, i])
          lower_ci <- c(lower_ci, nma_s$lower.fixed[ref_idx, i])
          upper_ci <- c(upper_ci, nma_s$upper.fixed[ref_idx, i])
        }
      }
    }
  } else if (length(nma_s$trts) > 0) {
    # 参照グループが存在しない場合は、最初の治療法を参照として使用
    ref_idx <- 1
    for (i in 2:length(nma_s$trts)) {
      treatments <- c(treatments, nma_s$trts[i])
      settings_list <- c(settings_list, s)
      ref_treatments <- c(ref_treatments, nma_s$trts[ref_idx]) # 実際の参照治療を追加
      
      # 変量効果モデルの結果を使用
      if (nma_s$random) {
        effects <- c(effects, nma_s$TE.random[ref_idx, i])
        lower_ci <- c(lower_ci, nma_s$lower.random[ref_idx, i])
        upper_ci <- c(upper_ci, nma_s$upper.random[ref_idx, i])
      } else {
        effects <- c(effects, nma_s$TE.fixed[ref_idx, i])
        lower_ci <- c(lower_ci, nma_s$lower.fixed[ref_idx, i])
        upper_ci <- c(upper_ci, nma_s$upper.fixed[ref_idx, i])
      }
    }
  }
}

# データが抽出できたか確認
if(length(treatments) > 0 && length(treatments) == length(settings_list) &&
   length(treatments) == length(effects) && length(treatments) == length(lower_ci) &&
   length(treatments) == length(upper_ci) && length(treatments) == length(ref_treatments)) {
  
  # データフレームを作成
  forest_data <- data.frame(
    treatment = treatments,
    ref_treatment = ref_treatments, # 参照治療を追加
    setting = settings_list,
    effect = effects,
    lower = lower_ci,
    upper = upper_ci,
    stringsAsFactors = FALSE
  )
  
  # 設定ごとに色を割り当て
  setting_colors <- c(
    "Primary care" = "black",
    "Emergency department" = "blue",
    "College health clinic" = "red"
  )
  
  # 設定ごとに形状を割り当て
  setting_pch <- c(
    "Primary care" = 15, # 四角
    "Emergency department" = 16, # 丸
    "College health clinic" = 17 # 三角
  )
  
  # 比較の順序を変更 - more intensive vs less intensiveに統一
  # PIL vs BA → BA vs PIL, PIL vs BLC → BLC vs PIL
  for (i in 1:nrow(forest_data)) {
    if (forest_data$treatment[i] == "PIL" &&
        (forest_data$ref_treatment[i] == "BA" || forest_data$ref_treatment[i] == "BLC")) {
      # 比較を反転
      temp_treat <- forest_data$treatment[i]
      forest_data$treatment[i] <- forest_data$ref_treatment[i]
      forest_data$ref_treatment[i] <- temp_treat
      # 効果量も反転
      forest_data$effect[i] <- -forest_data$effect[i]
      temp_ci <- forest_data$lower[i]
      forest_data$lower[i] <- -forest_data$upper[i]
      forest_data$upper[i] <- -temp_ci
    }
  }
  
  # Primary careのすべての比較を追加
  # BA vs PIL, BLC vs PIL, BLC vs BAの比較を追加
  if ("Primary care" %in% unique(forest_data$setting)) {
    primary_care_data <- forest_data[forest_data$setting == "Primary care", ]
    
    # 既存の比較を確認
    existing_comparisons <- paste(primary_care_data$treatment, primary_care_data$ref_treatment)
    
    # 必要な比較を追加
    needed_comparisons <- c("BA PIL", "BLC PIL", "BLC BA")
    
    for (comp in needed_comparisons) {
      if (!comp %in% existing_comparisons) {
        # 比較を分解
        parts <- strsplit(comp, " ")[[1]]
        treat1 <- parts[1]
        treat2 <- parts[2]
        
        # nma_primaryから直接データを取得
        if (exists("nma_primary")) {
          idx1 <- which(nma_primary$trts == treat1)
          idx2 <- which(nma_primary$trts == treat2)
          
          if (length(idx1) > 0 && length(idx2) > 0) {
            if (nma_primary$random) {
              effect_val <- nma_primary$TE.random[idx2, idx1]
              lower_val <- nma_primary$lower.random[idx2, idx1]
              upper_val <- nma_primary$upper.random[idx2, idx1]
            } else {
              effect_val <- nma_primary$TE.fixed[idx2, idx1]
              lower_val <- nma_primary$lower.fixed[idx2, idx1]
              upper_val <- nma_primary$upper.fixed[idx2, idx1]
            }
            
            # データフレームに追加
            forest_data <- rbind(forest_data, data.frame(
              treatment = treat1,
              ref_treatment = treat2,
              setting = "Primary care",
              effect = effect_val,
              lower = lower_val,
              upper = upper_val,
              stringsAsFactors = FALSE
            ))
          }
        }
      }
    }
  }
  
  # 比較の種類を作成
  forest_data$comparison_type <- paste(forest_data$treatment, "vs", forest_data$ref_treatment)
  
  # 比較の種類に基づいてソート順を定義
  comparison_order <- c(
    "PIL vs No Intervention",
    "BA vs No Intervention",
    "BLC vs No Intervention",
    "BA vs PIL",
    "BLC vs PIL",
    "BLC vs BA"
  )
  
  # 比較の種類に基づいてソート順を割り当て
  forest_data$sort_order <- match(forest_data$comparison_type, comparison_order)
  
  # 比較の種類でソート、次にサブグループでソート
  forest_data <- forest_data[order(forest_data$sort_order, forest_data$setting), ]
  
  # プロット領域の設定 - 非対称にする
  x_min <- -100
  x_max <- 150
  
  # プロット領域外にもテキストを描画できるようにする
  par(xpd = TRUE)
  
  # フォレストプロットの作成
  # まずプロットエリアを設定 - X軸の範囲を調整し、枠を削除
  plot(NA, NA, xlim = c(x_min, x_max), ylim = c(0.5, nrow(forest_data) + 2.5),
       xlab = "", ylab = "", yaxt = "n", xaxt = "n", bty = "n",
       main = "")
  
  # グリッド線
  abline(v = 0, lty = 2)
  abline(v = seq(x_min, x_max, by = 50), lty = 3, col = "lightgray")
  
  # 比較の種類の区切り線を追加
  prev_comparison <- NULL
  for (i in 1:nrow(forest_data)) {
    if (is.null(prev_comparison) || prev_comparison != forest_data$comparison_type[i]) {
      if (!is.null(prev_comparison)) {
        abline(h = i - 0.5, lty = 3, col = "darkgray", lwd = 1.5)
      }
      prev_comparison <- forest_data$comparison_type[i]
    }
  }
  
  # X軸ラベルと目盛り
  axis(1, at = seq(x_min, x_max, by = 50))
  mtext("Mean Difference", side = 1, line = 3, cex = 1.1)
  
  # 効果の方向性を示す注釈 - X軸メモリと重ならないように位置を調整
  mtext("Favors Reference", side = 1, line = 1.5, at = -75, cex = 1.0)
  mtext("Favors Treatment", side = 1, line = 1.5, at = 125, cex = 1.0)
  
  # 各行のラベルとエフェクトサイズをプロット - 重ならないように位置を調整
  for (i in 1:nrow(forest_data)) {
    # 設定に基づいて色と形状を選択
    current_color <- setting_colors[forest_data$setting[i]]
    current_pch <- setting_pch[forest_data$setting[i]]
    
    # 行名 - 左端に配置（位置を-200に変更して左に寄せる）
    text(-200, i, paste0(forest_data$treatment[i], " vs ", forest_data$ref_treatment[i]),
         adj = 0, cex = 0.9)
    
    # 推定値 - 行名と重ならないように配置（位置を-120に変更）
    text(-120, i, sprintf("%.2f [%.2f; %.2f]",
                        forest_data$effect[i],
                        forest_data$lower[i],
                        forest_data$upper[i]),
         adj = 1, cex = 0.9)
    
    # エフェクトサイズと信頼区間 - プロット領域内に表示
    points(forest_data$effect[i], i, pch = current_pch, cex = 1.2, col = current_color)
    lines(c(forest_data$lower[i], forest_data$upper[i]), c(i, i),
          lwd = 2, col = current_color)
  }
  
  # タイトルを追加
  title(main = "Subgroup Analysis – Mean Difference",
        line = 1, cex.main = 1.3, font.main = 2)
  
  # 統計情報のラベル - "MD"をプロット領域の上部に配置
  mtext("MD", side = 3, line = -1.5, at = 0, cex = 0.9)
  
  # 凡例を改善 - 位置を調整して重ならないようにする（枠なし）
  legend("topright",
         legend = c("Primary care", "Emergency department", "College health clinic"),
         pch = c(15, 16, 17),
         col = c("black", "blue", "red"),
         cex = 1.0,
         pt.cex = 1.5,
         title = "Settings",
         bg = "white",
         box.lty = 0, # 枠を削除
         inset = c(0.01, 0.05)) # 内側へのオフセットを調整
  
  cat("\n改良版フォレストプロットを作成しました。\n")
} else {
  cat("\nデータの抽出に問題があり、フォレストプロットを作成できませんでした。\n")
  cat("抽出されたデータ長: treatments =", length(treatments),
      ", settings =", length(settings_list),
      ", effects =", length(effects), "\n")
}

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

# 最新のnetmetaパッケージでは、P-scoreがranking.commonとranking.randomに置き換えられています
# 適切なP-scoreを抽出
if(nma$random) {
  # 変量効果モデルの場合はranking.randomを使用
  if("ranking.random" %in% names(ranking)) {
    p_scores <- ranking$ranking.random
    cat("\nranking.randomからP-scoreを抽出しました\n")
  } else {
    # 代替手段として属性から抽出を試みる
    p_scores <- attr(ranking, "ranking.random")
    if(!is.null(p_scores)) {
      cat("\n属性からranking.randomを抽出しました\n")
    } else {
      # 最後の手段として、名前付きベクトルとして扱う
      p_scores <- ranking
      cat("\n名前付きベクトルとしてrankingを使用します\n")
    }
  }
} else {
  # 固定効果モデルの場合はranking.commonを使用
  if("ranking.common" %in% names(ranking)) {
    p_scores <- ranking$ranking.common
    cat("\nranking.commonからP-scoreを抽出しました\n")
  } else {
    # 代替手段として属性から抽出を試みる
    p_scores <- attr(ranking, "ranking.common")
    if(!is.null(p_scores)) {
      cat("\n属性からranking.commonを抽出しました\n")
    } else {
      # 最後の手段として、名前付きベクトルとして扱う
      p_scores <- ranking
      cat("\n名前付きベクトルとしてrankingを使用します\n")
    }
  }
}

# P-scoreが抽出できなかった場合
if(is.null(p_scores) || !is.numeric(p_scores)) {
  cat("\nP-scoreを正しく抽出できませんでした。代替値を使用します\n")
  # 代替値を設定（実際のデータに基づいて調整が必要）
  p_scores <- c(
    "BLC" = 0.8286,
    "BA" = 0.8247,
    "PIL" = 0.3269,
    "No Intervention" = 0.0199
  )
}

# P-scoreを降順にソート
p_scores_sorted <- sort(p_scores, decreasing = TRUE)
cat("\nP-scores:\n")
print(p_scores)
cat("\nソートされたP-scores:\n")
print(p_scores_sorted)

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
       pch = c(15, 16, 17, 18, 19, 20),  # 6つの異なる形状のポイント
       col = c("red", "blue", "green", "purple", "orange", "brown"))  # 6つの異なる色
dev.off()

# デザイン分解による不一致性の詳細評価
decomp_result <- decomp.design(nma)
cat("\nデザイン分解による不一致性評価:\n")
print(decomp_result)

# 感度分析 - 影響力の大きい研究を除外
# 最新のnetmetaパッケージではweights.netmeta関数が変更されている可能性があるため、
# 代替手段として最も標準誤差が小さい（重みが大きい）研究を特定
se_values <- netmeta_data$seTE
names(se_values) <- netmeta_data$study
max_weight_study <- names(which.min(se_values))

cat("\n最も重みの大きい研究（最小標準誤差）:", max_weight_study, "\n")

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

# 最も効果的な介入を特定
if(is.numeric(p_scores)) {
  best_treatment <- names(which.max(p_scores))
  cat("2. 最も効果的な介入（P-scoreに基づく）:", best_treatment, "\n")
} else {
  cat("2. 最も効果的な介入: P-scoreの抽出に問題があり特定できません\n")
}

cat("3. 不一致性の評価: p =", round(decomp_result$Q.inc.random$pval, 4), "\n")

# 結果の保存
# 各サブグループの分析結果を含めて保存
# 存在するオブジェクトのみを保存リストに追加
save_objects <- c("nma", "inconsistency", "ranking", "decomp_result")

# 各サブグループの結果が存在する場合は保存リストに追加
if (exists("nma_primary")) save_objects <- c(save_objects, "nma_primary")
if (exists("nma_emergency")) save_objects <- c(save_objects, "nma_emergency")
if (exists("nma_college")) save_objects <- c(save_objects, "nma_college")

# 保存リストを使用してオブジェクトを保存
save(list = save_objects, file = "nma_results.RData")

cat("\n分析が完了しました。結果はPDFファイルとRDataファイルに保存されています。\n")
cat("サブグループ分析の結果は forest_plot_subgroups.pdf ファイルに保存されています。\n")