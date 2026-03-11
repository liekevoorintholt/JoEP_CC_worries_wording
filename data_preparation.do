********************************** Data preparation ********************************** 
/*
********************************** Instructions ************************************** 	
	
	Objective of this dofile: Generate dataset for Voorintholt, Soetevent, and Van den Berg (2026).
	Original datasets used: p_indresp_ip.dta, p_hhsamp_ip.dta, p_indint_timings.csv

	Outline of this dofile: 
		a) Load the relevant dataset and variables
		b) Merge with treatment status file and time stamps
		c) Generate climate change worry outcome
		d) Generate CRT-2 score
		e) Generate controls and descriptive variables
		f) Time spent on questions and overall survey
		g) Compress and save dataset
*/

********************************************************************************
*a) Load the relevant dataset and variables
********************************************************************************
	// (i) Generate timestamp file
import delimited "$datapath/csv/p_indint_timings.csv", varnames(1) clear
save $newdatapath/timestamps.dta, replace

	// (ii) Open main data and extract the variables needed
use pidp p_pno p_hidp p_sex p_pdvage p_livesp_dv p_nchildlv p_health p_hiqual_dv p_scenv_nowo p_scenv_nowoexp p_scacearly p_urban_dv ///
p_jbstat p_vote7 p_vote8 p_voteeuref p_euref p_lprnt p_ladopted2 p_lprntadp2 p_jbhas p_jboff p_scsf1 p_isced11_dv p_finnow p_indmode ///
p_indstimehh p_indstimemm p_indendtimehh p_indendtimemm ///
using $datapath/p_indresp_ip.dta, clear

********************************************************************************
*b) Merge with treatment status file and time stamps
********************************************************************************

	// (i) import household-level treatment status
merge m:1 p_hidp using $datapath/p_hhsamp_ip.dta, keepusing(p_ff_climatechangew16) gen(merge_exp)
drop if merge_exp == 2 			// remove if no such status

	// (ii) create a wave variable
	gen wave = 16
	
	// (iii) drop the wave prefix from all variables that had one 
mvdecode _all, mv(-9/-1)
merge 1:1 pidp using $datapath/p_indresp_ip.dta, keepusing(p_scacrt2acor p_scacrt2b p_scacrt2ccor p_scacrt2d ///
p_scenv_nowo p_scenv_nowoexp ) nogen
mvdecode _all, mv(-9/-3) 		// for vars above, keep "don't know" and refusal labels
rename p_* * 					// remove prefix

	// (iii)  Merge with time stamps
merge 1:1 pidp using $newdatapath/timestamps.dta, keepusing(scaclmchgeexp_ip16_scenv_nowo scaclmchgeexp_ip16_scenv_nowoexp) nogen

********************************************************************************
*c) Generate climate change worry outcome
********************************************************************************
* generate single outcome variable
gen cc_worries = scenv_nowo
replace cc_worries =  scenv_nowoexp if cc_worries == .
label variable cc_worries "CC worries"

* generate treatment status indicator
gen treat_about = 1 if ff_climatechangew16 == 2
replace treat_about = 0 if ff_climatechangew16 ==1
label variable treat_about "Treatment"

* binary version
gen cc_worries_bin = (cc_worries > 3) if cc_worries != .

* time spent on CC worries question
rename scaclmchgeexp_ip16_scenv_nowo time_scenv_nowo
replace time_scenv_nowo = scaclmchgeexp_ip16_scenv_nowoexp if time_scenv_nowo == .
drop scaclmchgeexp_ip16_scenv_nowoexp
gen log_time_scenv_nowo = log(time_scenv_nowo)

********************************************************************************
*d) Generate CRT-2 score
********************************************************************************
* mark as correct of incorrect per question
gen crt2_a_corr = (scacrt2acor == 1) if !missing(scacrt2acor)
gen crt2_c_corr = (scacrt2ccor == 1) if !missing(scacrt2ccor)
gen crt2_b_corr = (scacrt2b == 7) if !missing(scacrt2b)
gen crt2_d_corr = (scacrt2d == 0) if !missing(scacrt2d)

* total correct
egen CRT2 = rowtotal(crt2_a_corr crt2_b_corr crt2_c_corr crt2_d_corr), missing // includes all individuals who started the module (N-34 missings)
label variable CRT2 "CRT-2 score"

* at least two questions correct
gen CRT2_bin = (CRT2 > 1) if !missing(CRT2)
label variable CRT2_bin "CRT-2 at least 2/4 correct"

/*
gen CRT2_frc = CRT2 / 4
label var CRT2_frc "Fraction CRT-2 correct"
*/

********************************************************************************
*e) Generate controls and descriptive variables
********************************************************************************
gen female = sex - 1
label var female "Female"

* age and age squared
gen age_sq = pdvage^2
gen age = pdvage
label var age "Age"

* 7 age groups
recode pdvage 16/25 = 1 26/35 = 2 36/45=3 46/55=4 56/65=5 66/75=6 76/95=7, gen(agegrp)
label define agegroups 1 "16-25" 2 "26-35" 3 "36-45" 4 "46-55" 5 "56-65" 6 "66-75" 7 "76+" 
label values agegrp agegroups
* 4 age groups
gen min35 = (pdvage <= 35) if pdvage !=.
gen btw36_55 = (pdvage <= 55 & pdvage>35) if pdvage !=.
gen btw56_65 = (agegrp == 5)
gen plus66 = (pdvage >= 66) if pdvage !=.
recode agegrp (1 = 1) (2 = 1) (3 = 2) (4 = 2) (5 = 3) (6 = 4) (7 = 4), gen(age2grp)

* parental status
gen parent = (nchildlv > 0) if nchildlv != .
replace parent = 1 if lprnt == 1
replace parent = 1 if ladopted2 ==1
replace parent = 1 if lprntadp2 ==1
label var parent "Parent"

* working indicator
gen working = 1 if jbhas==1|jboff==1
replace working = 0 if jbhas==2 & jboff==2 // 41 missings
*fixes for missing values
gen working_desc = working
label var working_desc "Working"
replace working = 2 if working == .
gen working_missing = 1 if working == 2
replace working_missing = 0 if working_missing == .

* health status
vreverse scsf1, gen(sphus) 
	tab sphus, generate(health)
label var health5 "\quad Excellent"
label var health4 "\quad Very good"
label var health3 "\quad Good"
label var health2 "\quad Fair"
label var health1 "\quad Poor"
rename health con_health

gen below_med_health = (sphus==1|sphus==2) if sphus!=.
gen above_med_health = (sphus==4|sphus==5) if sphus!=.
* fixes for missing values
gen below_med_health_desc = below_med_health
gen above_med_health_desc = above_med_health
gen med_health_desc = (sphus==3) if sphus!=.
replace below_med_health = 2 if sphus == .
replace above_med_health = 2 if sphus == .
gen health_missing = 1 if sphus == .
replace health_missing = 0 if sphus !=.
label var below_med_health_desc "Poor or fair health"
label var above_med_health_desc "Very good or excellent health"
label var med_health_desc "Good health"

* cohabitation with spouse
rename livesp_dv livespouse
replace livespouse = 2 if livespouse == .
gen spouse_missing = 1 if livespouse == 2
replace spouse_missing = 0 if livespouse != 2

* voting outcomes
gen voted = (vote7 == 1) if !missing(vote7)
gen conservative = 0 if vote8 == 2 					// labour
replace conservative = 1 if vote8 == 1
gen party = 1 if vote8 == 2 						// labour
replace party = 2 if vote8 == 1 					// conservative
replace party = 3 if vote8 == 3 					// libdem
replace party = 4 if vote8 > 3 & vote8!= . 			// other
replace party = 5 if vote7 == 2 | vote7 == 3 		// no vote
* leave referendum
gen leave_ref = 1 if voteeuref == 2 				// leave
replace leave_ref = 0 if voteeuref == 1 			// remain
replace leave_ref = 2 if euref == 2 | euref == 3 	// no vote
* binary versions
gen party_labour_bin = .
replace party_labour_bin = 0 if party == 2
replace party_labour_bin = 1 if party == 1
gen ref_leave_bin = leave_ref
replace ref_leave_bin = . if leave_ref == 2

* education level
gen high_educ = (hiqual_dv == 1 | hiqual_dv == 2) if hiqual_dv != .
replace high_educ = 1 if isced11_dv == 6
replace high_educ = 0 if isced11_dv < 6 & isced11_dv !=.
*fixes for missing values
gen high_educ_desc = high_educ
replace high_educ = 2 if high_educ == .
gen high_educ_missing = 1 if high_educ == 2
replace high_educ_missing = 0 if high_educ != 2
label var high_educ_desc "Highly educated"
label var high_educ "Highly educated"

* financial worries
gen fin_worries = 1 if finnow >= 3 & finnow !=.
replace fin_worries = 0 if finnow == 1 | finnow == 0

********************************************************************************
*f) Time spent on questions and overall survey
********************************************************************************
gen diff_hrs = indendtimehh - indstimehh 
replace indendtimehh = indendtimehh +24 if indendtimehh < indstimehh

gen diff_min = indendtimemm - indstimemm
gen total_min = 60*diff_hrs + diff_min

* survey level slow indicator
by treat_about, sort : centile total_min, centile(50)
gen slow = 1 if total_min >= 40 & total_min!=.
replace slow = 0 if total_min < 40 & total_min !=.

* question level slow indicator
by treat_about, sort : centile time_scenv_nowo, centile(50)
gen slow_cc = 1 if time_scenv_nowo >=14 & time_scenv_nowo !=.
replace slow_cc = 0 if time_scenv_nowo < 14 & time_scenv_nowo !=.

* winsorized
*ssc install winsor2
winsor2 time_scenv_nowo , cuts(1 99) suffix(_w)
		
********************************************************************************
*g) Compress and save dataset
********************************************************************************
compress
save "$newdatapath/dataset.dta", replace