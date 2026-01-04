################################################################################
#                                                                              #
#   NONLINEAR DIFFERENCE-IN-DIFFERENCES PROJECT                                #
#   Estimation and Analysis                                                    #
#                                                                              #
#   Author:  Spencer Sween                                                     #
#   Purpose: Estimate ATT using Callaway-Sant'Anna DiD framework with          #
#            custom doubly-robust estimators for linear and nonlinear          #
#            parallel trend assumptions                                        #
#                                                                              #
#   Input Files:                                                               #
#     - scp_pdit_county.csv (Final analysis dataset from Stata prep)           #
#                                                                              #
#   Methods:                                                                   #
#     - Linear PT:    Standard DiD with additive outcome trends                #
#     - Nonlinear PT: Ratio-based DiD (Wooldridge 2023 style)                  #
#                                                                              #
#   Estimators:                                                                #
#     - No covariates (simple means)                                           #
#     - Doubly-robust regression (GLM)                                         #
#     - Doubly-robust machine learning (GRF)                                   #
#                                                                              #
################################################################################

rm(list = ls())
gc()


################################################################################
#                                                                              #
#   SECTION 1: CONFIGURATION                                                   #
#                                                                              #
################################################################################

#-------------------------------------------------------------------------------
# Set Working Directory
#-------------------------------------------------------------------------------

setwd("~/Dropbox/Non-Linear DiD Claude Project/original/final/")

#-------------------------------------------------------------------------------
# Load Packages
#-------------------------------------------------------------------------------

library(data.table)
library(dplyr)
library(tidyr)
library(purrr)
library(ggplot2)
library(grf)
library(did)
library(knitr)
library(DoubleML)
library(mlr3learners)
library(fastglm)
library(DescTools)

#-------------------------------------------------------------------------------
# Analysis Settings
#-------------------------------------------------------------------------------

# Reproducibility
chosen_seed <- 42

# Sample selection: "rnd" (R&D credit), "itc" (investment credit), or "both"
chosen_sample <- "rnd"

# Outcome variable: "sfr" (startups), "eqi" (quality index), or "growth"
chosen_outcome <- "sfr"

# GRF parameters
grf_num_trees   <- 200
grf_num_threads <- max(1, parallel::detectCores() - 1)

# Numerical stability threshold
eps <- 1e-3


################################################################################
#                                                                              #
#   SECTION 2: HELPER FUNCTIONS                                                #
#                                                                              #
################################################################################

#-------------------------------------------------------------------------------
# Callaway-Sant'Anna DiD Wrapper
#-------------------------------------------------------------------------------

#' Wrapper for did::att_gt() with sensible defaults
#'
#' @param d Data frame with required columns: Outcome, Time, Unit, Cohort, Cluster
#' @param f Covariate formula (default: no covariates)
#' @param e Estimation method (string or custom function)
#' @param c Control group: "nevertreated" or "notyettreated"
#' @param b Base period: "varying" or "universal"
#' @return att_gt object

csdid <- function(d, f = ~ 1, e = "dr", c = "nevertreated", b = "varying") {
  att_gt <- did::att_gt(
    yname         = "Outcome",
    tname         = "Time",
    idname        = "Unit",
    gname         = "Cohort",
    clustervars   = "Cluster",
    data          = d,
    control_group = c,
    base_period   = b,
    xformla       = f,
    est_method    = e,
    print_details = TRUE
  )
  return(att_gt)
}

#-------------------------------------------------------------------------------
# Results Display Helper
#-------------------------------------------------------------------------------

#' Display formatted estimation results
#'
#' @param psi Influence function vector
#' @param nobs Number of observations
#' @param method_name Name of estimation method for display

display_results <- function(psi, nobs, method_name = "AutoDML") {
  psi <- as.matrix(psi)
  estimates  <- colMeans(psi)
  std_errors <- apply(psi, 2, sd) / sqrt(nobs)
  
  mat <- rbind(estimates, std_errors)
  colnames(mat) <- method_name
  rownames(mat) <- c("Estimate", "Std. Error")
  
  results_wide <- as_tibble(mat, rownames = "Statistic")
  m <- kable(
    results_wide,
    caption = "Non-Linear DiD Estimates and Standard Errors",
    digits = 3,
    align = "l"
  )
  print(m)
}


################################################################################
#                                                                              #
#   SECTION 3: LINEAR PARALLEL TRENDS ESTIMATORS                               #
#                                                                              #
#   Assumption: E[Y(1) - Y(0) | D=1] = E[Y(1) - Y(0) | D=0]                     #
#   (Additive trends are parallel across treatment groups)                     #
#                                                                              #
################################################################################

#-------------------------------------------------------------------------------
# 3A: No Covariates - Simple Difference-in-Means
#-------------------------------------------------------------------------------

#' ATT estimator under linear parallel trends, no covariates
#'
#' Uses simple group means for outcome regression and propensity score.
#' Implements Neyman-orthogonal influence function for valid inference.
#'
#' @param y1 Post-treatment outcomes
#' @param y0 Pre-treatment outcomes
#' @param D Treatment indicator
#' @param covariates Covariate matrix (unused but required by did package)
#' @param ... Additional arguments (ignored)
#' @return List with ATT estimate and centered influence function

my_nox_linear <- function(y1, y0, D, covariates, ...) {
  
  # Process inputs
  outcome_pre   <- as.numeric(y0)
  outcome_post  <- as.numeric(y1)
  treated       <- as.numeric(D)
  covariates    <- as.matrix(covariates)
  
  # Compute outcome trend
  outcome_trend <- outcome_post - outcome_pre
  
  # Get dimensions
  nobs <- length(outcome_post)
  
  # Estimate nuisance functions (simple means, no covariates)
  dyhat_0 <- rep(mean(outcome_trend[treated == 0]), nobs)
  pscore  <- rep(mean(treated), nobs)
  
  # Clamp propensity scores for numerical stability
  pscore <- pmax(eps, pmin(1 - eps, pscore))
  
  # Plug-in component
  q      <- mean(treated)
  plugin <- (1 / q) * treated * (outcome_trend - dyhat_0)
  
  # Debiasing component (Neyman orthogonality correction)
  riesz     <- (-1 / q) * (pscore / (1 - pscore))
  grad_loss <- (1 - treated) * (outcome_trend - dyhat_0)
  debias    <- riesz * grad_loss
  
  # Construct influence function
  psi_1 <- plugin + debias
  psi_2 <- (-1 / q) * mean(psi_1) * (treated - q)
  psi   <- psi_1 + psi_2
  
  # Display results
  display_results(psi, nobs, "Linear-NoCov")
  
  # Return ATT and centered influence function
  att      <- mean(psi)
  inf.func <- psi - att
  return(list(ATT = att, att.inf.func = inf.func))
}

#-------------------------------------------------------------------------------
# 3B: Doubly-Robust Regression (GLM)
#-------------------------------------------------------------------------------

#' ATT estimator under linear parallel trends with GLM nuisance estimation
#'
#' Uses OLS for outcome regression and logit for propensity score.
#' Doubly-robust: consistent if either model is correctly specified.
#'
#' @inheritParams my_nox_linear
#' @return List with ATT estimate and centered influence function

my_drreg_linear <- function(y1, y0, D, covariates, ...) {
  
  # Process inputs
  outcome_pre   <- as.numeric(y0)
  outcome_post  <- as.numeric(y1)
  treated       <- as.numeric(D)
  covariates    <- as.matrix(covariates)
  
  # Compute outcome trend
  outcome_trend <- outcome_post - outcome_pre
  
  # Get dimensions
  nobs <- length(outcome_post)
  
  # Estimate nuisance functions using GLM
  # Outcome model: E[ΔY | X, D=0]
  dyhat_0 <- predict(
    fastglm::fastglm(
      x      = covariates[treated == 0, ],
      y      = outcome_trend[treated == 0],
      family = gaussian()
    ),
    covariates,
    type = "response"
  )
  
  # Propensity score: P(D=1 | X)
  pscore <- predict(
    fastglm::fastglm(
      x      = covariates,
      y      = treated,
      family = binomial()
    ),
    covariates,
    type = "response"
  )
  
  # Clamp propensity scores for numerical stability
  pscore <- pmax(eps, pmin(1 - eps, pscore))
  
  # Plug-in component
  q      <- mean(treated)
  plugin <- (1 / q) * treated * (outcome_trend - dyhat_0)
  
  # Debiasing component (Neyman orthogonality correction)
  riesz     <- (-1 / q) * (pscore / (1 - pscore))
  grad_loss <- (1 - treated) * (outcome_trend - dyhat_0)
  debias    <- riesz * grad_loss
  
  # Construct influence function
  psi_1 <- plugin + debias
  psi_2 <- (-1 / q) * mean(psi_1) * (treated - q)
  psi   <- psi_1 + psi_2
  
  # Display results
  display_results(psi, nobs, "Linear-DR-GLM")
  
  # Return ATT and centered influence function
  att      <- mean(psi)
  inf.func <- psi - att
  return(list(ATT = att, att.inf.func = inf.func))
}

#-------------------------------------------------------------------------------
# 3C: Doubly-Robust Machine Learning (GRF)
#-------------------------------------------------------------------------------

#' ATT estimator under linear parallel trends with GRF nuisance estimation
#'
#' Uses honest regression forests for both outcome and propensity models.
#' Achieves root-n consistency under weaker assumptions than GLM.
#'
#' @inheritParams my_nox_linear
#' @return List with ATT estimate and centered influence function

my_drml_linear <- function(y1, y0, D, covariates, ...) {
  
  # Process inputs
  outcome_pre   <- as.numeric(y0)
  outcome_post  <- as.numeric(y1)
  treated       <- as.numeric(D)
  covariates    <- as.matrix(covariates)
  
  # Compute outcome trend
  outcome_trend <- outcome_post - outcome_pre
  
  # Get dimensions
  nobs <- length(outcome_post)
  
  # Estimate nuisance functions using GRF
  # Outcome model: E[ΔY | X, D=0]
  dyhat_0 <- predict(
    regression_forest(
      covariates[treated == 0, ],
      outcome_trend[treated == 0],
      seed        = chosen_seed,
      num.threads = grf_num_threads,
      honesty     = TRUE,
      num.trees   = grf_num_trees
    ),
    covariates
  )$predictions
  
  # Propensity score: P(D=1 | X)
  pscore <- predict(
    regression_forest(
      covariates,
      treated,
      seed        = chosen_seed,
      num.threads = grf_num_threads,
      honesty     = TRUE,
      num.trees   = grf_num_trees
    ),
    covariates
  )$predictions
  
  # Clamp propensity scores for numerical stability
  pscore <- pmax(eps, pmin(1 - eps, pscore))
  
  # Plug-in component
  q      <- mean(treated)
  plugin <- (1 / q) * treated * (outcome_trend - dyhat_0)
  
  # Debiasing component (Neyman orthogonality correction)
  riesz     <- (-1 / q) * (pscore / (1 - pscore))
  grad_loss <- (1 - treated) * (outcome_trend - dyhat_0)
  debias    <- riesz * grad_loss
  
  # Construct influence function
  psi_1 <- plugin + debias
  psi_2 <- (-1 / q) * mean(psi_1) * (treated - q)
  psi   <- psi_1 + psi_2
  
  # Display results
  display_results(psi, nobs, "Linear-DR-GRF")
  
  # Return ATT and centered influence function
  att      <- mean(psi)
  inf.func <- psi - att
  return(list(ATT = att, att.inf.func = inf.func))
}


################################################################################
#                                                                              #
#   SECTION 4: NONLINEAR PARALLEL TRENDS ESTIMATORS                            #
#                                                                              #
#   Assumption: E[Y(1)/Y(0) | D=1] = E[Y(1)/Y(0) | D=0]                         #
#   (Multiplicative/ratio trends are parallel across treatment groups)         #
#                                                                              #
#   Reference: Wooldridge (2023), "Simple Approaches to Nonlinear DiD"         #
#                                                                              #
################################################################################

#-------------------------------------------------------------------------------
# 4A: No Covariates - Simple Ratio Estimator
#-------------------------------------------------------------------------------

#' ATT estimator under nonlinear (ratio) parallel trends, no covariates
#'
#' Estimates ATT as percentage change relative to counterfactual.
#' Uses simple group means for all nuisance functions.
#'
#' @inheritParams my_nox_linear
#' @return List with ATT estimate and centered influence function

my_nox_nonlinear <- function(y1, y0, D, covariates, ...) {
  
  # Process inputs
  outcome_pre  <- as.numeric(y0)
  outcome_post <- as.numeric(y1)
  treated      <- as.numeric(D)
  covariates   <- as.matrix(covariates)
  
  # Get dimensions
  nobs <- length(outcome_post)
  
  # Estimate nuisance functions (simple means, no covariates)
  yhat_0_pre  <- rep(mean(outcome_pre[treated == 0]),  nobs)
  yhat_1_pre  <- rep(mean(outcome_pre[treated == 1]),  nobs)
  yhat_0_post <- rep(mean(outcome_post[treated == 0]), nobs)
  yhat_1_post <- rep(mean(outcome_post[treated == 1]), nobs)
  pscore      <- rep(mean(treated), nobs)
  
  # Clamp predictions for numerical stability
  yhat_1_pre  <- pmax(eps, yhat_1_pre)
  yhat_1_post <- pmax(eps, yhat_1_post)
  pscore      <- pmax(eps, pmin(1 - eps, pscore))
  
  # Plug-in component: Y_post * (Y_0_pre / Y_1_pre) / Y_0_post - 1
  q           <- mean(treated)
  numerator1  <- outcome_post * yhat_0_pre
  denominator <- pmax(yhat_1_pre * yhat_0_post, eps)
  plugin      <- (treated / q) * (numerator1 / denominator - 1)
  
  # Debiasing component (Neyman orthogonality correction for ratio estimator)
  numerator2 <- yhat_1_post * yhat_0_pre
  EdH00      <-  (pscore / q) * (yhat_1_post / denominator)
  EdH01      <- -(pscore / q) * (numerator2 / pmax(denominator * yhat_0_post, eps))
  EdH10      <- -(pscore / q) * (numerator2 / pmax(denominator * yhat_1_pre, eps))
  
  ell00 <- (treated == 0) * (outcome_pre  - yhat_0_pre)
  ell01 <- (treated == 0) * (outcome_post - yhat_0_post)
  ell10 <- (treated == 1) * (outcome_pre  - yhat_1_pre)
  
  i_1m_pscore <- 1 / pmax(1 - pscore, eps)
  i_pscore    <- 1 / pmax(pscore, eps)
  
  debias <- (EdH00 * i_1m_pscore * ell00) +
    (EdH01 * i_1m_pscore * ell01) +
    (EdH10 * i_pscore * ell10)
  
  # Construct influence function
  psi_1 <- plugin + debias
  psi_2 <- (-1 / q) * mean(psi_1) * (treated - q)
  psi   <- psi_1 + psi_2
  
  # Display results
  display_results(psi, nobs, "Nonlinear-NoCov")
  
  # Return ATT and centered influence function
  att      <- mean(psi)
  inf.func <- psi - att
  return(list(ATT = att, att.inf.func = inf.func))
}

#-------------------------------------------------------------------------------
# 4B: Neyman-Orthogonal Regression (Poisson GLM)
#-------------------------------------------------------------------------------

#' ATT estimator under nonlinear parallel trends with Poisson GLM
#'
#' Uses Poisson regression for outcome models (appropriate for count data)
#' and logit for propensity scores. Includes winsorization for stability.
#'
#' @inheritParams my_nox_linear
#' @return List with ATT estimate and centered influence function

my_noreg_nonlinear <- function(y1, y0, D, covariates, ...) {
  
  # Process inputs
  outcome_pre  <- as.numeric(y0)
  outcome_post <- as.numeric(y1)
  treated      <- as.numeric(D)
  covariates   <- as.matrix(covariates)
  
  # Get dimensions
  nobs <- length(outcome_post)
  
  # Estimate outcome models using Poisson GLM (for count outcomes)
  yhat_0_pre <- predict(
    fastglm::fastglm(
      x      = covariates[treated == 0, ],
      y      = outcome_pre[treated == 0],
      family = poisson()
    ),
    covariates,
    type = "response"
  )
  
  yhat_0_post <- predict(
    fastglm::fastglm(
      x      = covariates[treated == 0, ],
      y      = outcome_post[treated == 0],
      family = poisson()
    ),
    covariates,
    type = "response"
  )
  
  yhat_1_pre <- predict(
    fastglm::fastglm(
      x      = covariates[treated == 1, ],
      y      = outcome_pre[treated == 1],
      family = poisson()
    ),
    covariates,
    type = "response"
  )
  
  yhat_1_post <- predict(
    fastglm::fastglm(
      x      = covariates[treated == 1, ],
      y      = outcome_post[treated == 1],
      family = poisson()
    ),
    covariates,
    type = "response"
  )
  
  # Estimate propensity score using logit
  pscore <- predict(
    fastglm::fastglm(
      x      = covariates,
      y      = treated,
      family = binomial()
    ),
    covariates,
    type = "response"
  )
  
  # Clamp predictions for numerical stability
  yhat_0_pre  <- pmax(eps, yhat_0_pre)
  yhat_0_post <- pmax(eps, yhat_0_post)
  yhat_1_pre  <- pmax(eps, yhat_1_pre)
  yhat_1_post <- pmax(eps, yhat_1_post)
  pscore      <- pmax(eps, pmin(1 - eps, pscore))
  
  # Plug-in component
  q           <- mean(treated)
  numerator1  <- outcome_post * yhat_0_pre
  denominator <- pmax(yhat_1_pre * yhat_0_post, eps)
  plugin      <- (treated / q) * (numerator1 / denominator - 1)
  
  # Debiasing component
  numerator2 <- yhat_1_post * yhat_0_pre
  EdH00      <-  (pscore / q) * (yhat_1_post / denominator)
  EdH01      <- -(pscore / q) * (numerator2 / pmax(denominator * yhat_0_post, eps))
  EdH10      <- -(pscore / q) * (numerator2 / pmax(denominator * yhat_1_pre, eps))
  
  ell00 <- (treated == 0) * (outcome_pre  - yhat_0_pre)
  ell01 <- (treated == 0) * (outcome_post - yhat_0_post)
  ell10 <- (treated == 1) * (outcome_pre  - yhat_1_pre)
  
  i_1m_pscore <- 1 / pmax(1 - pscore, eps)
  i_pscore    <- 1 / pmax(pscore, eps)
  
  debias <- (EdH00 * i_1m_pscore * ell00) +
    (EdH01 * i_1m_pscore * ell01) +
    (EdH10 * i_pscore * ell10)
  
  # Winsorize debiasing term for stability (1st and 99th percentiles)
  wins   <- 0.01
  debias <- DescTools::Winsorize(debias, quantile(debias, probs = c(wins, 1 - wins)))
  
  # Construct influence function
  psi_1 <- plugin + debias
  psi_2 <- (-1 / q) * mean(psi_1) * (treated - q)
  psi   <- psi_1 + psi_2
  
  # Display results
  display_results(psi, nobs, "Nonlinear-Poisson")
  
  # Return ATT and centered influence function
  att      <- mean(psi)
  inf.func <- psi - att
  return(list(ATT = att, att.inf.func = inf.func))
}

#-------------------------------------------------------------------------------
# 4C: Neyman-Orthogonal Machine Learning (GRF)
#-------------------------------------------------------------------------------

#' ATT estimator under nonlinear parallel trends with GRF nuisance estimation
#'
#' Uses honest regression forests for all nuisance functions.
#' Most flexible approach but computationally intensive.
#'
#' @inheritParams my_nox_linear
#' @return List with ATT estimate and centered influence function

my_noml_nonlinear <- function(y1, y0, D, covariates, ...) {
  
  # Process inputs
  outcome_pre  <- as.numeric(y0)
  outcome_post <- as.numeric(y1)
  treated      <- as.numeric(D)
  covariates   <- as.matrix(covariates)
  
  # Get dimensions
  nobs <- length(outcome_post)
  
  # Estimate outcome models using GRF
  # E[Y_pre | X, D=0]
  yhat_0_pre <- predict(
    regression_forest(
      covariates[treated == 0, ],
      outcome_pre[treated == 0],
      seed        = chosen_seed,
      num.threads = grf_num_threads,
      honesty     = TRUE,
      num.trees   = grf_num_trees
    ),
    covariates
  )$predictions
  
  # E[Y_pre | X, D=1]
  yhat_1_pre <- predict(
    regression_forest(
      covariates[treated == 1, ],
      outcome_pre[treated == 1],
      seed        = chosen_seed,
      num.threads = grf_num_threads,
      honesty     = TRUE,
      num.trees   = grf_num_trees
    ),
    covariates
  )$predictions
  
  # E[Y_post | X, D=0]
  yhat_0_post <- predict(
    regression_forest(
      covariates[treated == 0, ],
      outcome_post[treated == 0],
      seed        = chosen_seed,
      num.threads = grf_num_threads,
      honesty     = TRUE,
      num.trees   = grf_num_trees
    ),
    covariates
  )$predictions
  
  # E[Y_post | X, D=1]
  yhat_1_post <- predict(
    regression_forest(
      covariates[treated == 1, ],
      outcome_post[treated == 1],
      seed        = chosen_seed,
      num.threads = grf_num_threads,
      honesty     = TRUE,
      num.trees   = grf_num_trees
    ),
    covariates
  )$predictions
  
  # P(D=1 | X)
  pscore <- predict(
    regression_forest(
      covariates,
      treated,
      seed        = chosen_seed,
      num.threads = grf_num_threads,
      honesty     = TRUE,
      num.trees   = grf_num_trees
    ),
    covariates
  )$predictions
  
  # Clamp predictions for numerical stability
  yhat_0_pre  <- pmax(eps, yhat_0_pre)
  yhat_0_post <- pmax(eps, yhat_0_post)
  yhat_1_pre  <- pmax(eps, yhat_1_pre)
  yhat_1_post <- pmax(eps, yhat_1_post)
  pscore      <- pmax(eps, pmin(1 - eps, pscore))
  
  # Plug-in component
  q           <- mean(treated)
  numerator1  <- outcome_post * yhat_0_pre
  denominator <- pmax(yhat_1_pre * yhat_0_post, eps)
  plugin      <- (treated / q) * (numerator1 / denominator - 1)
  
  # Debiasing component
  numerator2 <- yhat_1_post * yhat_0_pre
  EdH00      <-  (pscore / q) * (yhat_1_post / denominator)
  EdH01      <- -(pscore / q) * (numerator2 / pmax(denominator * yhat_0_post, eps))
  EdH10      <- -(pscore / q) * (numerator2 / pmax(denominator * yhat_1_pre, eps))
  
  ell00 <- (treated == 0) * (outcome_pre  - yhat_0_pre)
  ell01 <- (treated == 0) * (outcome_post - yhat_0_post)
  ell10 <- (treated == 1) * (outcome_pre  - yhat_1_pre)
  
  i_1m_pscore <- 1 / pmax(1 - pscore, eps)
  i_pscore    <- 1 / pmax(pscore, eps)
  
  debias <- (EdH00 * i_1m_pscore * ell00) +
    (EdH01 * i_1m_pscore * ell01) +
    (EdH10 * i_pscore * ell10)
  
  # Winsorize debiasing term for stability (0.001th and 99.999th percentiles)
  wins   <- 1e-5
  debias <- DescTools::Winsorize(debias, quantile(debias, probs = c(wins, 1 - wins)))
  
  # Construct influence function
  psi_1 <- plugin + debias
  psi_2 <- (-1 / q) * mean(psi_1) * (treated - q)
  psi   <- psi_1 + psi_2
  
  # Display results
  display_results(psi, nobs, "Nonlinear-GRF")
  
  # Return ATT and centered influence function
  att      <- mean(psi)
  inf.func <- psi - att
  return(list(ATT = att, att.inf.func = inf.func))
}


################################################################################
#                                                                              #
#   SECTION 5: DATA PREPARATION                                                #
#                                                                              #
################################################################################

#-------------------------------------------------------------------------------
# Load Raw Data
#-------------------------------------------------------------------------------

df_raw <- fread("scp_pdit_county.csv") |> as_tibble()

#-------------------------------------------------------------------------------
# Select Sample Based on Treatment Definition
#-------------------------------------------------------------------------------

if (chosen_sample == "rnd") {
  
  # R&D Tax Credit sample
  df_filter <- df_raw |>
    filter(Sample_rnd == 1) |>
    mutate(
      Cohort   = G_rnd,
      Treated  = as.numeric(avg_rnd > 0),
      Exposure = avg_rnd
    )
  
} else if (chosen_sample == "itc") {
  
  # Investment Tax Credit sample
  df_filter <- df_raw |>
    filter(Sample_itc == 1) |>
    mutate(
      Cohort   = G_itc,
      Treated  = as.numeric(avg_itc > 0),
      Exposure = avg_itc
    )
  
} else if (chosen_sample == "both") {
  
  # Combined treatment sample
  df_filter <- df_raw |>
    filter(Sample_both == 1) |>
    mutate(
      Cohort   = G_both,
      Treated  = as.numeric(avg_itc > 0 | avg_rnd > 0),
      Exposure = as.numeric(avg_itc > 0 | avg_rnd > 0)
    )
  
} else {
  stop("Invalid sample choice. Use 'rnd', 'itc', or 'both'.")
}

#-------------------------------------------------------------------------------
# Select Outcome Variable
#-------------------------------------------------------------------------------

if (chosen_outcome == "sfr") {
  df_clean <- df_filter |> mutate(Outcome = sfr)
} else if (chosen_outcome == "eqi") {
  df_clean <- df_filter |> mutate(Outcome = eqi)
} else if (chosen_outcome == "growth") {
  df_clean <- df_filter |> mutate(Outcome = growth)
} else {
  stop("Invalid outcome choice. Use 'sfr', 'eqi', or 'growth'.")
}

#-------------------------------------------------------------------------------
# Create Panel Identifiers
#-------------------------------------------------------------------------------

df_clean <- df_clean |>
  mutate(
    Cluster = countyfips,
    Unit    = countyfips,
    Time    = year
  )

#-------------------------------------------------------------------------------
# Define Covariate Formulas
#-------------------------------------------------------------------------------

# Full covariate set (all X_ prefixed variables)
cov_names <- df_clean |>
  dplyr::select(dplyr::starts_with("X_")) |>
  colnames() |>
  paste(collapse = " + ")
xform <- as.formula(paste("~ -1 +", cov_names))

# Parsimonious covariate set (Z variables)
zform <- ~ -1 + Z1 + Z2 + Z3 + Z4 + Z5 + Z6 + Z7


################################################################################
#                                                                              #
#   SECTION 6: ESTIMATION - LINEAR PARALLEL TRENDS                             #
#                                                                              #
################################################################################

cat("\n")
cat("================================================================\n")
cat("  LINEAR PARALLEL TRENDS ESTIMATION                             \n")
cat("  Sample:", chosen_sample, "| Outcome:", chosen_outcome, "\n")
cat("================================================================\n")
cat("\n")

#-------------------------------------------------------------------------------
# Log(1+Y) Transformation with DR-GRF Estimator
#-------------------------------------------------------------------------------

attgt_log1p_drml <- csdid(
  d = df_clean |>
    mutate(Outcome = log1p(Outcome)) |>
    mutate(Cohort = ifelse(Cohort > 2010, 0, Cohort)) |>
    filter(Time >= 1990 & Time <= 2010),
  f = zform,
  e = my_drml_linear,
  c = "nevertreated",
  b = "varying"
)

# Event study plot
ggdid(aggte(attgt_log1p_drml, "dynamic", min_e = -5, max_e = 14)) +
  scale_y_continuous(n.breaks = 10, limits = c(-0.45, 0.60)) +
  labs(
    title    = "Event Study: Linear PT with DR-GRF",
    subtitle = paste0("Sample: ", chosen_sample, " | Outcome: log(1 + ", chosen_outcome, ")")
  )

# Group-specific ATT plot
ggdid(aggte(attgt_log1p_drml, "group", min_e = 0, max_e = 10)) +
  scale_x_continuous(n.breaks = 10, limits = c(-0.75, 0.75)) +
  labs(
    title    = "Group ATT: Linear PT with DR-GRF",
    subtitle = paste0("Sample: ", chosen_sample, " | Outcome: log(1 + ", chosen_outcome, ")")
  )


################################################################################
#                                                                              #
#   SECTION 7: ESTIMATION - NONLINEAR PARALLEL TRENDS                          #
#                                                                              #
################################################################################

cat("\n")
cat("================================================================\n")
cat("  NONLINEAR PARALLEL TRENDS ESTIMATION                          \n")
cat("  Sample:", chosen_sample, "| Outcome:", chosen_outcome, "\n")
cat("================================================================\n")
cat("\n")

#-------------------------------------------------------------------------------
# Level Outcome with NO-GRF Estimator
#-------------------------------------------------------------------------------

attgt_nldid_noml <- csdid(
  d = df_clean |>
    mutate(Outcome = Outcome) |>
    mutate(Cohort = ifelse(Cohort > 2010, 0, Cohort)) |>
    filter(Time >= 1990 & Time <= 2010),
  f = zform,
  e = my_noml_nonlinear,
  c = "nevertreated",
  b = "varying"
)

# Event study plot
ggdid(aggte(attgt_nldid_noml, "dynamic", min_e = -5, max_e = 14)) +
  scale_y_continuous(n.breaks = 10, limits = c(-0.45, 0.60)) +
  labs(
    title    = "Event Study: Nonlinear PT with NO-GRF",
    subtitle = paste0("Sample: ", chosen_sample, " | Outcome: ", chosen_outcome, " (levels)")
  )

# Group-specific ATT plot
ggdid(aggte(attgt_nldid_noml, "group", min_e = 0, max_e = 14)) +
  scale_x_continuous(n.breaks = 10, limits = c(-0.75, 0.75)) +
  labs(
    title    = "Group ATT: Nonlinear PT with NO-GRF",
    subtitle = paste0("Sample: ", chosen_sample, " | Outcome: ", chosen_outcome, " (levels)")
  )


################################################################################
#                                                                              #
#   END OF SCRIPT                                                              #
#                                                                              #
################################################################################