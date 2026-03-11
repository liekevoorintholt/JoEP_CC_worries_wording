********************************************************************************
*** This is the master file for the replication of the empirical results in the article "Measuring worries about climate change: the effect of a subtle wording change" by Lieke Voorintholt, Adriaan R. Soetevent, and Gerard J. van den Berg.
*** Replication do-files by Lieke Voorintholt.

*** This do file and its subsidiary do files can be executed with (at least) stata versions 17.0 and higher.
*** The do-file "data_preparation" reads extracts the data we use from the raw data in the Understanding Society folder, and prepares them for the analyses.
*** The do-file "analysis" performs all the analyses reported in the paper.
********************************************************************************

*** Clear all
	clear all

*** Stata version
	version 17.0		// can be edited

*** Edit screen settings
	set more off

*** Abbreviations off
	set varabbrev off, perm

***	Set paths
	global datapath   	"" 												// here: path to folder were the source data set (retrieved from http://doi.org/10.5255/UKDA-SN-6849-17) is stored
	global outputpath   "" 												// here: save output 
	global newdatapath 	"" 												// here: save new/intermediate data sets
	global dofilepath   "" 												// here: dofiles 
	global outputname 	"JoEP_climate_worries_wording" 					// Name of log-file 

*** Manage log
	capture log close	

*******************************************************************************************

* To replicate the dataset:
	do "$dofilepath/data_preparation.do"
	
* To replicate the analyses:
	do "$dofilepath/analysis.do"

exit
