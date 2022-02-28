module RuralABM
export Connected_Components, Plot_Adj_Matrix, switch_off_comm_gaths!, seed_contagen!, Serialize_Model, Deserialize_Model, run_model!, save_model, load_model, Household_Adjacency_Matrix, Adjacency_Matrix, update_agents_attribute!, get_portion_random, get_portion_watts

    using Parameters
    using Agents
    using Graphs, MetaGraphs
    using DataFrames
    using Random, Distributions
    using SparseArrays
    using Match
    using Revise
    using Serialization, Base64
    using PlotlyJS

    include("Structs.jl")
    include("Interface.jl")
    include("AgentBehavior.jl")
    include("Distribute.jl")
    include("Watts.jl")
    include("Matrices.jl")
    include("Network.jl")

    ## Unused and probably broken
    #include("Ideologies.jl")
    #include("Age_Structured_Contacts.jl")

end # Module
