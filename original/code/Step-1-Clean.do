/*******************************************************************************
*                                                                              *
*   NONLINEAR DIFFERENCE-IN-DIFFERENCES PROJECT                                *
*   Data Preparation and Panel Construction                                    *
*                                                                              *
*   Author:  Spencer Sween                                                     *
*   Purpose: Merge and clean county-level entrepreneurship data with           *
*            state-level tax incentive policies for DiD analysis               *
*                                                                              *
*   Input Files:                                                               *
*     - PDIT.csv (Panel Database of Incentives and Taxes)                      *
*     - Entrepreneurship_by_County_academic.dta (Startup Cartography Project)  *
*     - historical_county_populations_v2.csv                                   *
*     - allhlcn90.xlsx (QCEW 1990 county-level data)                           *
*                                                                              *
*   Output Files:                                                              *
*     - scp_pdit_county.csv (Final analysis dataset)                           *
*                                                                              *
*******************************************************************************/

clear all
cls


/*******************************************************************************
*                                                                              *
*   SECTION 0: DEFINE FILE PATHS AND IMPORT RAW DATA                           *
*                                                                              *
*   This section imports all raw data files from their original locations      *
*   and saves copies to the project's raw data folder.                         *
*                                                                              *
*******************************************************************************/

*-------------------------------------------------------------------------------
* Define Directory Paths
*-------------------------------------------------------------------------------

global raw      "/Users/spencersween/Dropbox/Non-Linear DiD Claude Project/original/raw"
global modified "/Users/spencersween/Dropbox/Non-Linear DiD Claude Project/original/modified"
global final    "/Users/spencersween/Dropbox/Non-Linear DiD Claude Project/original/final"

*-------------------------------------------------------------------------------
* Import and Save Raw Data Files (Commented Out and Never Done Again)
*-------------------------------------------------------------------------------

// * PDIT (Panel Database of Incentives and Taxes)
// import delimited "/Users/spencersween/Dropbox/Nonlinear DiD Project/Data/1 - Raw/PDIT.csv", clear
// save "${raw}/PDIT.dta", replace
//
// * Startup Cartography Project (County-Level)
// use "/Users/spencersween/Dropbox/Nonlinear DiD Project/Data/1 - Raw/Entrepreneurship_by_County_academic.dta", clear
// save "${raw}/Entrepreneurship_by_County_academic.dta", replace
//
// * Historical County Populations
// import delimited "/Users/spencersween/Downloads/historical_county_populations_v2.csv", clear varn(1)
// save "${raw}/historical_county_populations.dta", replace
//
// * QCEW 1990 (US Mainland)
// import excel "/Users/spencersween/Downloads/1990_all_county_high_level/allhlcn90.xlsx", ///
// 	clear firstrow sheet("US_St_Cn_MSA")
// save "${raw}/qcew_1990_us.dta", replace
//
// * QCEW 1990 (Puerto Rico and Virgin Islands)
// import excel "/Users/spencersween/Downloads/1990_all_county_high_level/allhlcn90.xlsx", ///
// 	clear firstrow sheet("US_PR_VI")
// save "${raw}/qcew_1990_prvi.dta", replace


/*******************************************************************************
*                                                                              *
*   SECTION 1: CLEAN PANEL DATABASE OF INCENTIVES AND TAXES (PDIT)             *
*                                                                              *
*   This section processes state-level tax incentive data, including:          *
*     - R&D Tax Credits                                                        *
*     - Investment Tax Credits                                                 *
*   Creates treatment cohort indicators for staggered DiD design.              *
*                                                                              *
*******************************************************************************/

use "${raw}/PDIT.dta", clear

*-------------------------------------------------------------------------------
* Filter and Rename Variables
*-------------------------------------------------------------------------------

* Keep 'All Export' industries (consistent with published paper methodology)
keep if industry == "All Export"

* Select and rename relevant variables
keep state baseyear researchanddevelopmentcredit investmenttaxcredit
rename baseyear year
rename researchanddevelopmentcredit rnd
rename investmenttaxcredit itc

* Restrict to sample period
keep if inrange(year, 1990, 2010)

*-------------------------------------------------------------------------------
* Create Treatment Cohort Indicators (Staggered Adoption Design)
*-------------------------------------------------------------------------------

* R&D Tax Credit adoption cohort (G_rnd)
* First year with positive R&D credit; 0 = never treated
gen t = year if rnd > 0
hashsort state year
by state: gegen G_rnd = min(t)
replace G_rnd = 0 if missing(G_rnd)
drop t

* Investment Tax Credit adoption cohort (G_itc)
* First year with positive ITC; 0 = never treated
gen t = year if itc > 0
hashsort state year
by state: gegen G_itc = min(t)
replace G_itc = 0 if missing(G_itc)
drop t

* Combined treatment cohort (G_both)
* Earliest adoption of either credit
gen G_both = G_rnd
replace G_both = G_itc if G_itc > 0 & G_rnd > 0 & G_itc < G_rnd 
replace G_both = G_itc if G_itc > 0 & G_rnd == 0

*-------------------------------------------------------------------------------
* Create Continuous and Binary Treatment Variables
*-------------------------------------------------------------------------------

hashsort state year

* R&D Credit: year-over-year change and binary indicator
gen delta_rnd = 0
by state: replace delta_rnd = rnd - rnd[_n-1] if _n > 1
gen has_rnd = rnd > 0

* Investment Tax Credit: year-over-year change and binary indicator
gen delta_itc = 0
by state: replace delta_itc = itc - itc[_n-1] if _n > 1
gen has_itc = itc > 0

* Combined treatment indicator
gen has_both = has_rnd | has_itc

*-------------------------------------------------------------------------------
* Finalize and Save
*-------------------------------------------------------------------------------

keep state year itc rnd G_rnd G_itc delta_rnd has_rnd delta_itc has_itc G_both has_both
order state year itc rnd G_rnd G_itc delta_rnd has_rnd delta_itc has_itc G_both has_both
hashsort state year

* Clear variable labels
foreach v of varlist * {
	label var `v' ""
}

export delimited "${modified}/pdit.csv", replace


/*******************************************************************************
*                                                                              *
*   SECTION 2: CLEAN STARTUP CARTOGRAPHY PROJECT (COUNTY-LEVEL)                *
*                                                                              *
*   This section processes county-level entrepreneurship metrics:              *
*     - SFR: Startup Formation Rate                                            *
*     - EQI: Entrepreneurial Quality Index                                     *
*     - Growth: High-growth firm indicator                                     *
*     - RECPI: Regional Entrepreneurship Cohort Potential Index                *
*                                                                              *
*******************************************************************************/

use "${raw}/Entrepreneurship_by_County_academic.dta", clear

*-------------------------------------------------------------------------------
* Initial Variable Processing
*-------------------------------------------------------------------------------

rename *, lower
destring countycode, gen(countyfips)
keep state countyfips year sfr eqi growth recpi
order state countyfips year sfr eqi growth recpi

*-------------------------------------------------------------------------------
* Fix ZIP-to-County Crosswalk Artifacts
*-------------------------------------------------------------------------------

* Round SFR to integer (artifact from weighted crosswalk)
replace sfr = ceil(sfr)

* Correct masked positive values
replace sfr = 1 if sfr == 0 & eqi > 0

* Convert growth to binary indicator
replace growth = growth > 0

*-------------------------------------------------------------------------------
* Create Balanced Panel
*-------------------------------------------------------------------------------

xtset countyfips year
tsfill, full

* Carry forward/backward state identifiers
hashsort countyfips -year
by countyfips: carryforward state, replace
hashsort countyfips year
by countyfips: carryforward state, replace

* Fill missing outcomes with zeros
foreach v of varlist sfr eqi growth recpi {
	replace `v' = 0 if missing(`v')
}

*-------------------------------------------------------------------------------
* Restrict Sample Period and Create Pre-Period Measures
*-------------------------------------------------------------------------------

hashsort countyfips year

* Keep 1988-1989 for pre-period covariates, 1990-2010 for analysis
keep if inrange(year, 1988, 2010)
keep state countyfips year sfr eqi growth
order state countyfips year sfr eqi growth

* Create pre-panel outcome measures (1988 and 1989 baselines)
hashsort countyfips year
forvalues i = 1988(1)1989 {
	gen t1 = sfr if year == `i'
	gen t2 = eqi if year == `i'
	gen t3 = growth if year == `i'
	by countyfips: gegen W_sfr_`i' = firstnm(t1)
	by countyfips: gegen W_eqi_`i' = firstnm(t2)
	by countyfips: gegen W_growth_`i' = firstnm(t3)
	drop t1 t2 t3
}

export delimited "${modified}/scp_county.csv", replace


/*******************************************************************************
*                                                                              *
*   SECTION 3: CREATE COUNTY-LEVEL COVARIATES                                  *
*                                                                              *
*   This section creates baseline covariates from:                             *
*     - Historical population data (1900-2010)                                 *
*     - QCEW employment and wage data (1990)                                   *
*                                                                              *
*******************************************************************************/

*===============================================================================
* 3A: HISTORICAL POPULATION DATA (1900-2010)
*===============================================================================

use "${raw}/historical_county_populations.dta", clear

rename cty_fips countyfips
keep countyfips pop_2010 pop_2000 pop_1990 pop_1980 pop_1970 pop_1960 ///
     pop_1950 pop_1940 pop_1930 pop_1920 pop_1910 pop_1900

* Log-transform population and create missing indicators
foreach v of varlist pop_* {
	rename `v' temp
	gen `v' = temp
	replace `v' = log(`v') if `v' > 0
	gen has_`v' = `v' > 0
	drop temp
}

* Drop always-positive indicators (uninformative)
drop has_pop_1990 has_pop_2000 has_pop_2010

export delimited "${modified}/covariates_pop.csv", replace

*===============================================================================
* 3B: QCEW EMPLOYMENT AND WAGE DATA (1990)
*===============================================================================

* Load US mainland data
use "${raw}/qcew_1990_us.dta", clear
save "${modified}/empwage_temp.dta", replace

* Append Puerto Rico and Virgin Islands
use "${raw}/qcew_1990_prvi.dta", clear
append using "${modified}/empwage_temp.dta"
erase "${modified}/empwage_temp.dta"

*-------------------------------------------------------------------------------
* Process Geographic Identifiers
*-------------------------------------------------------------------------------

gen s = St + Cnty
destring St, gen(statefips) force
destring s, gen(countyfips) force
split Area, parse(",")
rename Area1 county
rename Area2 state
drop if missing(countyfips)
keep if AreaType == "County"

*-------------------------------------------------------------------------------
* Create Aggregate Employment/Wage Variables by Ownership Type
*-------------------------------------------------------------------------------

* Total Covered Employment
gen total_est = AnnualAverageEstablishmentCou if Ownership == "Total Covered"
gen total_emp = AnnualAverageEmployment if Ownership == "Total Covered"
gen total_wage = AnnualAveragePay if Ownership == "Total Covered"

* Federal Government
gen fed_est = AnnualAverageEstablishmentCou if Ownership == "Federal Government"
gen fed_emp = AnnualAverageEmployment if Ownership == "Federal Government"
gen fed_wage = AnnualAveragePay if Ownership == "Federal Government"
gen fed_ratio_e = EmploymentLocationQuotientRel if Ownership == "Federal Government"
gen fed_ratio_w = TotalWageLocationQuotientRel if Ownership == "Federal Government"

* State Government
gen state_est = AnnualAverageEstablishmentCou if Ownership == "State Government"
gen state_emp = AnnualAverageEmployment if Ownership == "State Government"
gen state_wage = AnnualAveragePay if Ownership == "State Government"
gen state_ratio_e = EmploymentLocationQuotientRel if Ownership == "State Government"
gen state_ratio_w = TotalWageLocationQuotientRel if Ownership == "State Government"

* Local Government
gen local_est = AnnualAverageEstablishmentCou if Ownership == "Local Government"
gen local_emp = AnnualAverageEmployment if Ownership == "Local Government"
gen local_wage = AnnualAveragePay if Ownership == "Local Government"
gen local_ratio_e = EmploymentLocationQuotientRel if Ownership == "Local Government"
gen local_ratio_w = TotalWageLocationQuotientRel if Ownership == "Local Government"

* Private Sector (All Industries)
gen priv_est = AnnualAverageEstablishmentCou if Ownership == "Private" & Industry == "Total, all industries"
gen priv_emp = AnnualAverageEmployment if Ownership == "Private" & Industry == "Total, all industries"
gen priv_wage = AnnualAveragePay if Ownership == "Private" & Industry == "Total, all industries"
gen priv_ratio_e = EmploymentLocationQuotientRel if Ownership == "Private" & Industry == "Total, all industries"
gen priv_ratio_w = TotalWageLocationQuotientRel if Ownership == "Private" & Industry == "Total, all industries"

*-------------------------------------------------------------------------------
* Create Industry-Specific Variables (Private Sector)
*-------------------------------------------------------------------------------

* Standardize industry names
replace Industry = lower(trim(Industry))
tab Industry if Industry != "Total, all industries"

replace Industry = "education" if regexm(Industry, "education")
replace Industry = "finance" if regexm(Industry, "financial")
replace Industry = "goods" if regexm(Industry, "goods")
replace Industry = "information" if regexm(Industry, "information")
replace Industry = "leisure" if regexm(Industry, "leisure")
replace Industry = "manufacturing" if regexm(Industry, "manufacturing")
replace Industry = "mining" if regexm(Industry, "mining")
replace Industry = "other" if regexm(Industry, "other")
replace Industry = "business" if regexm(Industry, "business")
replace Industry = "service" if regexm(Industry, "service-providing")
replace Industry = "trade" if regexm(Industry, "trade")

* Generate sector-specific variables
glevelsof Industry if Industry != "total, all industries", local(sectors)
foreach s in `sectors' {
    local vname = subinstr("`s'", " ", "_", .)
    gen `vname'_est     = AnnualAverageEstablishmentCou if Ownership == "Private" & Industry == "`s'"
    gen `vname'_emp     = AnnualAverageEmployment       if Ownership == "Private" & Industry == "`s'"
    gen `vname'_wage    = AnnualAveragePay              if Ownership == "Private" & Industry == "`s'"
    gen `vname'_ratio_e = EmploymentLocationQuotientRel if Ownership == "Private" & Industry == "`s'"
    gen `vname'_ratio_w = TotalWageLocationQuotientRel  if Ownership == "Private" & Industry == "`s'"
}

*-------------------------------------------------------------------------------
* Collapse to County Level
*-------------------------------------------------------------------------------

gcollapse (firstnm) total_est-trade_ratio_w, by(state county statefips countyfips)

* Log-transform counts and create missing indicators
foreach v of varlist *_est *_emp *_wage {
	replace `v' = 0 if missing(`v')
	rename `v' temp
	gen `v' = temp
	replace `v' = log(`v') if `v' > 0
	gen has_`v' = `v' > 0
	drop temp
}
drop has_total_*

* Process location quotients
foreach v of varlist *_ratio_* {
	replace `v' = 0 if missing(`v')
	rename `v' temp
	gen `v' = temp
	gen has_`v' = `v' > 0
	drop temp
}

export delimited "${modified}/empwage.csv", replace

*===============================================================================
* 3C: MERGE COVARIATE DATASETS
*===============================================================================

* Load population covariates into tempfile for merging
import delimited "${modified}/covariates_pop.csv", clear case(preserve)
tempfile covariates_pop
save `covariates_pop', replace

* Load employment/wage data and merge with population
import delimited "${modified}/empwage.csv", clear case(preserve)
merge 1:1 countyfips using `covariates_pop', keep(3) nogen

* Prefix all covariates with X_
foreach v of varlist total_est-has_pop_1900 {
	rename `v' X_`v'
}

export delimited "${modified}/covariates.csv", replace

/*
NOTE: The following counties have missing covariates:
    1) Shannon County, South Dakota
    2) Bedford City, Virginia
    3) Prince of Wales-Outer Ketchikan Census Area, Alaska
    4) Valdez-Cordova Census Area, Alaska
    5) Wade Hampton Census Area, Alaska
    6) Wrangell-Petersburg Census Area, Alaska
    7) Puerto Rico
    8) U.S. Virgin Islands
*/


/*******************************************************************************
*                                                                              *
*   SECTION 4: MERGE ALL COUNTY-LEVEL DATA                                     *
*                                                                              *
*   This section combines:                                                     *
*     - Startup Cartography Project outcomes                                   *
*     - State tax incentive treatments                                         *
*     - County-level covariates                                                *
*                                                                              *
*******************************************************************************/

*-------------------------------------------------------------------------------
* Load Tempfiles for Merging
*-------------------------------------------------------------------------------

* Load covariates into tempfile
import delimited "${modified}/covariates.csv", clear case(preserve)
tempfile covariates
save `covariates', replace

* Load PDIT into tempfile
import delimited "${modified}/pdit.csv", clear case(preserve)
tempfile pdit
save `pdit', replace

*-------------------------------------------------------------------------------
* Merge State-Level Tax Incentives
*-------------------------------------------------------------------------------

* Load SCP county data
import delimited "${modified}/scp_county.csv", clear case(preserve)

* Merge with tax incentives
merge m:1 state year using `pdit', keep(1 3)

* Keep only counties that never merged (i.e., non-US states)
hashsort countyfips year
by countyfips: gegen max_merge = max(_merge == 3)
keep if max_merge == 1
drop _merge max_merge

* Forward-fill treatment variables
hashsort countyfips -year
by countyfips: carryforward itc rnd G_rnd G_itc delta_rnd has_rnd ///
    delta_itc has_itc G_both has_both, replace
hashsort countyfips year

*-------------------------------------------------------------------------------
* Merge County-Level Covariates
*-------------------------------------------------------------------------------

rename state state_abr

* Handle Broomfield County (created from Boulder County in 2001)
gen Broomfield = (countyfips == 8014)
replace countyfips = 8013 if countyfips == 8014

merge m:1 countyfips using `covariates', keep(3) nogen

* Restore Broomfield FIPS code
replace countyfips = 8014 if Broomfield == 1

* Drop DC (not a state)
drop if missing(state)

*-------------------------------------------------------------------------------
* Create Baseline Outcome Covariates (1988 Values)
*-------------------------------------------------------------------------------

gen X_sfr = log(W_sfr_1988)
replace X_sfr = 0 if missing(X_sfr)

gen X_eqi = log(W_eqi_1988 / (1 - W_eqi_1988))
replace X_eqi = 0 if missing(X_eqi)

gen X_growth = W_growth_1988

gen X_has_sfr = W_sfr_1988 > 0

*-------------------------------------------------------------------------------
* Create 10-Year Average Treatment Intensity
*-------------------------------------------------------------------------------

* R&D Credit: average over first 10 years post-adoption
hashsort countyfips year
gen t = rnd if year >= G_rnd & year <= G_rnd + 9
by countyfips: gegen avg_rnd = mean(t)
drop t
replace avg_rnd = 0 if missing(avg_rnd)
order avg_rnd, after(has_rnd)

* Investment Tax Credit: average over first 10 years post-adoption
hashsort countyfips year
gen t = itc if year >= G_itc & year <= G_itc + 9
by countyfips: gegen avg_itc = mean(t)
drop t
replace avg_itc = 0 if missing(avg_itc)
order avg_itc, after(has_itc)

*-------------------------------------------------------------------------------
* Create Transformed Outcome Variables
*-------------------------------------------------------------------------------

* Log transformation (zero = 0)
gen log_sfr = 0
replace log_sfr = log(sfr) if sfr > 0

* Log(1 + Y) transformation
gen log1p_sfr = log(1 + sfr)

* Inverse hyperbolic sine transformation
gen asinh_sfr = asinh(sfr)

* Per 1,000 population transformation
gen sfr_per1k = 1000 * (sfr / ceil(exp(X_pop_1990)))

*-------------------------------------------------------------------------------
* Organize Final Dataset
*-------------------------------------------------------------------------------

format state %16s
format county %16s
hashsort statefips countyfips

keep state_abr state county statefips countyfips year ///
	G_rnd rnd delta_rnd has_rnd avg_rnd ///
	G_itc itc delta_itc has_itc avg_itc ///
	G_both has_both ///
	sfr log_sfr log1p_sfr asinh_sfr sfr_per1k eqi growth ///
	W_sfr_* W_eqi_* W_growth_* ///
	X_*

order state_abr state county statefips countyfips year ///
	G_rnd rnd delta_rnd has_rnd avg_rnd ///
	G_itc itc delta_itc has_itc avg_itc ///
	G_both has_both ///
	sfr log_sfr log1p_sfr asinh_sfr sfr_per1k eqi growth ///
	W_sfr_* W_eqi_* W_growth_* ///
	X_*

* Clear variable labels
foreach v of varlist * {
	label var `v' ""
}

*-------------------------------------------------------------------------------
* Create Sample Indicators (Exclude Always-Treated and Small Cohorts)
*-------------------------------------------------------------------------------

gen Sample_rnd  = !inlist(G_rnd, 1990, 1992, 1993)
gen Sample_itc  = !inlist(G_itc, 1990)
gen Sample_both = !inlist(G_both, 1990, 1993)

order Sample_*, first

*-------------------------------------------------------------------------------
* Create Parsimonious Covariate Set (Z variables)
*-------------------------------------------------------------------------------

* For comparison with full covariate specifications
gen Z1 = X_pop_1990          // Log population (1990)
gen Z2 = log(exp(X_total_emp) / exp(X_pop_1990))  // Log employment-to-population ratio
gen Z3 = X_total_wage        // Log average wage
gen Z4 = X_sfr               // Log baseline SFR
gen Z5 = X_has_sfr           // Any startups indicator
gen Z6 = X_eqi               // Baseline EQI (logit)
gen Z7 = X_growth            // Baseline growth indicator

order Z1 Z2 Z3 Z4 Z5 Z6 Z7, last

* Drop intermediate variables
drop W_*


/*******************************************************************************
*                                                                              *
*   SECTION 5: EXPORT FINAL DATASET                                            *
*                                                                              *
*******************************************************************************/

export delimited "${final}/scp_pdit_county.csv", replace

* End of script
