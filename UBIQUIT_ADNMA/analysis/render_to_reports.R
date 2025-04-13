# Script to render generate_results.Rmd to the reports directory

# Render the Rmd file to the reports directory
rmarkdown::render(
  "generate_results.Rmd",
  output_file = "../reports/generate_results.pdf",
  output_dir = "../reports/"
)

# Print success message
cat("PDF successfully generated in ../reports/ directory\n")