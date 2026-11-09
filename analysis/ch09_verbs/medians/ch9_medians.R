# Chapter 9 Tables 9.39, 9.46, 9.54 (2026-11-04): posterior median, SD, 95% quantile CrI, pd from the stored final fits.
# Run from the repository root: Rscript analysis/ch09_verbs/medians/ch9_medians.R
# (writes ch9_medians.tsv to this folder, or to the folder in the environment variable S). Table 9.73: see ch9_medians_pey.R.
suppressMessages(library(posterior))
source('analysis/paths.R')
F <- paste0(file.path(MODEL_ROOT, 'analysis_verbs'), '/')
fits <- c(t939 = 'infc2_M2', t946 = 'infc_lh2_M4p', t954 = 'infa2_M3', t973 = 'pey2_M1')
f2 <- function(x) formatC(x, format = 'f', digits = 2)
out <- list()
for (k in names(fits)) {
  m <- readRDS(paste0(F, fits[[k]], '.rds'))
  d <- as_draws_df(m)
  v <- grep('^b_|^sd_', names(d), value = TRUE)
  cat('\n==', k, fits[[k]], ' draws', nrow(d), '\n')
  for (p in v) {
    x <- d[[p]]
    pd <- max(mean(x > 0), mean(x < 0))
    row <- data.frame(table = k, param = p, mean = mean(x), median = median(x), sd = sd(x),
                      l95 = quantile(x, 0.025), u95 = quantile(x, 0.975), pd = pd)
    out[[length(out) + 1]] <- row
    cat(sprintf('%-40s mean %6s | median %6s sd %5s [%6s, %6s] pd %s\n', p, f2(mean(x)), f2(median(x)), f2(sd(x)),
                f2(quantile(x, .025)), f2(quantile(x, .975)), if (grepl('^b_', p)) f2(pd) else ''))
  }
}
write.table(do.call(rbind, out), file.path(Sys.getenv('S', file.path(CH09_DIR, 'medians')), 'ch9_medians.tsv'), sep = '\t', row.names = FALSE, quote = FALSE)
