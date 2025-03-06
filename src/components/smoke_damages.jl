using Mimi

# ------------------------------------------------------------
# Wildfire smoke PM2.5 damages (based on Qiu et al.)
# ------------------------------------------------------------

@defcomp smoke_damages begin

    country                 = Index() # Index for countries in the regions used for the smoke-mortality damage functions.
    smoke_bootstrap         = Index() # bootstrap sample of damage functions
    
    β0_smoke             = Parameter(index=[smoke_bootstrap]) # Zero-order (intercept) coefficient relating global temperature to change in mortality rates (deaths per mil).
   	β1_smoke             = Parameter(index=[smoke_bootstrap]) # First-order (linear) coefficient relating global temperature to change in mortality rates (deaths per mil).
   	β2_smoke             = Parameter(index=[smoke_bootstrap]) # Second-order (quadratic) coefficient relating global temperature to change in mortality rates (deaths per mil).
   	β3_smoke             = Parameter(index=[smoke_bootstrap]) # Third-order (cubic) coefficient relating global temperature to change in mortality rates (deaths per mil).
   	β4_smoke             = Parameter(index=[smoke_bootstrap]) # Fourth-order (quartic) coefficient relating global temperature to change in mortality rates (deaths per mil).
    #baseline_mortality_rate = Parameter(index=[time, country]) # Crude death rate in a given country (deaths per 1,000 population).
 	temperature             = Parameter(index=[time], unit="degC") # Global average surface temperature anomaly relative to pre-industrial (°C).

    population              = Parameter(index=[time, country], unit="million") # Population in a given country (millions of persons).
    vsl                     = Parameter(index=[time, country], unit="US\$2005/yr") # Value of a statistical life ($).

    #mortality_change             = Variable(index=[time, country])  # Change in a country's baseline mortality rate due to smoke (with positive values indicating increasing mortality rates).
   	smoke_costs                   = Variable(index=[time, country], unit="US\$2005/yr")  # Costs of smoke PM2.5 mortality based on the VSL ($).
    excess_death_rate_smoke       = Variable(index=[time, country], unit = "deaths/million persons/yr")  # Change in a country's baseline death rate due to the effects of smoke PM2.5 (additional deaths per 1,000 population).
    excess_deaths_smoke           = Variable(index=[time, country], unit="persons")  # Additional deaths that occur in a country due to the effects of smoke PM2.5 (individual persons).
    excess_deaths_usa             = Variable(index=[time], unit="persons")  # Additional deaths that occur in the USA due to the effects of smoke PM2.5 (individual persons).
    
    bootid                          = Parameter(default=1) # bootstrap sample, set as random variable from main_mcs.jl

      function run_timestep(p, v, d, t)

        for c in d.country
            
            # additional deaths per million population due to changes in wildfire smoke PM2.5
            # we're doing this for each country to match the structure of GIVE but the parameters are only non-zero for the US
            # so set to zero for every non-us country
            if c==174 # not "USA"
                beta0 = p.β0_smoke[Int(p.bootid)]
                beta1 = p.β1_smoke[Int(p.bootid)]
                beta2 = p.β2_smoke[Int(p.bootid)]
                beta3 = p.β3_smoke[Int(p.bootid)]
                beta4 = p.β4_smoke[Int(p.bootid)]
            else
                beta0 = 0.0
                beta1 = 0.0
                beta2 = 0.0
                beta3 = 0.0
                beta4 = 0.0
            end
            
            # calculate excess death rate
            #v.excess_death_rate_smoke[t,c] = beta0 + (beta1 * p.temperature[t]) + (beta2 * (Complex(p.temperature[t])^2))
            v.excess_death_rate_smoke[t,c] = (beta1 * p.temperature[t]) + (beta2 * (Complex(p.temperature[t])^2)) + (beta3 * (Complex(p.temperature[t])^3)) + (beta4 * (Complex(p.temperature[t])^4))
            
            # Calculate additional deaths that occur due to smoke (assumes population units in millions of persons, which matches the damage function units).
            v.excess_deaths_smoke[t,c] = p.population[t,c] * v.excess_death_rate_smoke[t,c]

            # Multiply excess deaths by the VSL.
            v.smoke_costs[t,c] = p.vsl[t,c] * v.excess_deaths_smoke[t,c]
            
            # save these values for the US
            if c==174
                v.excess_deaths_usa[t] = v.excess_deaths_smoke[t,c]
            end
        end
    end
end
