# The social cost of CO2 for wildfire smoke in the GIVE model

This code runs the a modified version of the GIVE IAM from Rennert et al., Nature, 2022, to calculate a domestic (i.e., within-US) social cost of CO2. Four sectors (ag, temperature-driven mortality, energy use, and sea level rise) were originally included. We have added a component to include monetized damages from smoke-related mortality.

This code was written by Christopher Callahan and Lisa Rennels. 

# Requirements 

1. Julia is free and available for download [here](https://julialang.org/). Estimation was performed on Julia 1.10. While newer versions of Julia are compatible with all the code, the random number generators were updated and results might not be identical due to random differences in the random parameters underlying the Monte Carlo runs. Install Julia and ensure that it can be invoked (ran) from where the replication repository is to be cloned ("in your path").

*Tip*: Julia ships with the Julia version manager [Juliaup](https://github.com/JuliaLang/juliaup) which is useful in this case for handling Julia versions. To add the option of running Julia version 1.10 to your machine type the following in the terminal.
```
juliaup add 1.10
```
To run code using a specific version, as shown below in the replication code, you may indicate a version using `+version` ie.
```
julia +1.10 myfile.jl
```

2. Optional: Visual Studio Code (VScode) [here](https://code.visualstudio.com) is an excellent IDE for use with Julia.

3. Optional: Github is free and available for download [here](https://github.com/git-guides/install-git). Github is used to house this repository and by installing and using it to clone the repository one will simplify the replication procedure. However, a user could also simply download a zipped file version of this repository, unzip in the desired location, and follow the replication procedures outlined below

# Estimating the SC-GHGs
Estimation of the model and the SC-GHGs is outlined below.

## Getting Started 

Begin by cloning or downloading a copy of this repository. This can be done by clicking on the green "code" button in this repository and following those instructions, or by navigating in the terminal via the command line to the desired location of the cloned repository and then typing:
```
git clone git clone https://github.com/lrennels/paper-give-smoke.git
```
Alternatively, you can make a fork of this repository and work from the fork in the same way. This allows for development on the fork while preserving its relationship with this repository.

## Running the Model

Replicating the estimates can be done by following the steps outlined here and assumes that the user has downloaded and installed *Julia*. Begin by opening a terminal and navigating via the command line to the location of the cloned repository (as outlined [above](#getting-started)). Then, navigate to the [code](src) subdirectory by typing:

```
cd src
```

The directory: `paper-give-smoke\src` should be the current location in the terminal. This directory includes the replication script: `1_estimate_scghgs.jl`. 

The replication script `1_estimate_scghgs.jl` contains several important parameters that need to be set prior to the user executing the below commands.  These parameters depend on how many processors the user has available, the number of gases and emissions years they would like to run, the number of Monte Carlo simulations, and the damage function specifications. To prevent triggering too many processors from being automatically called on a user's machine, we set the number of processors equal to 1 for the default. Once the parameters have been established by the user, on the command line, type: 

```
julia +1.10 1_estimate_give_scghgs.jl
```

Importantly, note that the `+1.10` above will load the correct Julia version for this code. This can be removed and full code functionality will be retained in any 1.X version of Julia, but possible changes to random number generators may prevent identical results generation. See bullet 1 of the [Requirements](#requirements) section above. As stated there, you may need `juliaup add 1.10` to download the proper Julia version.

**Note:** Estimation time varies by machine. Using 10,000 Monte Carlo draws for each `gas + emissions year` pair (one pair per processor) takes approximate 12 processor hours to run on a high-performance computing system. Users should plan to allocate 5GB of memory per processor. 

## Output

Output data can be found in the created *output* folder, including saved `Parameters` and `Variables` in the `output\save_list` folder, and both the full set of SC-GHGs and a summary of the means in `output\scghgs`.