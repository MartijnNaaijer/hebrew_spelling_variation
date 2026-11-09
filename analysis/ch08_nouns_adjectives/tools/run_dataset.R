# Runner for <id>/analysis.R, sections 0-3d (or 0-3e with the argument
# 'final', once FINAL_ID is set: drop-one models and prior fits). Used for the approved fitting runs
# (first_w 2026-10-21, single_w and final_w 2026-10-22). ALLOW_FIT is set TRUE
# here only; the script files keep FALSE. Stops before 3e (FINAL_ID is the
# author's choice).
#
# Usage (from a scratch folder, not from this folder):
#   Rscript <analysis_nouns>/run/run_dataset.R <id> > <analysis_nouns>/run/logs/<id>_run.log 2>&1
# Memory log alongside (optional):
#   powershell -NoProfile -ExecutionPolicy Bypass -File <analysis_nouns>/run/memlog.ps1 -id <id>
# Fitted models and k-folds that exist in MODEL_FOLDER are loaded, not refitted,
# so an interrupted run can simply be restarted. Writes run/logs/<id>_done.flag
# at the end (also after an error). Only start a run the author has approved.

ID <- commandArgs(trailingOnly = TRUE)[1]
TO_FINAL <- identical(commandArgs(trailingOnly = TRUE)[2], 'final')
stopifnot(ID %in% c('first_w', 'single_w', 'final_w', 'affix_types_mt'))
ANALYSIS_DIR <- 'C:/Users/geitb/Dropbox/monograph_orthography/nouns_adjectives/analysis_nouns'
LOG_DIR <- file.path(ANALYSIS_DIR, 'run', 'logs')
flag <- file.path(LOG_DIR, paste0(ID, '_done.flag'))
unlink(flag)
f <- file.path(ANALYSIS_DIR, ID, 'analysis.R')
txt <- readLines(f, encoding = 'UTF-8')
cut <- grep(if (TO_FINAL) '^# ==== 4. DATA VISUALISATION ====' else '^# ---- 3e. Final models? ----', txt)
stopifnot(length(cut) == 1)
txt <- txt[seq_len(cut - 1)]
i <- grep('^ALLOW_FIT <- FALSE', txt); stopifnot(length(i) == 1)
txt[i] <- 'ALLOW_FIT <- TRUE'
exprs <- parse(text = txt, encoding = 'UTF-8')
# The external disk D: disconnected once during a run (2026-10-22)
stopifnot('Model folder (drive D:) not available' = dir.exists('D:/brms_models_spelling/analysis_nouns'))
tryCatch({
  cat('Start', ID, ':', format(Sys.time()), '\n')
  for (e in exprs) {
    t0 <- Sys.time()
    v <- withVisible(eval(e, globalenv())); if (v$visible) print(v$value)
    if (as.numeric(difftime(Sys.time(), t0, units = 'mins')) > 1)
      cat(sprintf('[%s] done after %.1f min: %s\n', format(Sys.time()),
                  as.numeric(difftime(Sys.time(), t0, units = 'mins')),
                  substr(paste(deparse(e), collapse = ' '), 1, 80)))
  }
  cat('End', ID, ':', format(Sys.time()), '\n')
}, finally = writeLines(format(Sys.time()), flag))
