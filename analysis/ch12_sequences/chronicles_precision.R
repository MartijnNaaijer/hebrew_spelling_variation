################################################################################
# Chapter 12: precision check for Chronicles (author, 2026-11-14)
#
# In the main run (B = 10,000) the stratified p of Chronicles (qal active
# participle) is 9/10,001, and its Benjamini-Hochberg value over the 29
# informative MT books is 2 x 0.0009 x 29 = 0.052: just above 0.05, and within
# Monte Carlo error of it (one permutation more or less changes the verdict).
# This script reruns the stratified null (within lexeme x suffix) and the
# model-based null of Chronicles with B = 1,000,000 and recomputes both
# corrections with the p-values of the other books from results/units.tsv
# (unchanged; Chronicles has the smallest p in both corrections).
#
# Run from the repository root, after sequence_analysis.R:
#   Rscript analysis/ch12_sequences/chronicles_precision.R   (a few minutes)
# Output: results/chronicles_precision.tsv
################################################################################

suppressMessages(source('analysis/ch12_sequences/sequence_analysis.R'))   # definitions only (main block is skipped)

BIG <- as.integer(Sys.getenv('CH12_BIG', '1000000'))
FEATURE <- 'ptca_qal'; UNIT <- 'Chronicles'

d <- read_sequences(FEATURE) |> filter(unit == UNIT)
x <- d$full; obs <- n_changes(x)

set.seed(SEED + 1)
k_strat <- 0L; k_strat_alt <- 0L; done <- 0L
while (done < BIG) {      # in chunks, to keep memory small
  b <- min(100000L, BIG - done)
  st <- permute(x, d$stratum, b)
  k_strat <- k_strat + sum(st$changes <= obs); k_strat_alt <- k_strat_alt + sum(st$changes >= obs)
  done <- done + b
}
set.seed(SEED + 2)
mo <- cb_sim(x, d$eta, BIG)
k_model <- sum(mo$changes <= obs); k_model_alt <- sum(mo$changes >= obs)

p1 <- function(k) (k + 1) / (BIG + 1)
mc_ci <- function(k) binom.test(k, BIG)$conf.int     # Monte Carlo 95% interval of the one-sided p
u <- read_tsv(file.path(RES, 'units.tsv'), show_col_types = FALSE) |> filter(feature == FEATURE, corpus == 'MT')
bh_with <- function(p2_col, keep, p2_new) {
  v <- u[keep, ]
  p2 <- v[[p2_col]]; p2[v$unit == UNIT] <- p2_new
  p.adjust(p2, 'BH')[v$unit == UNIT]
}
strat_p2 <- min(1, 2 * min(p1(k_strat), p1(k_strat_alt)))
model_p2 <- min(1, 2 * min(p1(k_model), p1(k_model_alt)))
old <- u |> filter(unit == UNIT)

out <- tibble(
  null = c('within lexeme and suffix', 'model-based'),
  permutations = BIG,
  changes = obs,
  k_as_few_changes = c(k_strat, k_model),
  p_block = c(p1(k_strat), p1(k_model)),
  p_block_mc_low = c(mc_ci(k_strat)[1], mc_ci(k_model)[1]),
  p_block_mc_high = c(mc_ci(k_strat)[2], mc_ci(k_model)[2]),
  p_two_sided = c(strat_p2, model_p2),
  books_in_correction = c(sum(u$strat_informative), sum(!is.na(u$model_p2))),
  p_corrected = c(bh_with('strat_p2', u$strat_informative, strat_p2),
                  bh_with('model_p2', !is.na(u$model_p2), model_p2)),
  p_block_main_run = c(old$strat_p_block, old$model_p_block),
  p_corrected_main_run = c(old$strat_q, old$model_q))
write_tsv(out, file.path(RES, 'chronicles_precision.tsv'))
print(as.data.frame(out))
