# Kaplan-Meier Survival Analysis Report Generator

This repository contains a SAS program designed to perform a Kaplan-Meier survival analysis on an ADTTE (Analysis Data for Time-to-Event) dataset. 
The script processes raw event data, calculates survival probabilities across three treatment arms, and generates a formatted PDF report.

## Features
- **Data Simulation:** Creates a sample ADTTE dataset with treatment arms (Placebo, Old Drug, New Drug).
- **Statistical Analysis:** Utilizes `PROC LIFETEST` to calculate Product-Limit Estimates.
- **Data Binning:** Maps event days to clinical visit windows (e.g., 3 Months, 6 Months, 1 Year).
- **Automated Reporting:** Uses `PROC REPORT` and ODS PDF to create a publication-quality table including:
    - Cumulative Deaths (Events)
    - Survival Probabilities
    - 95% Confidence Intervals (Calculated manually via stderr)

## Usage
1. Open the `.sas` file in SAS Studio, Enterprise Guide, or SAS 9.4.
2. Run the script.
3. The output will be saved as `KM_Survival_Table.pdf` in your default working directory.

## Requirements
- Base SAS
- SAS/STAT (for `PROC LIFETEST`)
