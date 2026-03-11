********************************** Data analysis ********************************** 
/*
********************************** Instructions ************************************** 	
	
	Objective of this dofile: Complete analysis code to replicate Voorintholt, Soetevent, and Van den Berg (2026).

	Outline of this dofile: 
		a) Set-up the data
		b) Table 2: Descriptive statistics and balance
		c) Figure 1: Distribution of climate change worries by treatment
		d) Figure 2: Mean and 95% confidence interval for proportion of treated by answer option
		e) Table 3: Wording effect on climate change worries interacted with relevant demographics
		f) Table 4: Seconds spent on worries question regressed on treatment status and response
		g) Appendix Table B1: Heterogeneity in age
		h) Table B2: Wording effect on climate change worries interacted with voting behavior
		i) Appendix Table B3: Wording effect on climate change worries interacted with response times
*/

********************************************************************************
*a) Set up the data
********************************************************************************

use $newdatapath/dataset.dta, clear // load dataset

*crucial analysis vars
 drop if treat_about == . | cc_worries == .

*choose controls
global controls "female parent working livespouse above_med_health below_med_health" 
foreach var of global controls {
    drop if missing(`var')
}
 global controls "female parent working livespouse above_med_health below_med_health i.indmode" 

********************************************************************************
*b) Table 2: Descriptive statistics and balance
********************************************************************************
global controls_desc "female parent working_desc livespouse sphus high_educ_desc urban_dv"

	* Column "Control"	
		eststo: estpost sum $controls_desc CRT2 age if treat_about==0
				estimates store modela
	* Column "Treatment"
		eststo: estpost sum $controls_desc CRT2 age if treat_about==1
				estimates store modelb
	* Column "T-test"
		eststo: estpost ttest $controls_desc  CRT2 age, by(treat_about)
				estimates store model1
		
esttab modela modelb model1, ///
cells("mean(pattern(1 1 0 ) fmt(2)) b(star pattern(0 0 1) fmt(2)) count(pattern(1 1 0 ) fmt(0))" "sd(pattern(1 1 0 ) par)  se(pattern(0 0 1 ) par)") ///
mtitle("C" "T" "C-T") ///
nonumbers  label nogaps noobs booktabs

eststo clear

* test balance using F statistic
reg treat_about $controls_desc  CRT2 age 

* other tests of balance
foreach var in female parent working_desc livespouse sphus high_educ_desc urban_dv CRT2 age {
	qui reg `var' treat_about
	est sto reg_`var'
}

suest reg_female reg_parent reg_working_desc reg_livespouse reg_sphus reg_high_educ_desc reg_urban_dv reg_CRT2 reg_age

qui test [reg_female_mean]treat_about = 0
qui test [reg_parent_mean]treat_about = 0, accum 
qui test	[reg_working_desc_mean]treat_about = 0, accum 
qui test [reg_livespouse_mean]treat_about = 0, accum 
qui test     [reg_sphus_mean]treat_about = 0, accum 
qui test     [reg_high_educ_desc_mean]treat_about = 0, accum 
qui test     [reg_urban_dv_mean]treat_about = 0, accum 
qui test     [reg_CRT2_mean]treat_about = 0, accum 
test     [reg_age_mean]treat_about = 0, accum 

eststo clear

********************************************************************************
*c) Figure 1: Distribution of climate change worries by treatment
********************************************************************************
gen group_worries = cc_worries + 0.25 * treat_about
label variable group_worries " "
	
twoway  (histogram group_worries if treat_about==0 & age2grp == 1,  fraction discrete width(0.5)  lwidth(none) fcolor(cranberry%90) barwidth(0.25) ) ///
        (histogram group_worries if treat_about==1 & age2grp == 1,  fraction discrete width(0.5)  lwidth(none) fcolor(eltgreen%90) barwidth(0.25)), ///
    ylabel(0 "0" 0.1 "0.1" 0.2 "0.2" 0.3 "0.3" 0.4 "0.4" ) ///
	xlabel(1.125 "1" 2.125 "2" 3.125 "3" 4.125 "4" 5.125 "5") ///
legend(order(1 "Control" 2 "Treatment")) xtitle(Climate change worries)

********************************************************************************
*d) Figure 2: Mean and 95% confidence interval for proportion of treated by answer option
********************************************************************************

preserve
statsby, by(cc_worries) clear : ci proportions treat_about
twoway ///
    bar mean cc_worries, horizontal barw(0.6) bfcolor(green*0.2) ///
    || rcap lb ub cc_worries, horizontal ///
    legend(off) ///
    xla(0(0.1)0.6, format(%02.1f)) ///
    xline(0.5) xtitle("Proportion of treated")
*subtitle(Mean and 95% confidence intervals for proportion of treated by answer option)
restore

********************************************************************************
*e) Table 3: Wording effect on climate change worries interacted with relevant demographics
********************************************************************************
* column 1
	qui reg cc_worries 1.treat_about, robust
	eststo model1
	estadd local hasrep "No"
* column 2
	qui reg cc_worries 1.treat_about $controls i.age2grp, robust
	eststo model2
	estadd local hasrep "Yes"
* column 3
	qui reg cc_worries 1.treat_about 1.treat_about#1.btw36_55 1.treat_about#1.btw56_65 1.treat_about#1.plus66 i.age2grp $controls, robust
	eststo model3
	estadd local hasrep "Yes"
* column 4
	qui reg cc_worries 1.treat_about $controls 1.treat_about#1.female i.age2grp, robust
	eststo model4
	estadd local hasrep "Yes"
* column 5
	qui reg cc_worries 1.treat_about $controls 1.treat_about#1.parent i.age2grp, robust
	eststo model5
	estadd local hasrep "Yes"

esttab model1 model2 model3 model4 model5, scalars("hasrep Controls") collabels(none) keep(1.treat_about 1.treat_about#1.btw36_55 1.treat_about#1.btw56_65 1.treat_about#1.plus66 1.treat_about#1.female 1.treat_about#1.parent _cons) cells(b(star  fmt(2)) se(par  fmt(2))) obslast label title("OLS estimates of wording effect") starlevels(* 0.05 ** 0.01 *** 0.001)

eststo clear

********************************************************************************
*f) Table 4: Seconds spent on worries question regressed on treatment status and response
********************************************************************************
* column 1
	qui reg time_scenv_nowo_w treat_about, robust
	eststo model1
	estadd local hasrep "No"
* column 2
	qui reg time_scenv_nowo_w treat_about $controls, robust
	eststo model2
	estadd local hasrep "Yes"
* column 3
	qui reg time_scenv_nowo_w treat_about cc_worries , robust
	eststo model3
	estadd local hasrep "No"
* column 4
	qui reg time_scenv_nowo_w treat_about cc_worries  $controls, robust
	eststo model4
	estadd local hasrep "Yes"


esttab model1 model2 model3 model4, scalars("hasrep Controls") collabels(none) keep(treat_about cc_worries) cells(b(star  fmt(2)) se(par  fmt(2))) obslast label title("OLS estimates of wording effect") starlevels(* 0.05 ** 0.01 *** 0.001) 

eststo clear

********************************************************************************
*g) Appendix Table B1: Heterogeneity in age
********************************************************************************
	*columns 1-4
	qui reg cc_worries 1.treat_about $controls if age2grp==1, robust
		eststo model1
		estadd local hasrep "Yes"
qui reg cc_worries 1.treat_about $controls if age2grp==2, robust		
		eststo model2
		estadd local hasrep "Yes"
qui reg cc_worries 1.treat_about $controls if age2grp==3, robust
		eststo model3
		estadd local hasrep "Yes"
qui reg cc_worries 1.treat_about $controls if age2grp==4, robust
		eststo model4
		estadd local hasrep "Yes"
	* column 5
	qui reg cc_worries 1.treat_about 1.treat_about#c.age 1.treat_about#c.age_sq  $controls age age_sq, robust
		eststo model5
	estadd local hasrep "Yes"
	
esttab model1 model2 model3 model4 model5, scalars("hasrep Controls") collabels(none) keep(1.treat_about 1.treat_about#c.age  1.treat_about#c.age_sq  _cons) cells(b(star  fmt(2)) se(par  fmt(2))) obslast label  starlevels(* 0.05 ** 0.01 *** 0.001) 

* p-value final paragraph page 10
qui reg cc_worries i.treat_about##i.age2grp, robust
test (1.treat_about#4.age2grp + 1.treat_about#1.age2grp = 1.treat_about#2.age2grp + 1.treat_about#3.age2grp) // p-value footnote 8

eststo clear

********************************************************************************
*h) Table B2: Wording effect on climate change worries interacted with voting behavior
********************************************************************************
* column 1
	qui reg cc_worries 1.treat_about $controls i.age2grp if party!=., robust
	eststo model1
	estadd local hasrep "Yes"
* column 2
	qui reg cc_worries 1.treat_about $controls b1.party 1.treat_about#b1.party i.age2grp, robust
	eststo model2
	estadd local hasrep "Yes"
testparm i.treat_about#i.party
* column 3
	qui reg cc_worries 1.treat_about $controls i.age2grp if leave_ref!=., robust
	eststo model3
	estadd local hasrep "Yes"
* column 4
	qui reg cc_worries 1.treat_about $controls b1.leave_ref 1.treat_about#b1.leave_ref i.age2grp, robust
	eststo model4
	estadd local hasrep "Yes"
testparm i.treat_about#i.leave_ref


esttab model1 model2 model3 model4, scalars("hasrep Controls") collabels(none)  cells(b(star  fmt(2)) se(par  fmt(2))) obslast label title("OLS estimates of wording effect") starlevels(* 0.05 ** 0.01 *** 0.001) keep(1.treat_about 1.treat_about#2.party 1.treat_about#3.party 1.treat_about#4.party 1.treat_about#5.party 1.treat_about#0.leave_ref 1.treat_about#2.leave_ref _cons)

eststo clear

********************************************************************************
*i) Appendix Table B3: Wording effect on climate change worries interacted with response times
********************************************************************************
*column 1
qui reg cc_worries 1.treat_about 1.treat_about#1.slow_cc 1.slow_cc  $controls i.age2grp, robust
	eststo model1
	estadd local hasrep "Yes"
*column 2
qui reg cc_worries 1.treat_about $controls 1.treat_about#1.slow 1.slow i.age2grp, robust
	eststo model2
	estadd local hasrep "Yes"

esttab model1 model2, scalars("hasrep Controls") collabels(none) keep(1.treat_about 1.treat_about#1.slow_cc 1.treat_about#1.slow _cons) cells(b(star  fmt(2)) se(par  fmt(2))) obslast label title("OLS estimates of wording effect")  starlevels(* 0.05 ** 0.01 *** 0.001) 

eststo clear

*** EXTRA: distribution of seconds spent
twoway (histogram time_scenv_nowo_w if treat_about==0, start(0) width(5) color(pink%70)) ///        
       (histogram time_scenv_nowo_w if treat_about==1, start(0) width(5) color(teal%70)), ///   
       legend(order(1 "Control" 2 "Treatment" ))
