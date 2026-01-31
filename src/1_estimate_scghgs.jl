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

include("constants.jl")
include("main_model.jl")
include("mcs.jl")
include("scc.jl")

# number of monte carlo trials
num_trials = 10_000

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
                (:Smoke, :bootid),
                (:Smoke, :temperature),
                (:Smoke, :excess_deaths_usa)
            ]

# run
for year in years, gas in gases, smokecrf in smoke_crf, polynum in polynums, feedback in feedbacks

    # print into console
    println("Now estimating SC-$(gas) in $(year) with $(smokecrf) smoke crf, $(polynum)-order polynomial, and $(feedback) fire-fuel feedback")

    m = get_smoke_model(; smoke_damages_crf = smokecrf, polynomial = polynum, feedback = feedback)
    #update_param!(m, :DamageAggregator, :include_slr, false) # turning off sea level rise damages computatoin significantly improves speed for iterative testing

    # specify output directory even if save_list (above) is empty
    output_dir = joinpath(@__DIR__, "../output/save_list/$(gas)-$(year)-$(smokecrf)-poly$(polynum)-$(feedback)")
    mkpath(output_dir)

    # set random seed
    Random.seed!(seed)

    results = 
        compute_smoke_scc(m;
                n                          = num_trials,
                gas                        = gas,
                year                       = year,
                pulse_size                 = 1e-4,
                discount_rates             = global_discount_rates,
                last_year                  = 2300,
                certainty_equivalent       = false,
                output_dir                 = output_dir,
                save_list                  = save_list,
                save_md                    = false, 
                save_cpc                   = false,
                save_slr_damages           = false,
                compute_sectoral_values    = true,
                compute_domestic_values    = true,
                CIAM_foresight             = :perfect,
                CIAM_GDPcap                = true,
                fair_parameter_set         = :deterministic,         
                fair_parameter_set_ids     = fair_parameter_set_ids, 
                rffsp_sampling             = :deterministic,
                rffsp_sampling_ids         = rffsp_sampling_ids,
        );


    # initialize empty DataFrame to hold full distribution of scghgs
    scghgs = DataFrame(region = String[], sector = String[], discount_rate = String[], trial = Int[], scghg = Float64[]);
        
    # populate DataFrame
    for (k, v) in results[:scc]
        for (i, sc) in enumerate(v.sccs)
            push!(scghgs, (region = String(k.region), sector = String(k.sector), discount_rate = k.dr_label, trial = i, scghg = sc * pricelevel_2005_to_2020))
        end
    end

    # export full distribution
    mkpath(joinpath(@__DIR__, "../output/scghgs/full_distributions"))
    Parquet.write_parquet(joinpath(@__DIR__, "../output/scghgs/full_distributions/smoke_mortality_sc-$(gas)_$(year)pulse_$(smokecrf)crf_$(polynum)poly_$(feedback)_lag1.parquet"), scghgs)

    # collapse to the expected scghgs
    scghgs_mean = combine(groupby(scghgs, [:region, :sector, :discount_rate]), :scghg => (x -> mean(x)) .=> :scghg)

    # export expected scghgs    
    scghgs_mean |> save(joinpath(@__DIR__, "../output/scghgs/smoke_mortality_sc-$(gas)_$(year)pulse_$(smokecrf)crf_$(polynum)poly_$(feedback)_lag1.csv"));

end
