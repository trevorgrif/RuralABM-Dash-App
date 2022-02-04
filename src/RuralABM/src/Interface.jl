#============================================================
---------------------- Run the Model  -----------------------
============================================================#

function switch_off_comm_gaths!(model)
    turn_comm_gaths_off!(model)
end

function seed_contagen!(model, seed_num = 1)
    infect_someone!(model,seed_num)
end

function run_model!(model, days::Int; savepath="")
    # Set epidemiological data
    symptomatic(x) = x.status == :I
    recovered(x) = x.status == :R
    pop_size(x) = x.id != 0

    adata = [(symptomatic, count), (recovered, count), (pop_size, count)]

    # Run the model and extract model data
    @time begin
        data, mdata = run!(model,agent_step!,model_step!,12*days; adata= adata, mdata = [:day])
    end

    # If savepath given, store model
    if savepath != ""
        save_model(savepath, model)
    end

    return data, mdata
end

function construct_town(filepath1, filepath2)
    build_town(filepath1, filepath2)
end

function save_model(filepath, model)
    AgentsIO.save_checkpoint(filepath, model)
end

function load_model(filepath)
    AgentsIO.load_checkpoint(filepath;warn = false)
end

function Adjacency_Matrix(model)
    Get_Adjacency_Matrix(model)
end

function Connected_Components(model;min_w = 0)
    get_connected_components(model,min_w = min_w)
end

function Serialize_Model(model)
    base64encode(serialize, model)
end

function Deserialize_Model(model)
    deserialize(IOBuffer(base64decode(model)))
end

function Household_Adjacency_Matrix(model)
    Household_Adjacency(model)
end

function update_agents_attribute!(model, id_arr, attr::Symbol, new_value)
    update_agents_attr!(model, id_arr, attr, new_value)
end

function get_portion_random(model, portion)
    get_portion_rand(model, portion)
end

function get_portion_watts(model, portion; δ = 0.014, seed_num = 1, VERBOSE = false)
     get_portion_Watts(model, portion; δ, seed_num, VERBOSE)
end

function Plot_Adj_Matrix(model; min_w = 0)
    plot_adj_matrix(model, min_w)
end
