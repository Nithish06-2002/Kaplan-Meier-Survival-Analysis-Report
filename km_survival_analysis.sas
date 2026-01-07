/*-----------------------------------------------------------------------
  Program: km_survival_analysis.sas
  Purpose: Perform KM estimation and generate a formatted summary table.
-----------------------------------------------------------------------*/

/* 1. Create Sample ADTTE Data */
data adtte;
    label 
        trta = "Actual Treatment"
        aval = "Analysis Value (Days)"
        cnsr = "Censor Flag (1=Censored, 0=Event)";
        
    input trta $ aval cnsr @@;
datalines;
A 543 0  A 453 1  B 232 1  C 43 0
A 23 0   B 154 1  C 879 0  B 435 1
C 34 1   A 323 0  C 334 0  B 23 0
A 145 1  B 982 0  C 524 0  A 212 0
B 321 1  C 109 1  A 288 0  B 465 1
C 100 0  A 265 1  B 980 0  C 298 1
A 55 1   B 900 0  C 144 1  A 874 1
;
run;

/* 2. Run Kaplan-Meier Analysis */
ods listing close;
ods output ProductLimitEstimates = survivalest;

proc lifetest data=adtte method=km;
    time aval*cnsr(1);
    strata trta;
run;

ods listing;

/* 3. Assign Analysis Windows (Visits) */
data survivalest;
    set survivalest;

    if aval = 0 then visit = 0;
    else if 1 <= aval <= 91 then visit = 91;
    else if 92 <= aval <= 183 then visit = 183;
    else if 184 <= aval <= 365 then visit = 365;
    else if 366 <= aval <= 731 then visit = 731;
    else if 732 <= aval <= 1096 then visit = 1096;
    else visit = 1461;
run;

/* 4. Prepare Estimates for Reporting */
proc sort data=survivalest;
    by trta visit aval;
run;

data survivalest_final;
    set survivalest;
    by trta visit aval;

    retain survprob count lcl ucl;

    if first.trta then call missing(survprob, count, lcl, ucl);

    /* Capture survival and calculate 95% CI */
    if survival ne . then do;
        survprob = survival;
        count = failed;
        if visit ne 0 and stderr ne . then do;
            lcl = survival - (1.96 * stderr);
            ucl = survival + (1.96 * stderr);
        end;
    end;

    /* Keep only the last record per visit window */
    if last.visit;
    keep trta visit survprob count lcl ucl;
run;

/* 5. Transpose Data for Side-by-Side Treatment Comparison */
proc sort data=survivalest_final;
    by visit;
run;

data table_final;
    merge survivalest_final(where=(trta="A") rename=(count=count_a survprob=surv_a lcl=lcl_a ucl=ucl_a))
          survivalest_final(where=(trta="B") rename=(count=count_b survprob=surv_b lcl=lcl_b ucl=ucl_b))
          survivalest_final(where=(trta="C") rename=(count=count_c survprob=surv_c lcl=lcl_c ucl=ucl_c));
    by visit;
run;

/* 6. Define Formats for the Report */
proc format;
    value visitf
        0    = "Baseline"
        91   = "3 Months"
        183  = "6 Months"
        365  = "1 Year"
        731  = "2 Years"
        1096 = "3 Years"
        1461 = "4 Years";
run;

/* 7. Generate PDF Report */
ods pdf file="KM_Survival_Table.pdf" style=HTMLBlue;

proc report data=table_final nowd split="|";
    columns visit 
            ("Placebo" count_a surv_a lcl_a ucl_a)
            ("Old Drug" count_b surv_b lcl_b ucl_b)
            ("New Drug" count_c surv_c lcl_c ucl_c);

    define visit   / order format=visitf. "Analysis Visit";
    define count_a / display "Deaths";
    define surv_a  / display "Survival Prob" format=8.4;
    define lcl_a   / display "Lower 95% CI" format=8.4;
    define ucl_a   / display "Upper 95% CI" format=8.4;

    define count_b / display "Deaths";
    define surv_b  / display "Survival Prob" format=8.4;
    define lcl_b   / display "Lower 95% CI" format=8.4;
    define ucl_b   / display "Upper 95% CI" format=8.4;

    define count_c / display "Deaths";
    define surv_c  / display "Survival Prob" format=8.4;
    define lcl_c   / display "Lower 95% CI" format=8.4;
    define ucl_c   / display "Upper 95% CI" format=8.4;
run;

ods pdf close;
