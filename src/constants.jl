using CSVFiles, DataFrames

## constant values that are consistent across modules and analyses

## GIVE results are in 2005 USD, this is the price deflator to bring the results to 2020 USD. accessed 09/13/2022. source: https://apps.bea.gov/iTable/iTable.cfm?reqid=19&step=3&isuri=1&select_all_years=0&nipa_table_list=13&series=a&first_year=2005&last_year=2020&scale=-99&categories=survey&thetable=
const pricelevel_2005_to_2020 = 113.648 / 87.504

# named global discount rates
const global_discount_rates = 
[
    (label = "1.5% Ramsey", prtp = exp(0.000091496)-1, eta  = 1.016010261),
    (label = "2.0% Ramsey", prtp = exp(0.001972641)-1, eta  = 1.244459020),
    (label = "2.5% Ramsey", prtp = exp(0.004618785)-1, eta  = 1.421158057),
    (label = "3.0% Ramsey", prtp = exp(0.007702711) - 1, eta = 1.567899391)
];

# named domestic discount rates
const domestic_discount_rates = 
[
    (label = "1.5% Ramsey", prtp = 0.002240666, eta  = 0.799171833),
    (label = "2.0% Ramsey", prtp = 0.004064562, eta  = 1.016812824),
    (label = "2.5% Ramsey", prtp = 0.006510474, eta  = 1.198549413),
    (label = "3.0% Ramsey", prtp = 0.009465468, eta = 1.348861788)
];

# seed for random number generator (consistent within Julia versions)
const seed = 42

# read the series of rffsp-fair pairings, these were randomly selected pairings, please 
# read GIVE documentation for other functionality.
const rffsp_fair_sequence = load(joinpath(@__DIR__, "../data/rffsp_fair_sequence.csv")) |> DataFrame
