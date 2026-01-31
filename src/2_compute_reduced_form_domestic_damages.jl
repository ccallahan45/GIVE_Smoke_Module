using Pkg

# activate and instantiate environment
Pkg.activate(joinpath(@__DIR__, ".."))
Pkg.instantiate() # only need to run this once per machine

using Mimi
using MimiGIVE 
using DataFrames
using Query
using Random
using Parquet
using Distributions

include("constants.jl")
include("main_model.jl")
include("mcs.jl")

# number of monte carlo trials
num_trials = 10

# get fair and rffsp trials (rffsp_fair_sequence comes from constants.jl)
fair_parameter_set_ids = rffsp_fair_sequence[1:num_trials, "fair_id"]
rffsp_sampling_ids     = rffsp_fair_sequence[1:num_trials, "rffsp_id"]

# list emissions years
years = [2020] # any year from 2020 to 2300

# list gases
gases = [:CO2]

# list which CRF to use
smoke_crf = ["2part","binned","totalPM"] # "binned" or "totalPM" or "2part"

# choose which fire-fuel feedback setting to use
feedbacks = ["baseline","dynamic"] # "baseline" or "dynamic"

# choose which polynomial the damage function uses
polynums = [2,4] # 2 for quadratic, 4 for 4th degree polynomial

# choose the model variables and paramters that you would like to save (can be left empty)
save_list = [
                (:global_netconsumption, :net_consumption), # Global net per capita consumption in US\$2005/yr/person
                (:Smoke, :temperature), # Global average surface temperature anomaly relative to pre-industrial (°C)
                (:DamageAggregator, :total_damage_domestic) # US\$2005/yr
            ]

# run 
for year in years, gas in gases, smokecrf in smoke_crf, polynum in polynums, feedback in feedbacks

    # print into console
    println("Now running the mcs for $(gas) in $(year) with $(smokecrf) smoke crf, $(polynum)-order polynomial, and $(feedback) fire-fuel feedback")

    m = get_smoke_model(; smoke_damages_crf = smokecrf, polynomial = polynum, feedback = feedback)

    # specify output directory even if save_list (above) is empty
    output_dir = joinpath(@__DIR__, "../output/reduced_form_domestic_damages/$(gas)-$(year)-$(smokecrf)-poly$(polynum)-$(feedback)")
    mkpath(output_dir)

    # set random seed
    Random.seed!(seed)

    run_smoke_mcs(
                    trials = num_trials,
                    output_dir = output_dir,
                    fair_parameter_set         = :deterministic,         
                    fair_parameter_set_ids     = fair_parameter_set_ids, 
                    rffsp_sampling             = :deterministic,
                    rffsp_sampling_ids         = rffsp_sampling_ids,
                    m = m,
                    save_list = save_list,
                    results_in_memory = false
    );    
end
