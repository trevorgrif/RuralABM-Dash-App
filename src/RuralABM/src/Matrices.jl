##Matrices
function Get_Adjacency_Matrix(model)
    if model.model_steps == 0
        @warn "Retrieving adjacency matrix before model has stepped (i.e. empty matrix)."
    end
    A = DataFrame(Agent = Int64[], Contact = Int64[], Count = Float64[])
    for agent in allagents(model)
        for i in findall(!iszero,agent.contact_list)
            push!(A,[agent.id i (agent.contact_list[i])/model.model_steps])
        end
    end
    for agent in eachrow(model.DeadAgents)
        for i in findall(!iszero,agent.contact_list)
            push!(A,[agent.Agent, i, (agent.contact_list[i])/model.model_steps])
        end
    end
    return sparse(A.Agent, A.Contact, A.Count)
end

function Household_Adjacency(model)
    A = DataFrame(Agent = Int64[], Contact = Int64[], Household = Int64[], Contact_household= Int64[], Count = Float64[])
    for agent in allagents(model)
        for i in findall(!iszero, agent.contact_list)
            try
            push!(A,[agent.id i agent.home model[i].home agent.contact_list[i]])
            catch
            push!(A,[agent.id, i, agent.home,
                    filter(x->x.Agent==i,model.DeadAgents).Home[1],
                    agent.contact_list[i]])
            end
        end
    end
    select!(A,[:Household, :Contact_household, :Count])
    A =  combine(groupby(A, [:Household, :Contact_household]), :Count => sum => :Count)
    return sparse(A.Household, A.Contact_household, A.Count)
end

function Household_size(model)
    A = DataFrame(Agent = Int64[], Household = Int64[], Counter = Bool[])
    for agent in allagents(model)
            A = push!(A,[agent.id agent.home true])
    end
    A = combine(groupby(A, :Household),:Counter => count => :Number)
    sort!(A,:Household)
    return A
end
