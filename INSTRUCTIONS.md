# AI-Generated Academic Paper: Completing "Semi-parametric Non-linear Difference-in-Differences for Policy Evaluation: New Evidence on the Entrepreneurial Impacts of State Business Tax Credits"

## Project Overview

You are tasked with completing an academic econometrics paper that:

1. **Replicates** Fazio, Guzman, and Stern (2020), published in *Economic Development Quarterly*, which used TWFE difference-in-differences to estimate the causal effects of state R&D tax credits on county-level entrepreneurial outcomes.

2. **Extends** the analysis using new semi-parametric difference-in-differences estimators developed in Sween (2026) for settings with count, discrete, or bounded outcomes where nonlinear parallel trend assumptions are more appropriate.

3. **Compares** standard approaches (log-plus-one transformations with linear parallel trends) to outcome-consistent nonlinear methods (log-mean parallel trends with debiased machine learning).

### Background

**The Original Paper (Fazio, Guzman, and Stern 2020):**
- Used TWFE diff-in-diff to study state R&D tax credits' effects on entrepreneurship
- Found significant positive effects on startup formation, insignificant effects on quality
- Applied log-plus-one transformations to count outcomes
- Suffers from two methodological issues:
  1. Log-plus-one transformations are invalid for causal inference (Chen and Roth 2024, QJE)
  2. TWFE is biased in staggered adoption settings (Goodman-Bacon 2021)

**The New Framework (Sween 2026):**
- Develops semi-parametric DiD estimators for discrete/bounded/count outcomes
- Imposes parallel trends on outcome-consistent link scales (e.g., log-mean for counts)
- Accommodates continuous treatment intensity
- Allows flexible ML-based covariate adjustment via Automatic Debiased Machine Learning
- Similar to Wooldridge (2023) but with ML nuisance estimation

### Your Task

1. **Replicate** the original Fazio et al. findings using their empirical strategy
2. **Apply** the Callaway-Sant'Anna (2021) estimator to address staggered adoption
3. **Implement** the nonlinear DiD estimators from Sween (2026)
4. **Compare** log-plus-one DML to nonlinear AutoDML approaches
5. **Investigate** extensions, heterogeneity, and robustness
6. **Complete** missing results, proofs, and text in the Sween (2026) draft
7. **Write** a professional, Econometrics Journal-quality article

---

## IMPORTANT: Stop-and-Check Points

Throughout this project, there are mandatory **STOP AND CHECK** points marked with 🛑. At each checkpoint:
1. Summarize what you have completed
2. Present key outputs for review
3. List any issues or concerns
4. **Wait for human approval before proceeding**

Do not proceed past a 🛑 checkpoint without explicit approval.

---

## PHASE 0: Project Setup and Materials Review

### Task 0.1: Project Directory Structure

The project uses the following structure:

```
Nonlinear-DiD-Fazio/
├── README.md
├── INSTRUCTIONS.md
├── Sween (2026).pdf              # Draft paper to complete
├── Fazio, Guzman, Stern (2020).pdf  # Original paper to replicate
├── original/
│   ├── raw/                      # Raw data files (.dta from original sources)
│   ├── modified/                 # Intermediate processed data (.csv)
│   ├── final/                    # Final analysis dataset
│   │   └── scp_pdit_county.csv
│   └── code/
│       ├── data_cleaning.do      # Stata data preparation
│       └── analysis.R            # R analysis code
├── code/                         # Your analysis code
├── data/
│   ├── raw/
│   ├── processed/
│   └── extension/
├── notes/                        # Documentation
├── output/
│   ├── tables/
│   ├── figures/
│   └── paper/
└── logs/
```

### Task 0.2: Review Original Materials

The repository contains:

**Data Files:**
- `original/raw/`: Raw data from PDIT and Startup Cartography Project
- `original/final/scp_pdit_county.csv`: Final merged county-year panel

**Code Files:**
- `original/code/data_cleaning.do`: Stata script for data preparation
- `original/code/analysis.R`: R script with DiD estimators

### Task 0.3: Understand the Data Structure

The main analysis dataset (`scp_pdit_county.csv`) contains:

**Identifiers:**
- `state_abr`, `state`, `county`: Geographic identifiers
- `statefips`, `countyfips`: FIPS codes
- `year`: Year (1990-2010)

**Treatment Variables:**
- `G_rnd`: R&D tax credit adoption cohort (0 = never treated)
- `rnd`: R&D tax credit rate
- `has_rnd`: Binary indicator for R&D credit
- `avg_rnd`: 10-year average R&D credit intensity
- `G_itc`, `itc`, `has_itc`, `avg_itc`: Investment tax credit variables
- `G_both`, `has_both`: Combined treatment indicators

**Outcome Variables:**
- `sfr`: Startup Formation Rate (count of new firms)
- `log_sfr`, `log1p_sfr`, `asinh_sfr`: Transformed versions
- `sfr_per1k`: Startups per 1,000 population
- `eqi`: Entrepreneurial Quality Index
- `growth`: High-growth firm indicator

**Covariates (X_ prefix):**
- `X_pop_1990`: Log population
- `X_total_emp`, `X_total_wage`: Employment and wage measures
- `X_sfr`, `X_eqi`, `X_growth`: Baseline outcome values
- Industry-specific employment shares
- Historical population measures

**Parsimonious Covariates (Z variables):**
- `Z1`: Log population (1990)
- `Z2`: Log employment-to-population ratio
- `Z3`: Log average wage
- `Z4`: Log baseline SFR
- `Z5`: Any startups indicator
- `Z6`: Baseline EQI (logit-transformed)
- `Z7`: Baseline growth indicator

**Sample Indicators:**
- `Sample_rnd`: Include in R&D credit analysis
- `Sample_itc`: Include in ITC analysis
- `Sample_both`: Include in combined analysis

### Task 0.4: Review the Analysis Code

The R analysis code (`analysis.R`) implements:

1. **Callaway-Sant'Anna wrapper** (`csdid`): Calls `did::att_gt()` with custom estimators

2. **Linear Parallel Trends Estimators:**
   - `my_nox_linear`: No covariates, simple means
   - `my_drreg_linear`: Doubly-robust GLM
   - `my_drml_linear`: Doubly-robust GRF (machine learning)

3. **Nonlinear Parallel Trends Estimators:**
   - `my_nox_nonlinear`: No covariates, ratio estimator
   - `my_noreg_nonlinear`: Neyman-orthogonal Poisson GLM
   - `my_noml_nonlinear`: Neyman-orthogonal GRF

Each estimator returns ATT estimates and influence functions compatible with the `did` package.

---

## 🛑 CHECKPOINT 0: Project Setup Complete

**Before proceeding, confirm:**
- [ ] Project directory structure understood
- [ ] Data files located and dimensions verified
- [ ] Variable definitions documented
- [ ] Analysis code reviewed and understood
- [ ] Estimator functions comprehended

**Present for review:**
1. Summary of data structure (N observations, N counties, N years)
2. List of treatment and outcome variables
3. Description of the six estimator functions
4. Any issues or questions about the materials

**STOP and wait for approval to proceed to Phase 1.**

---

## PHASE 1: Literature Review and Background

### Task 1.1: Summarize Fazio, Guzman, and Stern (2020)

Create `notes/original_paper_summary.md` containing:

**1. Research Question**
- What is the causal effect of state R&D tax credits on entrepreneurship?
- Policy relevance: Do tax incentives stimulate innovation and firm formation?

**2. Data Sources**
- Startup Cartography Project (SCP): County-level entrepreneurship measures
- Panel Database of Incentives and Taxes (PDIT): State tax credit policies
- Sample period: 1990-2010
- Unit of analysis: County-year

**3. Identification Strategy**
- Two-way fixed effects (TWFE) difference-in-differences
- Exploits staggered adoption of R&D tax credits across states
- County and state-year fixed effects
- Key assumption: Parallel trends in (transformed) outcomes

**4. Outcome Transformations**
- Log-plus-one transformation: log(1 + Y)
- Applied to count outcomes (startup counts)
- Motivation: Proportional interpretation, handle zeros

**5. Main Findings**
- Positive effects on startup quantity (formation counts)
- Weaker/insignificant effects on startup quality
- Effects persist over longer horizons

**6. Methodological Issues**
- Log-plus-one is invalid for causal effects (Chen and Roth 2024)
- TWFE biased with staggered adoption (Goodman-Bacon 2021)
- Limited covariate adjustment

### Task 1.2: Extensive Literature Review

Create a comprehensive literature review in `notes/literature_review.md`. This review should be publication-quality and form the basis for Section 2 of the paper. Organize into the following subsections:

---

#### 1.2.1: Difference-in-Differences Methodology (Core)

**Foundational DiD Papers:**
| Paper | Year | Journal | Key Contribution | Relevance to Our Paper |
|-------|------|---------|------------------|------------------------|
| Ashenfelter & Card | 1985 | REStat | Classic DiD application | Foundation of method |
| Bertrand, Duflo, Mullainathan | 2004 | QJE | Serial correlation in DiD | Clustering guidance |
| Angrist & Pischke | 2009 | Book | "Mostly Harmless" DiD chapter | Textbook treatment |

**Staggered Adoption and Heterogeneous Treatment Effects:**
| Paper | Year | Journal | Key Contribution | Relevance to Our Paper |
|-------|------|---------|------------------|------------------------|
| Goodman-Bacon | 2021 | JoE | TWFE decomposition theorem | Motivates moving beyond TWFE |
| Callaway & Sant'Anna | 2021 | JoE | Group-time ATT framework | Primary estimation framework |
| Sun & Abraham | 2021 | JoE | Interaction-weighted estimator | Alternative robust estimator |
| de Chaisemartin & D'Haultfœuille | 2020 | AER | Negative weights in TWFE | Documents TWFE problems |
| Borusyak, Jaravel, Spiess | 2024 | ReStud | Imputation estimator | Alternative approach |
| Athey & Imbens | 2022 | JoE | Design-based DiD | Theoretical foundations |
| Roth | 2022 | AER:I | Pre-testing issues | Caution on pre-trend tests |
| Rambachan & Roth | 2023 | ReStud | Sensitivity to parallel trends | Robustness framework |
| Freyaldenhoven et al. | 2019 | AER | Proxy controls for PT violations | Alternative identification |

**For each paper, document:**
- Exact citation (journal, volume, pages)
- Main theoretical result or methodological contribution
- How it informs our empirical strategy
- Any limitations or caveats noted by authors

---

#### 1.2.2: Nonlinear Difference-in-Differences

**Nonlinear Parallel Trends and Functional Form:**
| Paper | Year | Journal | Key Contribution | Relevance to Our Paper |
|-------|------|---------|------------------|------------------------|
| Wooldridge | 2023 | Econometrics J | Nonlinear DiD for counts, Poisson QMLE | Direct methodological predecessor |
| Wooldridge | 2021 | JBES | Two-way Mundlak regression | Correlated random effects approach |
| Athey & Imbens | 2006 | Econometrica | Changes-in-changes | Nonparametric DiD |
| Bonhomme & Sauder | 2011 | ReStud | Distributional DiD | Quantile approaches |
| Melly & Santangelo | 2015 | JBES | Quantile DiD | Distribution-free methods |

**The Log Transformation Problem:**
| Paper | Year | Journal | Key Contribution | Relevance to Our Paper |
|-------|------|---------|------------------|------------------------|
| Chen & Roth | 2024 | QJE | Log-like transformations don't identify causal effects | **Central motivation** |
| Mullahy & Norton | 2022 | JBES | Interpreting log-transformed outcomes | Interpretation issues |
| Bellemare & Wichman | 2020 | AJAE | IHS transformation critique | Alternative transformation problems |
| Santos Silva & Tenreyro | 2006 | REStat | PPML for gravity | Poisson alternative to logs |
| Santos Silva & Tenreyro | 2011 | EL | Log of gravity critique | Why logs fail with zeros |

**Count Data and Zero-Inflation:**
| Paper | Year | Journal | Key Contribution | Relevance to Our Paper |
|-------|------|---------|------------------|------------------------|
| Cameron & Trivedi | 2013 | Book | Count data econometrics | Reference for Poisson |
| Mullainathan & Spiess | 2017 | JEP | ML for prediction vs. inference | When ML helps |
| Wooldridge | 2010 | Book | Count panel data models | Panel Poisson methods |

---

#### 1.2.3: Machine Learning for Causal Inference

**Double/Debiased Machine Learning:**
| Paper | Year | Journal | Key Contribution | Relevance to Our Paper |
|-------|------|---------|------------------|------------------------|
| Chernozhukov et al. | 2018 | Econometrics J | DML framework | **Core estimation method** |
| Chernozhukov et al. | 2021 | arXiv | Automatic DML via Riesz regression | **Riesz representer approach** |
| Chernozhukov et al. | 2022 | Econometrica | Local robustness, sensitivity | Robustness theory |
| Newey & Robins | 2018 | arXiv | Cross-fitting theory | Theoretical foundation |

**Generalized Random Forests:**
| Paper | Year | Journal | Key Contribution | Relevance to Our Paper |
|-------|------|---------|------------------|------------------------|
| Athey, Tibshirani, Wager | 2019 | AoS | Generalized random forests | **First-stage learner** |
| Wager & Athey | 2018 | JASA | Causal forests | Treatment effect heterogeneity |
| Athey & Wager | 2021 | JASA | Policy learning | Optimal policy |

**Other ML Methods for Causal Inference:**
| Paper | Year | Journal | Key Contribution | Relevance to Our Paper |
|-------|------|---------|------------------|------------------------|
| Belloni, Chernozhukov, Hansen | 2014 | ReStud | LASSO for IV | High-dimensional selection |
| Farrell | 2015 | JoE | Series estimation with ML | Semiparametric efficiency |
| Kennedy | 2022 | WIREs | Review of causal ML | Survey of methods |

---

#### 1.2.4: R&D Tax Credits and Innovation Policy

**State R&D Tax Credit Studies:**
| Paper | Year | Journal | Key Finding | Data/Method |
|-------|------|---------|-------------|-------------|
| Fazio, Guzman, Stern | 2020 | EDQ | + formation, null quality | SCP, TWFE |
| Wilson | 2009 | REStat | R&D credits increase R&D spending | State panel, TWFE |
| Bloom, Griffith, Van Reenen | 2002 | ReStud | Tax price elasticity of R&D | Cross-country |
| Rao | 2016 | JPubE | R&D credits, firm innovation | Firm-level, RDD |
| Dechezleprêtre et al. | 2016 | WP | R&D credits, patents | UK policy change |
| Howell | 2017 | AER | R&D grants vs. credits | SBIR program |

**Entrepreneurship and Regional Development:**
| Paper | Year | Journal | Key Finding | Relevance |
|-------|------|---------|-------------|-----------|
| Guzman & Stern | 2020 | AEJ:EP | Startup quality measurement | EQI methodology |
| Guzman | 2019 | Management Science | Regional entrepreneurship | Geography matters |
| Haltiwanger, Jarmin, Miranda | 2013 | REStat | Young firms create jobs | Startups matter |
| Glaeser & Kerr | 2009 | JUE | Local industrial structures | Agglomeration |
| Lerner | 2009 | Book | Government venture capital | Policy evaluation |

**Tax Policy and Firm Behavior:**
| Paper | Year | Journal | Key Finding | Relevance |
|-------|------|---------|-------------|-----------|
| Zwick & Mahon | 2017 | AER | Investment tax credits | Similar policy |
| Ohrn | 2018 | AER | Bonus depreciation | Corporate response |
| Curtis & Decker | 2018 | JMCB | State corporate taxes | Tax competition |
| Giroud & Rauh | 2019 | JPE | State taxes, establishment | Firm location |

---

#### 1.2.5: Applied Econometrics Best Practices

**Specification and Robustness:**
| Paper | Year | Journal | Key Contribution | How We Apply It |
|-------|------|---------|------------------|-----------------|
| Leamer | 1983 | AER | Specification searches | Report all specifications |
| Sala-i-Martin | 1997 | AER | "I just ran 2 million regressions" | Systematic comparison |
| Young | 2022 | QJE | Consistency of estimates | Stability across specs |
| Brodeur et al. | 2020 | AER | P-hacking tests | Pre-registration spirit |
| Andrews, Kasy | 2019 | AER | Publication bias | Report null results |

**Transparency and Replication:**
| Paper | Year | Journal | Key Contribution | How We Apply It |
|-------|------|---------|------------------|-----------------|
| Christensen & Miguel | 2018 | AEJ:Policy | Transparency in social science | Code availability |
| Huntington-Klein et al. | 2021 | JBES | Robustness reproducibility | Estimator comparison |

---

#### 1.2.6: Literature Review Deliverables

Create the following outputs:

1. **`notes/literature_review.md`**: Comprehensive annotated bibliography with all papers above, plus any additional relevant papers discovered during research.

2. **`notes/lit_review_narrative.md`**: A 3,000-4,000 word narrative literature review suitable for inclusion in Section 2 of the paper, organized thematically:
   - The DiD revolution and its discontents
   - The functional form problem in applied work
   - Machine learning meets causal inference
   - What we know about R&D credits and entrepreneurship
   - Gaps this paper fills

3. **`output/tables/literature_summary.tex`**: A formatted LaTeX table summarizing the key methodological papers and their contributions.

4. **Citation verification**: For every paper cited, confirm:
   - Exact title
   - All authors
   - Journal/outlet
   - Year
   - Volume and pages (if published)
   - DOI or stable URL

### Task 1.3: Document the Methodological Contribution

Create `notes/methodology_contribution.md` explaining:

**1. The Problem with Standard Approaches**
- Log-plus-one does not identify well-defined causal effects
- Linear parallel trends incompatible with count outcome support
- TWFE aggregates heterogeneous effects incorrectly

**2. The Nonlinear Parallel Trends Solution**
- Impose parallel trends on log-mean scale: E[Y(0)|D=1]/E[Y(0)|D=0] constant
- Counterfactual: Δ(X) = μ₁₀(X) × μ₀₁(X) / μ₀₀(X)
- Weighted proportional ATT: E[Y₁/Δ(X) - 1 | D=1]

**3. The Debiased ML Innovation**
- Flexible nuisance function estimation with ML
- Neyman-orthogonal scores for root-n inference
- Cross-fitting for regularization bias correction

**4. Comparison to Wooldridge (2023)**
- Wooldridge: Parametric (Poisson QMLE)
- Sween: Semi-parametric (any ML learner)
- Both target same weighted proportional estimand

---

## 🛑 CHECKPOINT 1: Literature Review Complete

**Before proceeding, confirm:**
- [ ] Original paper thoroughly summarized
- [ ] Methodological literature documented
- [ ] Contribution clearly articulated
- [ ] All citations verified

**Present for review:**
1. Summary of Fazio et al. (2020) findings and methods
2. Literature review table
3. Explanation of methodological contribution

**STOP and wait for approval to proceed to Phase 2.**

---

## PHASE 2: Replication of Original Results

### Task 2.1: Load and Examine Data

```r
# Load the analysis dataset
df <- fread("original/final/scp_pdit_county.csv")

# Document:
# - Dimensions: nrow(df), ncol(df)
# - Counties: length(unique(df$countyfips))
# - Years: range(df$year)
# - Treatment variation: table(df$G_rnd)
```

Create `notes/data_examination.md` with:
- Sample size and panel structure
- Treatment adoption by cohort
- Outcome distributions (mean, SD, zeros)
- Covariate summary statistics

### Task 2.2: Replicate TWFE Estimates

Estimate the original TWFE specification:

```r
# Log-plus-one outcome, TWFE
# Y_ct = β(RnD_st) + γ_c + δ_st + ε_ct

library(fixest)

# Basic TWFE
twfe_basic <- feols(
  log1p_sfr ~ has_rnd | countyfips + statefips^year,
  data = df,
  cluster = "countyfips"
)

# With continuous treatment intensity
twfe_intensity <- feols(
  log1p_sfr ~ rnd | countyfips + statefips^year,
  data = df,
  cluster = "countyfips"
)
```

### Task 2.3: Implement Callaway-Sant'Anna

```r
# Using the csdid wrapper from analysis.R
attgt_cs <- csdid(
  d = df |>
    mutate(Outcome = log1p(sfr)) |>
    filter(Sample_rnd == 1),
  f = ~ 1,  # No covariates initially
  e = "dr",  # Built-in doubly-robust
  c = "nevertreated",
  b = "varying"
)

# Aggregate to event study
es_cs <- aggte(attgt_cs, "dynamic", min_e = -5, max_e = 14)
ggdid(es_cs)

# Aggregate to overall ATT
att_cs <- aggte(attgt_cs, "simple")
```

### Task 2.4: Compare to Original Paper

Create comparison table:

| Specification | Original Paper | Replication | Difference |
|--------------|----------------|-------------|------------|
| TWFE, log(1+Y) | +X.XX (S.E.) | ??? | ??? |
| TWFE + covariates | +X.XX (S.E.) | ??? | ??? |
| CS-DiD, log(1+Y) | N/A | ??? | N/A |

Document any discrepancies in `notes/replication_comparison.md`.

---

## 🛑 CHECKPOINT 2: Replication Complete

**Before proceeding, confirm:**
- [ ] TWFE estimates computed
- [ ] Callaway-Sant'Anna estimates computed
- [ ] Results compared to original paper
- [ ] Discrepancies documented and explained

**Present for review:**
1. TWFE coefficient estimates with standard errors
2. CS-DiD event study plot
3. Comparison table
4. Any replication issues

**STOP and wait for approval to proceed to Phase 3.**

---

## PHASE 3: Comprehensive Estimator Comparison

This is the core analytical contribution. You will systematically compare estimates across **four dimensions**:
1. First-stage estimators (nuisance function learners)
2. Outcome transformations
3. Identification assumptions (linear vs. nonlinear parallel trends)
4. Covariate specifications

The goal is a rigorous, transparent, and exhaustive comparison that leaves no stone unturned.

---

### Task 3.1: Define the Comparison Framework

Create a systematic grid of specifications. Each cell represents a unique estimator configuration.

#### Dimension 1: First-Stage Estimators

| Estimator Code | Description | R Implementation | Strengths | Weaknesses |
|----------------|-------------|------------------|-----------|------------|
| `MEAN` | Simple group means | Manual calculation | Transparent, no tuning | No covariate adjustment |
| `OLS` | Linear regression | `lm()` or `fastglm(..., family=gaussian())` | Fast, interpretable | Linear functional form |
| `LOGIT` | Logistic regression (pscore) | `fastglm(..., family=binomial())` | Standard for pscore | Linear in X |
| `POISSON` | Poisson regression | `fastglm(..., family=poisson())` | Respects non-negativity | Parametric |
| `LASSO` | L1-penalized regression | `glmnet::cv.glmnet()` | Variable selection | Regularization bias |
| `RIDGE` | L2-penalized regression | `glmnet::cv.glmnet(alpha=0)` | Stable with collinearity | No variable selection |
| `ENET` | Elastic net | `glmnet::cv.glmnet(alpha=0.5)` | Compromise | Tuning complexity |
| `RF` | Random forest (non-honest) | `ranger::ranger()` | Flexible, fast | Overfitting risk |
| `GRF` | Generalized random forest (honest) | `grf::regression_forest()` | Valid inference, flexible | Slower, tuning |
| `BART` | Bayesian additive regression trees | `dbarts::bart()` | Uncertainty quantification | Computational cost |
| `XGB` | Gradient boosted trees | `xgboost::xgboost()` | State-of-art prediction | Black box, tuning |

For each first-stage estimator, document:
- Hyperparameter choices and tuning procedure
- Cross-fitting implementation (K=5 folds standard)
- Computational time
- Out-of-sample prediction performance (RMSE)

#### Dimension 2: Outcome Transformations

| Transform Code | Formula | Support | Interpretation | Issues |
|----------------|---------|---------|----------------|--------|
| `LEVEL` | Y | [0, ∞) | Level effect | Scale-dependent |
| `LOG` | log(Y) | (0, ∞) | % effect | Undefined at 0 |
| `LOG1P` | log(1 + Y) | [0, ∞) | Approximate % | Chen & Roth critique |
| `ASINH` | asinh(Y) | ℝ | Approximate % for large Y | Not % for small Y |
| `SQRT` | √Y | [0, ∞) | Variance stabilizing | No clear interpretation |
| `RATE` | Y/Pop | [0, ∞) | Per capita | Ratio interpretation |
| `PCTL` | Percentile rank | [0, 1] | Distributional | Loses magnitude |

For the nonlinear PT estimators, the outcome is always in levels, but the *link function* determines the parallel trends scale.

#### Dimension 3: Identification Assumptions

| ID Code | Parallel Trends Assumption | Link Function | Counterfactual Formula |
|---------|---------------------------|---------------|------------------------|
| `LINEAR` | Additive: E[Y(0)]₁ - E[Y(0)]₀ equal across groups | Identity | Δ = μ¹₀ + μ⁰₁ - μ⁰₀ |
| `LOGMEAN` | Multiplicative: E[Y(0)]₁ / E[Y(0)]₀ equal | Log | Δ = μ¹₀ × μ⁰₁ / μ⁰₀ |
| `LOGIT` | Log-odds: logit(E[Y(0)]) parallel | Logit | Δ = expit(logit(μ¹₀) + logit(μ⁰₁) - logit(μ⁰₀)) |
| `POISSON` | Log-rate: log(E[Y(0)]) parallel | Log (Poisson QMLE) | Same as LOGMEAN |

#### Dimension 4: Covariate Specifications

| Cov Code | Variables | Dimension | Rationale |
|----------|-----------|-----------|-----------|
| `NONE` | Intercept only | p = 1 | Unconditional PT |
| `PARSIM` | Z1-Z7 | p = 7 | Key confounders |
| `ECON` | Population, employment, wages | p ≈ 15 | Economic conditions |
| `FULL_X` | All X_ variables | p ≈ 100 | Kitchen sink |
| `LASSO_SEL` | LASSO-selected from FULL_X | p varies | Data-driven |

---

### Task 3.2: Master Comparison Table Structure

Create the master comparison table with the following structure:

```
output/tables/master_comparison.csv

Columns:
- spec_id: Unique specification identifier
- outcome_var: sfr, eqi, growth, sfr_per1k
- outcome_transform: LEVEL, LOG1P, ASINH, etc.
- id_assumption: LINEAR, LOGMEAN
- first_stage: MEAN, OLS, GRF, etc.
- covariates: NONE, PARSIM, FULL_X, etc.
- control_group: nevertreated, notyettreated
- base_period: varying, universal
- n_obs: Number of observations
- n_clusters: Number of counties
- n_treated: Number of treated county-years
- att_estimate: Point estimate
- att_se: Standard error (clustered)
- att_ci_lower: 95% CI lower bound
- att_ci_upper: 95% CI upper bound
- att_pvalue: p-value
- pre_trend_pvalue: p-value for pre-trend test
- computation_time_sec: Runtime in seconds
- notes: Any warnings or issues
```

---

### Task 3.3: Implement Core Estimator Combinations

#### 3.3.1: Linear Parallel Trends Family

**Specification L1: TWFE Benchmark (Problematic but Standard)**
```r
# Classic TWFE with log(1+Y) - the "bad" approach we're critiquing
twfe_log1p <- feols(
  log1p_sfr ~ has_rnd | countyfips + statefips^year,
  data = df |> filter(Sample_rnd == 1),
  cluster = "countyfips"
)
```

**Specification L2: Callaway-Sant'Anna with log(1+Y)**
```r
# CS-DiD with built-in DR estimator
cs_log1p_dr <- csdid(
  d = df |> mutate(Outcome = log1p(sfr)) |> filter(Sample_rnd == 1),
  f = ~ 1,
  e = "dr",
  c = "nevertreated",
  b = "varying"
)
```

**Specification L3: Linear PT with OLS nuisance**
```r
cs_log1p_ols <- csdid(
  d = df |> mutate(Outcome = log1p(sfr)) |> filter(Sample_rnd == 1),
  f = zform,
  e = my_drreg_linear,  # Uses fastglm with gaussian
  c = "nevertreated",
  b = "varying"
)
```

**Specification L4: Linear PT with GRF nuisance (ML)**
```r
cs_log1p_grf <- csdid(
  d = df |> mutate(Outcome = log1p(sfr)) |> filter(Sample_rnd == 1),
  f = zform,
  e = my_drml_linear,  # Uses GRF
  c = "nevertreated",
  b = "varying"
)
```

**Specification L5: Linear PT with LASSO nuisance**
```r
# Implement new estimator
my_drlasso_linear <- function(y1, y0, D, covariates, ...) {
  # [Implementation using glmnet for outcome and pscore]
}
```

#### 3.3.2: Nonlinear Parallel Trends Family

**Specification N1: Wooldridge (2023) Poisson QMLE**
```r
# Implement Wooldridge's approach for comparison
wooldridge_poisson <- function(data) {
  # Poisson regression with cohort-time interactions
  # See Wooldridge (2023) Section 4
}
```

**Specification N2: Nonlinear PT, No Covariates**
```r
cs_level_nox <- csdid(
  d = df |> mutate(Outcome = sfr) |> filter(Sample_rnd == 1),
  f = ~ 1,
  e = my_nox_nonlinear,
  c = "nevertreated",
  b = "varying"
)
```

**Specification N3: Nonlinear PT, Poisson GLM Nuisance**
```r
cs_level_poisson <- csdid(
  d = df |> mutate(Outcome = sfr) |> filter(Sample_rnd == 1),
  f = zform,
  e = my_noreg_nonlinear,
  c = "nevertreated",
  b = "varying"
)
```

**Specification N4: Nonlinear PT, GRF Nuisance (Main Specification)**
```r
cs_level_grf <- csdid(
  d = df |> mutate(Outcome = sfr) |> filter(Sample_rnd == 1),
  f = zform,
  e = my_noml_nonlinear,
  c = "nevertreated",
  b = "varying"
)
```

**Specification N5: Nonlinear PT, GRF with Full Covariates**
```r
cs_level_grf_full <- csdid(
  d = df |> mutate(Outcome = sfr) |> filter(Sample_rnd == 1),
  f = xform,  # Full covariate set
  e = my_noml_nonlinear,
  c = "nevertreated",
  b = "varying"
)
```

---

### Task 3.4: First-Stage Learner Comparison

Create a dedicated analysis comparing first-stage estimators holding everything else fixed.

#### 3.4.1: Prediction Performance

For each first-stage learner, compute out-of-sample prediction metrics:

```r
# Cross-validated RMSE for each nuisance function
evaluate_learner <- function(learner, X, Y, D, K = 5) {
  folds <- sample(1:K, nrow(X), replace = TRUE)
  
  results <- map_dfr(1:K, function(k) {
    train <- folds != k
    test <- folds == k
    
    # Fit on training, predict on test
    if (learner == "GRF") {
      model <- regression_forest(X[train,], Y[train], ...)
      pred <- predict(model, X[test,])$predictions
    } else if (learner == "LASSO") {
      # ... etc
    }
    
    tibble(
      fold = k,
      rmse = sqrt(mean((Y[test] - pred)^2)),
      mae = mean(abs(Y[test] - pred)),
      r2 = cor(Y[test], pred)^2
    )
  })
  
  return(results)
}
```

Create table: `output/tables/first_stage_prediction.csv`

| Learner | Nuisance Function | RMSE | MAE | R² | CV Folds |
|---------|-------------------|------|-----|----| ---------|
| OLS | μ⁰₀(X) | | | | 5 |
| GRF | μ⁰₀(X) | | | | 5 |
| LASSO | μ⁰₀(X) | | | | 5 |
| ... | ... | | | | |

#### 3.4.2: ATT Sensitivity to First-Stage

Create figure showing how ATT varies across first-stage learners:

```r
# Forest plot of ATT estimates by first-stage learner
learner_comparison <- tribble(
  ~learner, ~att, ~se, ~ci_lower, ~ci_upper,
  "Simple Means", ..., ..., ..., ...,
  "OLS", ..., ..., ..., ...,
  "LASSO", ..., ..., ..., ...,
  "Ridge", ..., ..., ..., ...,
  "Random Forest", ..., ..., ..., ...,
  "GRF (Honest)", ..., ..., ..., ...,
  "XGBoost", ..., ..., ..., ...
)

ggplot(learner_comparison, aes(x = att, y = reorder(learner, att))) +
  geom_point() +
  geom_errorbarh(aes(xmin = ci_lower, xmax = ci_upper), height = 0.2) +
  geom_vline(xintercept = 0, linetype = "dashed") +
  labs(x = "ATT Estimate", y = "First-Stage Learner",
       title = "Sensitivity of ATT to First-Stage Learner Choice")
```

Save as: `output/figures/first_stage_sensitivity.pdf`

#### 3.4.3: GRF Hyperparameter Sensitivity

Vary GRF tuning parameters:

```r
grf_sensitivity <- expand_grid(
  num_trees = c(100, 200, 500, 1000, 2000),
  honesty = c(TRUE, FALSE),
  min_node_size = c(5, 10, 20)
) |>
  mutate(
    att = map2_dbl(num_trees, honesty, ~{
      # Re-estimate with these parameters
    })
  )
```

Create heatmap: `output/figures/grf_tuning_sensitivity.pdf`

---

### Task 3.5: Outcome Transformation Comparison

#### 3.5.1: Same Identification, Different Transforms

Holding identification assumption fixed (linear PT), compare across transformations:

| Transformation | ATT | SE | Interpretation | Chen-Roth Valid? |
|----------------|-----|----|--------------------|------------------|
| log(1 + Y) | +0.09 | | ~9% increase | ❌ No |
| asinh(Y) | | | Approx % | ❌ No |
| √Y | | | Variance stabilized | ❌ No |
| Y (levels) | | | Startup count | ✅ Yes |
| Y/Pop×1000 | | | Per 1K pop | ✅ Yes |

#### 3.5.2: Visualization

```r
# Coefficient plot across transformations
transform_comparison <- tribble(
  ~transform, ~att, ~se, ~valid,
  "log(1+Y)", 0.09, 0.02, FALSE,
  "asinh(Y)", ..., ..., FALSE,
  "Levels", ..., ..., TRUE,
  "Per capita", ..., ..., TRUE
)

ggplot(transform_comparison, aes(x = att, y = transform, color = valid)) +
  geom_point(size = 3) +
  geom_errorbarh(aes(xmin = att - 1.96*se, xmax = att + 1.96*se), height = 0.2) +
  scale_color_manual(values = c("TRUE" = "darkgreen", "FALSE" = "red"),
                     labels = c("TRUE" = "Valid", "FALSE" = "Invalid")) +
  labs(title = "ATT Estimates Across Outcome Transformations",
       subtitle = "Validity per Chen & Roth (2024)")
```

---

### Task 3.6: Identification Assumption Comparison

This is the **key comparison** in the paper.

#### 3.6.1: Linear vs. Nonlinear PT Side-by-Side

| Specification | PT Assumption | Outcome | ATT | SE | 95% CI | Interpretation |
|---------------|---------------|---------|-----|----|----|----------------|
| Standard | Linear | log(1+Y) | +0.09 | | | +9% startups |
| Proposed | Log-mean | Y (levels) | -0.10 | | | -10% startups |

**Key narrative**: The sign flips from positive to negative when using outcome-consistent identification.

#### 3.6.2: Event Study Comparison

Create a 2×2 panel figure:

```r
# Panel A: Linear PT, log(1+Y)
# Panel B: Linear PT, levels
# Panel C: Nonlinear PT, no covariates  
# Panel D: Nonlinear PT, with covariates (main spec)

p1 <- ggdid(aggte(cs_log1p_dr, "dynamic")) + 
  labs(title = "A: Linear PT, log(1+Y)")

p2 <- ggdid(aggte(cs_level_linear, "dynamic")) + 
  labs(title = "B: Linear PT, Levels")

p3 <- ggdid(aggte(cs_level_nox, "dynamic")) + 
  labs(title = "C: Nonlinear PT, No Covariates")

p4 <- ggdid(aggte(cs_level_grf, "dynamic")) + 
  labs(title = "D: Nonlinear PT, GRF Covariates")

(p1 | p2) / (p3 | p4)
```

Save as: `output/figures/event_study_comparison_4panel.pdf`

#### 3.6.3: Formal Test of Identification Assumptions

While we cannot directly test parallel trends, we can:

1. **Pre-trend test**: Are pre-treatment coefficients jointly zero?
2. **Placebo outcome test**: Apply estimators to outcomes that shouldn't be affected
3. **Sensitivity analysis**: How large would PT violations need to be to overturn results?

```r
# Rambachan & Roth sensitivity analysis
library(HonestDiD)
sensitivity <- HonestDiD::createSensitivityResults(
  betahat = ...,  # Event study coefficients
  sigma = ...,    # Variance-covariance matrix
  numPrePeriods = 5,
  numPostPeriods = 14
)
```

---

### Task 3.7: Covariate Specification Comparison

#### 3.7.1: Covariate Balance

First, check covariate balance between treated and control:

```r
# Balance table
balance_table <- df |>
  filter(Sample_rnd == 1, year == 1990) |>
  group_by(has_rnd) |>
  summarise(across(starts_with("X_"), list(mean = mean, sd = sd))) |>
  pivot_longer(-has_rnd) |>
  # Compute standardized differences
```

Save as: `output/tables/covariate_balance.csv`

#### 3.7.2: ATT Across Covariate Specifications

| Covariates | N Covariates | ATT (Linear PT) | ATT (Nonlinear PT) | Change in ATT |
|------------|--------------|-----------------|--------------------| --------------|
| None | 0 | | | |
| Parsimonious (Z) | 7 | | | |
| Economic | ~15 | | | |
| Full (X) | ~100 | | | |
| LASSO-selected | varies | | | |

#### 3.7.3: Covariate Importance

For GRF-based estimators, extract variable importance:

```r
# Variable importance from GRF
importance <- variable_importance(grf_model)
importance_df <- tibble(
  variable = colnames(X),
  importance = importance
) |>
  arrange(desc(importance))
```

Create: `output/figures/variable_importance.pdf`

---

### Task 3.8: Create Summary Comparison Outputs

#### 3.8.1: The "Specification Curve"

Following Simonsohn, Simmons, and Nelson (2020), create a specification curve showing all estimates:

```r
# Specification curve analysis
all_specs <- master_comparison |>
  arrange(att_estimate) |>
  mutate(spec_rank = row_number())

# Panel A: Sorted estimates with CIs
p_curve <- ggplot(all_specs, aes(x = spec_rank, y = att_estimate)) +
  geom_point() +
  geom_errorbar(aes(ymin = att_ci_lower, ymax = att_ci_upper), alpha = 0.3) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "red") +
  labs(y = "ATT Estimate", x = "Specification (sorted)")

# Panel B: Specification indicators
p_indicators <- all_specs |>
  select(spec_rank, id_assumption, first_stage, covariates, outcome_transform) |>
  pivot_longer(-spec_rank) |>
  ggplot(aes(x = spec_rank, y = name, fill = value)) +
  geom_tile() +
  scale_fill_viridis_d()

p_curve / p_indicators
```

Save as: `output/figures/specification_curve.pdf`

#### 3.8.2: Summary Statistics of Estimates

```r
# Summarize distribution of estimates
estimate_summary <- master_comparison |>
  group_by(id_assumption) |>
  summarise(
    n_specs = n(),
    mean_att = mean(att_estimate),
    median_att = median(att_estimate),
    sd_att = sd(att_estimate),
    min_att = min(att_estimate),
    max_att = max(att_estimate),
    pct_positive = mean(att_estimate > 0),
    pct_significant = mean(att_pvalue < 0.05)
  )
```

---

### Task 3.9: Headline Results Table

Create the main results table for the paper:

```
output/tables/main_results.tex

                        (1)         (2)         (3)         (4)         (5)
                      TWFE      CS-DiD      CS-DiD     Nonlinear   Nonlinear
                    log(1+Y)   log(1+Y)   log(1+Y)     Levels      Levels
                    --------   --------   --------    --------    --------
Parallel Trends:    Linear     Linear     Linear      Log-mean    Log-mean
First Stage:        OLS        DR         GRF         None        GRF
Covariates:         None       None       Z1-Z7       None        Z1-Z7
------------------------------------------------------------------------
ATT                 0.090**    0.085**    0.082**    -0.095***   -0.102***
                   (0.025)    (0.028)    (0.030)     (0.022)     (0.024)

95% CI             [0.04,      [0.03,     [0.02,     [-0.14,     [-0.15,
                    0.14]       0.14]      0.14]      -0.05]      -0.06]

Pre-trend p-value   0.342      0.285      0.301       0.412       0.389

Observations        X,XXX      X,XXX      X,XXX       X,XXX       X,XXX
Counties            X,XXX      X,XXX      X,XXX       X,XXX       X,XXX
Treated county-yrs  X,XXX      X,XXX      X,XXX       X,XXX       X,XXX
------------------------------------------------------------------------
Chen-Roth Valid?    No         No         No          Yes         Yes
------------------------------------------------------------------------
```

---

## 🛑 CHECKPOINT 3: Comprehensive Comparison Complete

**Before proceeding, confirm:**
- [ ] All estimator combinations implemented
- [ ] First-stage learner comparison complete
- [ ] Outcome transformation comparison complete
- [ ] Identification assumption comparison complete
- [ ] Covariate specification comparison complete
- [ ] Master comparison table populated
- [ ] Specification curve created
- [ ] Main results table created

**Present for review:**
1. Master comparison table (CSV)
2. Specification curve figure
3. 4-panel event study figure
4. First-stage learner sensitivity figure
5. Main results table (LaTeX)
6. Key finding summary: How do estimates differ across dimensions?

**STOP and wait for approval to proceed to Phase 4.**

---

## PHASE 4: Robustness and Extensions

### Task 4.1: Alternative Outcomes

Repeat analysis for:
- `eqi`: Entrepreneurial Quality Index
- `growth`: High-growth indicator
- `sfr_per1k`: Startups per capita

### Task 4.2: Alternative Treatment Definitions

- Binary treatment: `has_rnd`
- Continuous intensity: `rnd` (credit rate)
- 10-year average: `avg_rnd`

### Task 4.3: Sensitivity to ML Tuning

Vary GRF parameters:
- `num.trees`: 200, 500, 1000, 2000
- Honesty: TRUE vs FALSE

### Task 4.4: Alternative Control Groups

- Never-treated only: `c = "nevertreated"`
- Not-yet-treated: `c = "notyettreated"`

### Task 4.5: Covariate Specifications

- No covariates: `f = ~ 1`
- Parsimonious: `f = zform` (Z1-Z7)
- Full: `f = xform` (all X_ variables)

### Task 4.6: Placebo and Pre-trend Tests

- Test for pre-treatment trends
- Placebo outcomes (if available)

---

## 🛑 CHECKPOINT 4: Robustness Complete

**Before proceeding, confirm:**
- [ ] Alternative outcomes analyzed
- [ ] Treatment definitions compared
- [ ] ML sensitivity assessed
- [ ] Pre-trend tests conducted

**Present for review:**
1. Robustness summary table
2. Sensitivity to ML tuning
3. Pre-trend test results
4. Any concerning patterns

**STOP and wait for approval to proceed to Phase 5.**

---

## PHASE 5: Paper Writing and Completion

This phase transforms the analysis into a publication-quality applied econometrics paper. The Sween (2026) draft provides the theoretical framework; your task is to complete the empirical exposition, fill in missing sections, and ensure the paper meets the standards of the *Econometrics Journal* or similar outlets.

---

### Task 5.1: Paper Structure and Standards

#### 5.1.1: Target Journal Standards

The paper should meet the standards of:
- **Primary target**: *The Econometrics Journal* (where Wooldridge 2023 appeared)
- **Alternative targets**: *Journal of Econometrics*, *Journal of Business & Economic Statistics*, *Review of Economics and Statistics*

These journals expect:
- Clear methodological contribution with practical applicability
- Rigorous theoretical foundations (identification, estimation, inference)
- Substantive empirical application demonstrating value-added
- Comprehensive robustness analysis
- Transparent presentation of limitations
- Reproducible code and data

#### 5.1.2: Paper Length and Structure

Target length: 40-50 pages (double-spaced) including tables/figures, or approximately:
- Main text: 10,000-12,000 words
- Tables: 8-12 tables
- Figures: 6-10 figures
- Online appendix: Additional robustness, proofs, details

#### 5.1.3: Final Paper Structure

```
1. Introduction (2,500-3,000 words)
2. Related Literature and Empirical Context (2,500-3,000 words)
   2.1 Methodological Literature
   2.2 The Startup Cartography Project
   2.3 State R&D Tax Credits and Prior Evidence
3. Setup (1,500 words)
   3.1 Target Parameters
4. Identification under Nonlinear Parallel Trends (2,000 words)
5. Semiparametric Estimation and Inference (2,500 words)
   5.1 Binary Treatments
   5.2 Continuous Treatments
   5.3 Multiple Periods and Staggered Adoption
   5.4 Repeated Cross Sections
6. Extensions (1,500 words)
   6.1 Benchmarking Intensive-Margin Effects
   6.2 Generalized Structural Parallel Trend Assumptions
7. Empirical Application (3,500-4,000 words)
   7.1 Data and Empirical Strategy
   7.2 Replication and Benchmarking Results
   7.3 Nonlinear Parallel Trends Results
   7.4 Robustness and Sensitivity
   7.5 Discussion of Economic Magnitude
8. Conclusion (800-1,000 words)
References
Appendix A: Proofs
Appendix B: Additional Results
Appendix C: Data Construction Details
```

---

### Task 5.2: Write the Introduction (Section 1)

The introduction must accomplish six things in approximately 2,500-3,000 words:

#### 5.2.1: Opening Hook (1-2 paragraphs)

Start with the methodological problem, not the application:

> "Difference-in-differences designs are central to empirical economics, yet standard implementations embed implicit assumptions about functional form that are often inconsistent with the outcomes being studied. When outcomes are counts, bounded proportions, or frequently zero, the parallel trends assumption—imposed on levels, logs, or ad hoc transformations—may generate counterfactual paths that violate the outcome's support or lack clear causal interpretation."

Then pivot to why this matters:

> "These concerns are not merely theoretical. A growing body of work demonstrates that commonly used transformations, such as log(1+Y), do not identify well-defined causal effects (Chen and Roth 2024), while two-way fixed effects estimators aggregate heterogeneous treatment effects in potentially misleading ways (Goodman-Bacon 2021). Applied researchers face a gap between methodological best practices and feasible implementation."

#### 5.2.2: Research Question and Contribution (2-3 paragraphs)

State clearly what the paper does:

> "This paper develops semi-parametric difference-in-differences estimators for discrete and weakly positive outcomes under nonlinear parallel trends assumptions. The framework imposes identification on outcome-consistent link scales—such as the log-mean for counts—while accommodating flexible, high-dimensional covariate adjustment using modern machine learning methods. The estimators target well-defined causal effects, respect support restrictions, and deliver valid inference under standard regularity conditions."

Articulate the three contributions:
1. **Methodological**: Extends nonlinear DiD (Wooldridge 2023) to ML nuisance estimation
2. **Applied**: Re-examines R&D tax credits and entrepreneurship
3. **Practical**: Demonstrates how functional form choices matter for policy conclusions

#### 5.2.3: Preview of Findings (1-2 paragraphs)

Be direct about what you find:

> "Applied to state research and development tax credits, the proposed estimators reveal substantial sensitivity to functional form assumptions. Standard approaches—two-way fixed effects with log-transformed outcomes—suggest that R&D credits increase startup formation by approximately 9%. In contrast, outcome-consistent nonlinear estimates indicate that R&D credits *reduce* startup formation by approximately 10%. This sign reversal is robust to alternative covariate specifications, machine learning algorithms, and sample restrictions."

#### 5.2.4: Why This Application (1 paragraph)

Justify the empirical setting:

> "Entrepreneurship provides an ideal testing ground for these methods. Startup counts are weakly positive, highly skewed, and sparse at fine geographic levels. Proportional effects—percentage changes in startup rates—are the natural object of policy interest. Yet the applied literature routinely employs transformations that do not identify these effects. By revisiting a prominent study with methods designed for the outcome's structure, we demonstrate that methodological choices can reverse substantive conclusions."

#### 5.2.5: Roadmap (1 paragraph)

Brief and functional:

> "Section 2 reviews the related literature and describes the empirical context. Section 3 defines the target parameters. Section 4 establishes identification under nonlinear parallel trends. Section 5 develops the estimators and discusses implementation. Section 6 presents extensions. Section 7 applies the methods to state R&D tax credits. Section 8 concludes."

---

### Task 5.3: Write Section 2 (Literature and Context)

This section has three subsections, each approximately 800-1,000 words.

#### 5.3.1: Section 2.1 - Methodological Literature

Organize into four themes:

**Theme 1: The DiD Revolution**
- Classic DiD papers (Ashenfelter & Card 1985, Card & Krueger 1994)
- Modern understanding of identifying assumptions (Angrist & Pischke 2009)
- Parallel trends as inherently untestable but partially assessable

**Theme 2: Staggered Adoption Problems**
- Goodman-Bacon (2021) decomposition
- Negative weighting problem
- Heterogeneous effects under TWFE
- Solutions: Callaway-Sant'Anna, Sun-Abraham, de Chaisemartin-D'Haultfœuille, Borusyak et al.

**Theme 3: The Functional Form Problem**
- Chen & Roth (2024) on log-like transformations
- Why log(1+Y) doesn't identify % effects
- Scale-dependence of parallel trends
- Existing solutions: Wooldridge (2023) Poisson approach

**Theme 4: Machine Learning for Causal Inference**
- Double/debiased ML (Chernozhukov et al. 2018)
- Automatic debiased ML (Chernozhukov et al. 2021)
- GRF and honest inference (Athey, Tibshirani, Wager 2019)
- Cross-fitting and regularization bias

**Write as flowing prose**, not bullet points. Example:

> "A growing methodological literature extends difference-in-differences designs beyond linear, additive specifications. Wooldridge (2023) develops estimators for count outcomes under log-mean parallel trends, showing that Poisson quasi-maximum likelihood delivers consistent estimates of proportional effects when the ratio of expected outcomes evolves similarly across groups. However, his framework relies on parametric specifications for the conditional mean function. When the outcome depends on high-dimensional covariates or exhibits complex nonlinearities, parametric approaches may introduce specification error that undermines the credibility of the identifying assumption.
>
> Recent advances in debiased machine learning offer a path forward. Chernozhukov et al. (2018) show that..."

#### 5.3.2: Section 2.2 - The Startup Cartography Project

Describe the data infrastructure:
- What it measures (formation, quality, growth events)
- How it's constructed (business registrations, growth signals)
- Geographic and temporal coverage
- Why it's well-suited to this application

#### 5.3.3: Section 2.3 - R&D Tax Credits and Prior Evidence

Summarize Fazio, Guzman, and Stern (2020):
- Research question and findings
- Empirical strategy (TWFE with log outcomes)
- Methodological limitations we address

---

### Task 5.4: Complete Sections 3-6 (Methodology)

The draft has the structure; fill in the "[To be added...]" sections.

#### 5.4.1: Section 5.2 - Continuous Treatments

Write 500-800 words covering:
- Extension of identification to continuous D
- Dose-response parameters: ATT_D(d), ATT_S
- Neyman-orthogonal scores (analogous to binary case)
- Practical considerations (density estimation, support)

#### 5.4.2: Section 5.3 - Multiple Periods and Staggered Adoption

Write 500-800 words covering:
- Integration with Callaway-Sant'Anna framework
- Group-time ATT: θ(g,t) for each cohort g and time t
- Aggregation schemes: event study, group, overall
- Inference with clustering

#### 5.4.3: Section 5.4 - Repeated Cross Sections

Write 300-500 words covering:
- Adaptation when units not observed in both periods
- Modified identification (no unit FE)
- Examples where this applies

#### 5.4.4: Section 6 - Extensions

For each extension, write 200-400 words explaining:
- The setting and why standard methods fail
- How the framework adapts
- What changes in identification/estimation

**6.1 Benchmarking Intensive Margins**: How to interpret proportional effects in levels

**6.2 Generalized PT Assumptions**: 
- Hazard models (survival outcomes)
- Selection models (censoring/truncation)
- Discrete choice (multinomial outcomes)
- Compositional DiD (shares that sum to 1)

---

### Task 5.5: Write Section 7 (Empirical Application)

This is the core of the paper. Write 3,500-4,000 words, heavily integrated with tables and figures.

#### 5.5.1: Section 7.1 - Data and Empirical Strategy (800-1,000 words)

**Paragraph 1**: Data sources
> "The analysis uses a county-level panel constructed from the Startup Cartography Project and the Panel Database of Incentives and Taxes. The sample covers [N] counties across [M] states observed annually from 1990 to 2010, yielding [T] county-year observations."

**Paragraph 2**: Outcome variables
> "The primary outcome is the count of new firm formations in each county-year, measured by business registrations recorded in the SCP. This outcome is weakly positive, with a mean of [X], standard deviation of [Y], and [Z]% zeros at the county-year level. Secondary outcomes include..."

**Paragraph 3**: Treatment variables
> "Treatment is defined by the adoption of state R&D tax credits, with timing and generosity drawn from the PDIT. Figure [X] plots the staggered adoption pattern across states. By 2010, [N] states had adopted some form of R&D credit, with credit rates ranging from [X]% to [Y]%."

**Paragraph 4**: Covariates
> "We augment the SCP data with county-level covariates capturing local economic conditions. The parsimonious specification includes seven variables: log population, log employment-to-population ratio, log average wage, log baseline startup formation, an indicator for any startups in 1988, the logit of baseline quality, and an indicator for high-growth startups. The full specification adds [X] additional variables..."

**Paragraph 5**: Empirical strategy preview
> "The empirical strategy proceeds in three steps. First, we replicate the original TWFE analysis to establish a baseline. Second, we apply the Callaway-Sant'Anna estimator to address staggered adoption concerns while maintaining the log-plus-one transformation. Third, we implement the proposed nonlinear DiD estimators, imposing parallel trends on the log-mean scale and using machine learning for covariate adjustment."

Include: **Table 1: Summary Statistics**

#### 5.5.2: Section 7.2 - Replication and Benchmarking (600-800 words)

Present the replication results:

> "Column 1 of Table [X] reports the TWFE estimate using log(1+Y) as the outcome, following Fazio et al. (2020). The coefficient of 0.090 (SE = 0.025) implies that R&D credit adoption is associated with approximately 9% more startups, statistically significant at conventional levels. This estimate closely replicates the original findings."

> "Column 2 applies the Callaway-Sant'Anna estimator to the same outcome. The overall ATT of 0.085 (SE = 0.028) is slightly smaller than TWFE but remains positive and significant. Figure [X] plots the event study, showing no evidence of pre-trends and positive post-treatment effects."

> "These results confirm that addressing staggered adoption alone does not resolve the functional form problem. Both estimators impose linear parallel trends on a transformed outcome that does not identify a well-defined proportional effect."

Include: 
- **Table 2: Replication Results (TWFE vs. CS-DiD)**
- **Figure 1: Event Study, log(1+Y) Outcome**

#### 5.5.3: Section 7.3 - Nonlinear Parallel Trends Results (1,000-1,200 words)

This is the key section. Present the main findings clearly:

> "We now turn to estimates under outcome-consistent identification. Column 3 of Table [X] reports the nonlinear DiD estimate without covariates, targeting the weighted proportional ATT under log-mean parallel trends. The point estimate is -0.095 (SE = 0.022), implying that R&D credit adoption *reduces* startup formation by approximately 9.5%. This estimate is opposite in sign to the transformed-outcome results and statistically significant."

> "Column 4 adds the parsimonious covariate set, with nuisance functions estimated by generalized random forests. The estimate is -0.102 (SE = 0.024), slightly larger in magnitude and more precisely estimated. The 95% confidence interval of [-0.15, -0.06] excludes zero and, importantly, excludes the positive effects implied by standard methods."

> "Figure [X] displays the event study under nonlinear parallel trends. The pre-treatment coefficients are close to zero and jointly insignificant (p = 0.41), supporting the identifying assumption. Post-treatment coefficients are uniformly negative, with magnitudes increasing over the first five years before stabilizing."

**Interpretation paragraph**:

> "How should we interpret these results? Under log-mean parallel trends, the estimand captures the average percentage deviation of treated outcomes from their counterfactual values. An estimate of -0.10 implies that, among counties whose states adopted R&D credits, startup formation is approximately 10% lower than it would have been absent the policy. This contrasts sharply with the +9% effect implied by log-transformed linear DiD."

**Reconciling the sign reversal**:

> "The sign reversal arises from two sources. First, the identifying assumption differs: linear parallel trends in log(1+Y) does not imply, and is not implied by, log-mean parallel trends in Y. Second, the estimands differ: even if both assumptions held, they target different parameters. The log(1+Y) coefficient lacks a clear causal interpretation (Chen and Roth 2024), while the weighted proportional ATT is a well-defined average of unit-level percentage effects."

Include:
- **Table 3: Main Results - Linear vs. Nonlinear PT**
- **Figure 2: Event Study Comparison (4-panel)**
- **Figure 3: Specification Curve**

#### 5.5.4: Section 7.4 - Robustness and Sensitivity (800-1,000 words)

Systematically address potential concerns:

**First-stage learner sensitivity**:
> "Table [X] reports estimates across alternative first-stage learners. The nonlinear PT estimates range from -0.089 (LASSO) to -0.115 (XGBoost), with all point estimates negative and significant. The GRF-based estimate lies near the median of this range, suggesting the main finding is not driven by learner choice."

**Covariate specification**:
> "Adding the full covariate set (Column 5) yields an estimate of -0.098 (SE = 0.026), essentially unchanged from the parsimonious specification. This stability suggests the seven-variable specification captures the relevant confounding variation."

**Alternative outcomes**:
> "We replicate the analysis for secondary outcomes. For the Entrepreneurial Quality Index, both linear and nonlinear estimates are close to zero and insignificant, consistent with the original paper's null findings for quality. For the high-growth indicator, the nonlinear estimate is -0.08 (SE = 0.04), directionally consistent with the formation results."

**Alternative treatment definitions**:
> "Using continuous treatment intensity (credit rate) rather than binary adoption yields similar conclusions. The nonlinear slope estimate implies a [X]% reduction in startups per percentage point of credit rate."

**Placebo and pre-trend tests**:
> "The joint test for pre-treatment effects yields p = [X], providing no evidence against the identifying assumption. As a placebo, we apply the estimators to county-level population growth, which should not respond to R&D credits. Both linear and nonlinear estimates are close to zero, as expected."

Include:
- **Table 4: Robustness Across Specifications**
- **Figure 4: First-Stage Learner Sensitivity**
- **Table 5: Alternative Outcomes**

#### 5.5.5: Section 7.5 - Economic Magnitude (400-500 words)

Translate statistical findings into economic terms:

> "What is the economic magnitude of these effects? The average treated county has approximately [X] startup formations per year. A 10% reduction implies [Y] fewer startups annually, or [Z] over the post-adoption period in our sample. Aggregating across all treated counties yields approximately [W] 'missing' startups attributable to R&D credit adoption."

> "These magnitudes are large relative to policy expectations. R&D tax credits are intended to stimulate innovation and entrepreneurship by reducing the effective cost of research investment. Our estimates suggest the opposite: that these credits may crowd out new firm formation. One interpretation is that R&D credits favor incumbent firms, who capture the subsidy while new entrants face relatively higher costs..."

> "We caution against strong causal claims. The estimates reflect the average effect under the identifying assumptions, which may not hold. Nonetheless, the reversal from positive to negative effects—depending solely on functional form choices—demonstrates that applied researchers must carefully consider whether their transformations and identifying assumptions are consistent with the outcome's structure."

---

### Task 5.6: Write Section 8 (Conclusion)

Write 800-1,000 words covering:

**Summary of contributions**:
> "This paper develops semi-parametric difference-in-differences estimators for outcomes that are discrete, bounded, or weakly positive. By imposing identification on outcome-consistent link scales and combining with flexible machine learning methods for covariate adjustment, the framework delivers estimators that respect support restrictions, target well-defined causal effects, and provide valid inference."

**Empirical takeaway**:
> "Applied to state R&D tax credits, the methods reveal substantial sensitivity to functional form assumptions. The standard finding—that R&D credits increase startup formation—reverses sign under outcome-consistent identification. This reversal is robust across specifications and underscores the importance of aligning methods with outcome structure."

**Limitations**:
> "Several limitations warrant acknowledgment. First, the identifying assumptions remain untestable. While pre-trend tests support the log-mean parallel trends assumption, they cannot rule out violations. Second, the estimates are local to the support of the data; extrapolation to different policy environments requires additional assumptions. Third, computational costs are non-trivial, particularly for large-dimensional covariate sets."

**Implications for practice**:
> "For applied researchers, the paper offers practical guidance. When outcomes are counts or bounded, avoid ad hoc transformations. Instead, impose parallel trends on a link scale consistent with the outcome's support. Use machine learning for covariate adjustment to reduce specification error. Report estimates under multiple identifying assumptions to assess sensitivity."

**Future directions**:
> "Several extensions merit further investigation. Continuous treatment intensity, dynamic treatment effects, and interference across units all present challenges that the current framework addresses only partially. A companion R package, `nldid`, will facilitate implementation in applied work."

---

### Task 5.7: Create All Tables

#### Table 1: Summary Statistics
```
Panel A: Outcome Variables
                        Mean    SD      Min     Max     Zeros (%)
Startup Formation       XX.X    XX.X    0       XXX     XX.X
log(1 + Formation)      X.XX    X.XX    0       X.XX    XX.X
Quality Index           0.XX    0.XX    0       1       XX.X
High-Growth Indicator   0.XX    0.XX    0       1       XX.X

Panel B: Treatment Variables
                        Mean    SD      Min     Max
R&D Credit Adoption     0.XX    0.XX    0       1
R&D Credit Rate (%)     X.XX    X.XX    0       XX.X

Panel C: Covariates
...
```

#### Table 2: Replication Results
TWFE and CS-DiD with log(1+Y) outcome

#### Table 3: Main Results
Linear vs. Nonlinear PT comparison (5-6 columns)

#### Table 4: Robustness
Across first-stage learners, covariate sets, samples

#### Table 5: Alternative Outcomes
Quality, growth, per capita formation

#### Table 6: First-Stage Prediction Performance
RMSE, R² for each learner

#### Table 7: Covariate Balance
Treated vs. control comparisons

#### Table 8: Pre-Trend Tests
Joint significance tests across specifications

---

### Task 5.8: Create All Figures

#### Figure 1: R&D Tax Credit Adoption Timeline
Map or timeline showing staggered adoption

#### Figure 2: Event Study - Standard Approach
log(1+Y) outcome, TWFE or CS-DiD

#### Figure 3: Event Study - Nonlinear PT
Levels outcome, log-mean PT, 4-panel comparison

#### Figure 4: Specification Curve
All estimates sorted with specification indicators

#### Figure 5: First-Stage Learner Sensitivity
Forest plot of ATT across learners

#### Figure 6: Variable Importance
From GRF, showing which covariates matter

#### Figure 7: Pre-Trends Comparison
Pre-treatment coefficients under different assumptions

#### Figure 8: Distribution of Outcomes
Histogram/density of startup counts, highlighting zeros and skewness

---

### Task 5.9: Complete the Appendix

#### Appendix A: Proofs
- Proof of identification under Assumption 1 (binary treatment)
- Proof of identification under Assumption 2 (continuous treatment)
- Derivation of Neyman-orthogonal scores
- Derivation of Riesz representers for log-mean link

#### Appendix B: Additional Results
- Full covariate coefficient table
- State-by-state results
- Alternative bandwidth/tuning sensitivity
- Bootstrapped confidence intervals

#### Appendix C: Data Construction
- Variable definitions
- Sample restrictions
- Crosswalks between data sources

---

### Task 5.10: Writing Quality Checklist

Before finalizing, verify:

**Clarity**:
- [ ] Every variable defined before first use
- [ ] Every acronym spelled out on first use
- [ ] Every equation numbered and referenced
- [ ] Every table and figure referenced in text

**Precision**:
- [ ] Point estimates reported with standard errors AND confidence intervals
- [ ] Statistical significance indicated consistently (stars, p-values)
- [ ] Sample sizes reported for every specification
- [ ] Clustering level stated for all standard errors

**Rigor**:
- [ ] Identifying assumptions stated formally
- [ ] Limitations acknowledged explicitly
- [ ] Causal language appropriately hedged
- [ ] Robustness concerns addressed systematically

**Style**:
- [ ] Active voice preferred
- [ ] Paragraphs have clear topic sentences
- [ ] Transitions between sections smooth
- [ ] No orphan sentences or paragraphs

**Formatting**:
- [ ] Consistent notation throughout
- [ ] Tables formatted for journal submission
- [ ] Figures high-resolution, colorblind-friendly
- [ ] References complete and consistent

---

## 🛑 CHECKPOINT 5: Paper Draft Complete

**Before proceeding, confirm:**
- [ ] All sections written (no "[To be added...]" remains)
- [ ] All tables created and formatted
- [ ] All figures created and formatted
- [ ] Appendix complete
- [ ] References verified and formatted
- [ ] Writing quality checklist passed

**Present for review:**
1. Complete paper draft (PDF compiled from LaTeX or clean Markdown)
2. All tables (as separate files and in paper)
3. All figures (as separate files and in paper)
4. Appendix materials
5. Bibliography file

**STOP and wait for approval to proceed to Phase 6.**

---

## PHASE 6: Final Deliverables

### Task 6.1: Organize Code

Final code structure:
```
code/
├── 00_setup.R                # Packages, paths, settings
├── 01_data_prep.R            # Load and prepare data
├── 02_replication.R          # TWFE and CS-DiD replication
├── 03_nonlinear_did.R        # Nonlinear estimators
├── 04_robustness.R           # Sensitivity analyses
├── 05_figures.R              # Generate all figures
├── 06_tables.R               # Generate all tables
└── utils/
    └── estimators.R          # Custom estimator functions
```

### Task 6.2: Documentation

Create comprehensive `README.md`:
- Project overview
- Data sources and access
- Software requirements
- Replication instructions
- File descriptions

### Task 6.3: Final Validation

Run complete pipeline:
1. Start from raw data
2. Execute all scripts in order
3. Verify all outputs match paper

---

## 🛑 FINAL CHECKPOINT: Project Complete

**Confirm all deliverables:**
- [ ] Complete paper (LaTeX/PDF)
- [ ] All analysis code (documented, reproducible)
- [ ] All output files (tables, figures)
- [ ] README with replication instructions
- [ ] Notes documenting all decisions

**Present final deliverables for review.**

---

## Appendix: Key Equations Reference

### Linear Parallel Trends (Standard DiD)

**Assumption:**
$$E[Y_{i1}(0) - Y_{i0}(0) | D_i = 1, X_i] = E[Y_{i1}(0) - Y_{i0}(0) | D_i = 0, X_i]$$

**Counterfactual:**
$$\Delta_i(X_i) = E[Y_{i0} | D_i = 1, X_i] + E[Y_{i1} | D_i = 0, X_i] - E[Y_{i0} | D_i = 0, X_i]$$

**ATT:**
$$ATT = E[Y_{i1} - \Delta_i(X_i) | D_i = 1]$$

### Nonlinear Parallel Trends (Log-Mean)

**Assumption:**
$$\frac{E[Y_{i1}(0) | D_i = 1, X_i]}{E[Y_{i0}(0) | D_i = 1, X_i]} = \frac{E[Y_{i1}(0) | D_i = 0, X_i]}{E[Y_{i0}(0) | D_i = 0, X_i]}$$

**Counterfactual:**
$$\Delta_i(X_i) = \frac{\mu^1_0(X_i) \cdot \mu^0_1(X_i)}{\mu^0_0(X_i)}$$

**Weighted Proportional ATT:**
$$ATT_{\omega,\%} = E\left[\frac{Y_{i1}}{\Delta_i(X_i)} - 1 \bigg| D_i = 1\right]$$

### Neyman-Orthogonal Score (Log-Mean)

$$\psi(W_i; \theta, g) = \frac{D_i}{\pi}\left[\frac{\mu^1_1(X_i)}{\Delta_i(X_i)} - 1 - \theta + \text{debiasing terms}\right]$$

Where debiasing terms correct for first-stage estimation error in $\mu^d_t(X)$.

---

## Quality Standards

### Statistical Standards
- Report point estimates with standard errors AND confidence intervals
- Cluster standard errors at county level
- Use cross-fitting for all ML-based estimates
- Set seeds for reproducibility

### Writing Standards
- Clear, precise econometric language
- Define all notation before use
- Interpret magnitudes economically
- Acknowledge limitations honestly

### Reproducibility Standards
- All results reproducible from code
- No manual data manipulation
- Seeds set for stochastic elements
- Package versions documented

### Citation Standards
- Every cited paper must be verified to exist
- No hallucinated citations
- Consistent citation format