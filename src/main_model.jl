using Mimi, MimiGIVE

include("components/smoke_damages.jl")
include("components/DamageAggregator_Smoke.jl")
include("components/Damages_RegionAggregatorSum_Smoke.jl")

function get_smoke_model(;  Agriculture_gtap::String = "midDF",
                            socioeconomics_source::Symbol = :RFF,
                            SSP_scenario::Union{Nothing, String} = nothing,       
                            RFFSPsample::Union{Nothing, Int} = nothing,
                            Agriculture_floor_on_damages::Bool = true,
                            Agriculture_ceiling_on_benefits::Bool = false,
                            vsl::Symbol = :epa,
                            smoke_damages_crf::String = "2part",
                            polynomial::Int = 2,
                            feedback::String = "baseline"
                        )

    # Obtain MimiGIVE model
    m = MimiGIVE.get_model(; Agriculture_gtap = Agriculture_gtap,
                            socioeconomics_source = socioeconomics_source,
                            SSP_scenario = SSP_scenario,
                            RFFSPsample = RFFSPsample,
                            Agriculture_floor_on_damages = Agriculture_floor_on_damages,
                            Agriculture_ceiling_on_benefits = Agriculture_ceiling_on_benefits,
                            vsl = vsl,
                        )

    # --------------------------------------------------------------------------
    # Add new components
    # --------------------------------------------------------------------------
    
    # Add smoke damages component
    add_comp!(m, smoke_damages, :Smoke, first = 2020, after = :CromarMortality)

    # Replace Regional Summation Damage Aggregator component with modified one
    replace!(m, :Damages_RegionAggregatorSum => Damages_RegionAggregatorSum_Smoke)

    # Replace Damage Aggregator component with modified one
    replace!(m, :DamageAggregator => DamageAggregator_Smoke)

    # Need to set this damage aggregator to run from 2020 to 2300, currently picks up
    # 1750 to 2300 from replace!
    Mimi.set_first_last!(m, :DamageAggregator, first=2020);
    Mimi.set_first_last!(m, :Damages_RegionAggregatorSum, first=2020);

    # --------------------------------------------------------------------------
    # Smoke PM2.5 mortality damages
    # --------------------------------------------------------------------------
    
    # Parameters and connections
    params = load(joinpath(@__DIR__, "..", "data","smoke_params","poly"*string(polynomial)*"_death_per_million_coef_final20yr_"*string(feedback)*".csv")) |> DataFrame
    crf_str = smoke_damages_crf * " CRF"
    params_crf = filter(row -> row.model == crf_str, params)
    smoke_boot = Vector(params_crf[:,3])
    
    # set bootstrap dimension
    set_dimension!(m, :smoke_bootstrap, smoke_boot) 
    
    # get parameters and add to module
    beta0_vec = Vector(params_crf[:,4])
    beta1_vec = Vector(params_crf[:,5])
    beta2_vec = Vector(params_crf[:,6])
    
    set_param!(m, :Smoke, :β0_smoke, beta0_vec)
    set_param!(m, :Smoke, :β1_smoke, beta1_vec)
    set_param!(m, :Smoke, :β2_smoke, beta2_vec)
    
    if polynomial==4
        beta3_vec = Vector(params_crf[:,7])
        beta4_vec = Vector(params_crf[:,8])
        set_param!(m, :Smoke, :β3_smoke, beta3_vec)
        set_param!(m, :Smoke, :β4_smoke, beta4_vec)
    else
        set_param!(m, :Smoke, :β3_smoke, zeros(length(beta2_vec)))
        set_param!(m, :Smoke, :β4_smoke, zeros(length(beta2_vec)))
    end
    
    
    connect_param!(m, :Smoke => :temperature, :TempNorm_1850to1900 => :global_temperature_norm)
    connect_param!(m, :Smoke => :population, :Socioeconomic => :population)
    connect_param!(m, :Smoke => :vsl, :VSL => :vsl)
    
    # Connect to damage aggregators
    connect_param!(m, :Damages_RegionAggregatorSum => :damage_smoke, :Smoke => :smoke_costs)
    connect_param!(m, :DamageAggregator => :damage_smoke_regions, :Damages_RegionAggregatorSum => :damage_smoke_regions)
    connect_param!(m, :DamageAggregator => :damage_smoke, :Smoke => :smoke_costs)

    return m
    
end