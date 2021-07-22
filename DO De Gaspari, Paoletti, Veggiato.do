////////////////////////////////////////////////////////////////////////////////
//// THE DETERMINANTS OF DIVIDEND PAYOUT POLICIES                           ////
//// Aurora De Gaspari, Laura Paoletti, Daniele Veggiato                    ////
////////////////////////////////////////////////////////////////////////////////


// INDEX

// PART 1: DATA MANAGEMENT
//      1.1. Preliminary commands
//      1.2. Importing data
//      1.3. Merging data
//      1.4. Arranging data
//      1.5. Generating the independent variables
//      1.6. Generating the dependent variable
//      1.7. Data preparation
//      1.8. Winsorising and dropping outliers
//      1.9. Generating dummy variable to control for the financial crisis
//      1.10. Dropping less than 8 observations per firm
//
// PART 2: EMPIRICAL ANALYSIS
//      2.1. Descriptive statistics
//      2.2. Some data visualisation
//      2.3. Baseline regression (and analysis of residuals for each regression)
//      2.4. Testing the dependent variable
//      2.5. Testing the independent variables
//      2.6. Models comparison (using library asdoc)


// PART 1: DATA MANAGEMENT

// 1.1. Preliminary commands

clear all 

set more off 

capture cd "C:\Users\Valter\Documents\DANIELE\ERASMUS\ISEG\ECF\GROUPWORK"

capture cmlog close 

memory 
set memory 500m
set maxvar 5000
set matsize 1000

* To directly open the final dataset run the following command:
* use "DTA De Gaspari, Paoletti, Veggiato.dta", clear

// 1.2. Importing data

import delimited financials.txt, delimiter(tab) varnames(1) 
save "financials.dta", replace
clear all
import delimited sector.txt, delimiter(tab) varnames(1) 
save "sector.dta", replace
clear all
import delimited mkt_cap.txt, delimiter(tab) varnames(1) 
save "mkt_cap.dta", replace
clear all

// 1.3. Merging data

use "financials.dta", clear

merge m:m v1 using "sector.dta"
drop if _merge==1 | _merge==2
drop _merge 

merge m:m v1 v2 using "mkt_cap.dta"
drop if _merge==1 | _merge==2
drop _merge

// 1.4. Arranging data

rename v1 code 
rename v2 year 

label variable code "TRBC Code"
label variable year "Year"

move isin year
move companycommonname year
move exchangename year
move countryofheadquarters year
move trbceconomicsectorname year

drop if totalrevenue == "NULL" | ebit == "NULL" | netincomebeforetaxes == "NULL" | provisionforincometaxes == "NULL" | ///
netincomeaftertaxes == "NULL" | totalassetsreported == "NULL" | totalliabilities == "NULL" | totalequity == "NULL" | ///
totalcommonsharesoutstanding == "NULL" | retainedearningsaccumulateddefic == "NULL" | ///
cashfromoperatingactivitiescumul == "NULL" | depreciationandamortization == "NULL" | companymarketcap == "NULL"

destring totalrevenue ebit netincomebeforetaxes provisionforincometaxes netincomeaftertaxes ///
totalassetsreported totalliabilities totalequity totalcommonsharesoutstanding retainedearningsaccumulateddefic ///
cashfromoperatingactivitiescumul depreciationandamortization companymarketcap, replace

rename exchangename a
encode a, ge(exchangename)
move exchangename a
drop a

rename countryofheadquarters a
encode a, ge(countryofheadquarters)
move countryofheadquarters a
drop a

rename trbceconomicsectorname a
encode a, ge(trbceconomicsectorname)
move trbceconomicsectorname a
drop a

rename code a
encode a, ge(code)
move code a
drop a 

// 1.5. Generating the independent variables

gen PROF = ebit / totalassetsreported 
label var PROF "Profitability"

gen CF = ln(cashfromoperatingactivitiescumul)
label var CF "Cash Flow Operating Activities"

gen CORP_TAX = provisionforincometaxes / netincomebeforetaxes
label var CORP_TAX "Corporate Tax"

sort code
by code: gen sales_lagged =  totalrevenue[_n-1]
gen SALES = (totalrevenue - sales_lagged)/ sales_lagged
label var SALES "SALES Growth"
drop sales_lagged

gen PTB = companymarketcap / totalequity
label var PTB "Price to Book"

gen DTE = totalliabilities / totalequity
label var DTE "Debt to Equity"

gen SIZE = ln(totalassetsreported)
label var SIZE "SIZE"

gen LIFE_CYCLE = retainedearningsaccumulateddefic / totalequity
label var LIFE_CYCLE "Life Cycle Stage"

// 1.6. Generating the dependent variable

by code: gen RE_lagged = retainedearningsaccumulateddefic[_n-1]
gen div = RE_lagged + netincomeaftertaxes - retainedearningsaccumulateddefic
label var div "Dividend"
replace div = 0 if div< 0 // drop negative dividends because no economic sense
drop RE_lagged

gen std_div = div / netincomeaftertaxes
label var std_div "Dividend Payout"

sum std_div, d
hist std_div, norm

gen ln_div = ln(div)
label var ln_div "Log Dividend"

gen ln_ni = ln(netincomeaftertaxes)
label var ln_ni "Log Net Income After Tax"

gen ln_dp = ln_div - ln_ni
label var ln_dp "Log Dividend Payout"

// 1.7. Data preparation

drop if div == .
drop if ln_dp == .

sum ln_dp, d
hist ln_dp, norm

// 1.8. Winsorising and dropping outliers

winsor ln_dp, gen(WLN_DP) p(0.075)
label var WLN_DP "Winsorized Log Dividend Payout"
sum WLN_DP, d
drop if WLN_DP < -2.620737 | WLN_DP >  .9130048

// 1.9. Generating dummy variable to control for the financial crisis

gen fincrisis = 0
replace fincrisis =1 if year >= 2008 & year<= 2009
label var fincrisis "Financial Crisis"
sum fincrisis
tab year fincrisis
ttest WLN_DP, by(fincrisis)

// 1.10. Dropping less than 8 observations per firm

gen a = 1
sort code
by code: egen obs = count(a)
tab obs

drop if obs < 8
tab obs
drop a obs

egen id = group(code)
sort id
move id code


// PART 2: EMPIRICAL ANALYSIS

// 2.1. Descriptive statistics

sum id
sum PROF CF CORP_TAX SALES PTB DTE SIZE LIFE_CYCLE
sum WLN_DP, d 

// 2.2. Some data visualisation

histogram WLN_DP, normal

twoway scatter PROF WLN_DP
twoway scatter CF WLN_DP
twoway scatter CORP_TAX WLN_DP
twoway scatter SALES WLN_DP
twoway scatter PTB WLN_DP
twoway scatter DTE WLN_DP
twoway scatter SIZE WLN_DP
twoway scatter LIFE_CYCLE WLN_DP

qnorm WLN_DP
pnorm WLN_DP
graph box WLN_DP

// 2.3. Baseline regression (and analysis of residuals for each regression)

reg WLN_DP PROF CF CORP_TAX SALES PTB DTE SIZE LIFE_CYCLE

predict r1, rstudent

stem r1
sort r1
list WLN_DP r1 in 1/10

lvr2plot, mlabel(WLN_DP)
kdensity r1, normal 
pnorm r1

graph box r1

swilk r1

* Residuals are not normal. Multicollinearity

corr PROF CF CORP_TAX SALES PTB DTE SIZE LIFE_CYCLE
pwcorr PROF CF CORP_TAX SALES PTB DTE SIZE LIFE_CYCLE, star(.5)
vif

* Reg. without (least significant) multicollinear variables: PTB and SIZE

reg WLN_DP PROF CF CORP_TAX SALES DTE LIFE_CYCLE

predict r2, rstudent

stem r2
sort r2
list WLN_DP r2 in 1/10

lvr2plot, mlabel(WLN_DP)
kdensity r2, normal 
pnorm r2

graph box r2

swilk r2

* Breusch-Pagan test for heteroskedasticity

estat hettest, iid

* Robust reg.

reg WLN_DP PROF CF CORP_TAX SALES DTE LIFE_CYCLE, robust

predict r4, residuals

stem r4
sort r4
list WLN_DP r4 in 1/10

kdensity r4, normal 
pnorm r4

graph box r4

swilk r4

* Reg. without SALES (not significant)

reg WLN_DP PROF CF DTE LIFE_CYCLE, robust

predict r5, residuals

stem r5
sort r5
list WLN_DP r5 in 1/10

kdensity r5, normal 
pnorm r5

graph box r5

swilk r5

// 2.4. Testing the dependent variable

kdensity WLN_DP, normal
sktest WLN_DP
sktest WLN_DP, noadjust
swilk WLN_DP
sfrancia WLN_DP

// 2.5. Testing the independent variables

quietly reg WLN_DP PROF CF CORP_TAX SALES PTB DTE SIZE LIFE_CYCLE, robust

* Multicollinearity

pwcorr PROF CF CORP_TAX SALES PTB DTE SIZE LIFE_CYCLE, star(.5)
vif

* Baseline model: no PTB and SIZE (multicollinear), no SALES (not significant)

quietly reg WLN_DP PROF CF CORP_TAX DTE LIFE_CYCLE, robust

* Wald test

test PROF CF CORP_TAX DTE LIFE_CYCLE

* Ramsey test

ovtest

* Link test

linktest

* Hausman test

xtset id year
xtreg WLN_DP PROF CF CORP_TAX DTE LIFE_CYCLE, fe
estimate store fixed
xtreg WLN_DP PROF CF CORP_TAX DTE LIFE_CYCLE, re
hausman fixed ., sigmamore

// 2.6. Models comparison (using library asdoc)

ssc install asdoc, update

asdoc reg WLN_DP PROF CF CORP_TAX SALES PTB DTE SIZE LIFE_CYCLE, robust add(Year, no, Firm, no, Industry, no, Country, no) save(Model selection) nest stat(r2_a, F) cnames(Pooled OLS) replace

asdoc reg WLN_DP PROF CF CORP_TAX SALES DTE LIFE_CYCLE, robust add(Year, no, Firm, no, Industry, no, Country, no) save(Model selection) nest stat(r2_a, F) cnames(Pooled OLS)

asdoc reg WLN_DP PROF CF CORP_TAX DTE LIFE_CYCLE, robust add(Year, no, Firm, no, Industry, no, Country, no) save(Model selection) nest stat(r2_a, F) cnames(Pooled OLS)

asdoc reg WLN_DP PROF CF CORP_TAX DTE LIFE_CYCLE, cluster(trbceconomicsectorname) robust add(Year, no, Firm, no, Industry, no, Country, no) save(Model selection) nest stat(r2_a, F) cnames(Clusters by economic sector)

asdoc reg WLN_DP PROF CF CORP_TAX DTE LIFE_CYCLE i.year, robust add(Year, yes, Firm, no, Industry, no, Country, no) drop(i.year) save(Model selection) nest stat(r2_a, F) cnames(Fixed effects)

asdoc reg WLN_DP PROF CF CORP_TAX DTE LIFE_CYCLE i.id, robust add(Year, no, Firm, yes, Industry, no, Country, no) drop(i.id) save(Model selection) nest stat(r2_a, F) cnames(Fixed effects)

asdoc reg WLN_DP PROF CF CORP_TAX DTE LIFE_CYCLE i.id i.year, robust add(Year, yes, Firm, yes, Industry, no, Country, no) drop(i.year i.id) save(Model selection) nest stat(r2_a, F) cnames(Fixed effects)

asdoc reg WLN_DP PROF CF CORP_TAX DTE LIFE_CYCLE i.id i.year i.countryofheadquarters i.trbceconomicsector, robust add(Year, yes, Firm, yes, Industry, yes, Country, yes) drop(i.id i.year i.trbceconomicsector i.countryofheadquarters) save(Model selection) nest stat(r2_a, F) cnames(Fixed effects)

xtset id year
asdoc xtreg WLN_DP PROF CF CORP_TAX DTE LIFE_CYCLE, re robust add(Year, no, Firm, no, Industry, no, Country, no) save(Model selection) nest stat(r2_a, F) cnames(Random effects)

asdoc xtscc WLN_DP PROF CF CORP_TAX DTE LIFE_CYCLE, add(Year, no, Firm, no, Industry, no, Country, no) save(Model selection) nest stat(r2_a, F) cnames(Driscoll-Kraay)

save "De Gaspari, Paoletti, Veggiato.dta", replace
