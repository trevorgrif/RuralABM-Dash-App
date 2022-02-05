#============================================================
-------------------------- Modules --------------------------
============================================================#
# External Modules
using DataFrames, Dash, DashBootstrapComponents, PlotlyJS
using Plots: RGBA

# Local Modules
include("RuralABM/src/RuralABM.jl")
using .RuralABM

#============================================================
------------------- Helper Functions ------------------------
============================================================#
function start_run(model, numdays)
    data, mdata = run_model!(model, numdays)
    return data
end

function generate_html_table(dataframe, max_rows = 10)
    html_table([
        html_thead(html_tr([html_th(col) for col in names(dataframe)])),
        html_tbody([
            html_tr([html_td(dataframe[r, c]) for c in names(dataframe)]) for r = 1:min(nrow(dataframe), max_rows)
        ]),
    ])
end

function parse_to_daily!(StepData)
    day_data = StepData[1:12:end, :]
    select!(day_data,:step => (x -> x/12), :count_symptomatic, :count_recovered, :count_pop_size)
    rename!(day_data, Dict(:step_function => "Day", :count_symptomatic => "Symptomatic", :count_recovered => "Recovered", :count_pop_size => "Population"))
    return day_data
end

function network_graph_layout()
    return Layout(
                hovermode="closest",
                title=attr(
                    text = "Network Graph",
                    y=0.9,
                    x=0.5,
                    xanchor= "center",
                    yanchor= "top"
                ),
                titlefont_size=16,
                showlegend=false,
                showarrow=false,
                xaxis=attr(showgrid=false, zeroline=false, showticklabels=false),
                yaxis=attr(showgrid=false, zeroline=false, showticklabels=false),
                paper_bgcolor= RGBA(0,0,0,0),
                plot_bgcolor= RGBA(0,0,0,0),
                height = 450,
                width = 450
            )
end

function model_graph_layout()
    return Layout(
                title = attr(
                    text = "Infection Over Time",
                    y=0.9,
                    x=0.5,
                    xanchor= "center",
                    yanchor= "top"
                ),
                xaxis_title = "Days",
                yaxis_title = "Case Count",
                paper_bgcolor= RGBA(0,0,0,0),
                plot_bgcolor= RGBA(0,0,0,0),
                height = 450,
                width = 450
            )
end

function blank_network_graph()
    data = GenericTrace{Dict{Symbol, Any}}[]
    return Plot(data, network_graph_layout())
end

function blank_model_graph()
    data = GenericTrace{Dict{Symbol, Any}}[]
    return Plot(data, model_graph_layout())
end

#============================================================
------------------ Application Layout -----------------------
============================================================#

#============================================================
Initialize App
============================================================#
app = dash(external_stylesheets=[dbc_themes.DARKLY],assets_folder="assets/")

#============================================================
Layout Variables
============================================================#

construct_town_variables = html_div(className = "table-col-1") do
    dbc_button("Build Town", id = "build-town", n_clicks = 0,size = "sm", style = Dict("margin" => "auto", "display" => "block")),
    html_br(),
    dbc_inputgroup(size = "sm") do
        dbc_inputgrouptext("Run Length"),
        dbc_input(id = "construct-length-input", type = "number", value = 30, style = Dict("text-align" => "right"))
    end,
    html_br(),
    dbc_checklist(
        options = [
            Dict("label" => "Community Gathering", "value" => 1),
        ],
        value = [1],
        input_class_name="comm-gath-value-adj",
        label_class_name="comm-gath-label-adj",
        id = "construct_comm_gath_switch",
        switch = true,
    )
end

network_graph = html_div(className = "table-col-2") do
    dcc_graph(id="network-graph",figure=blank_network_graph())
end

network_graph_slider = html_div() do
    dbc_label("Weight Filtration",color="secondary", className="slider-label"),
    html_div(
        dcc_slider(
             id="min_w_slider_input",
             min = 0.025,
             max = 0.525,
             step = 0.025,
             value = 0.025,
             vertical = true,
             verticalHeight = 300,
             tooltip=Dict("placement" => "bottom", "always_visible" => false)
        ),
        className = "slider"
    ),
    html_div(id = "min_w_slider_display")
end

network_ss = html_div(className = "table-col-3") do
    dbc_listgroup(horizontal = true) do
        dbc_listgroupitem("Nodes"),
        dbc_listgroupitem(0,id="SS_Nodes")
    end,
    html_br(),
    dbc_listgroup(horizontal = true) do
        dbc_listgroupitem("Edges"),
        dbc_listgroupitem(0,id="SS_Edges")
    end,
    html_br(),
    dbc_listgroup(horizontal = true) do
        dbc_listgroupitem("Density"),
        dbc_listgroupitem("0.000",id="SS_Density")
    end,
    html_br(),
    dbc_listgroup(horizontal = true) do
        dbc_listgroupitem("Conn. Components"),
        dbc_listgroupitem(0,id="SS_ConnComp")
    end
end

run_model_variables = html_div(className = "table-col-1") do
    dbc_button("Run Model", id = "run-model", n_clicks = 0, size = "sm", disabled = true, style = Dict("margin" => "auto", "display" => "block")),
    html_br(),
    dbc_inputgroup(size = "sm") do
        dbc_inputgrouptext("Run Length"),
        dbc_input(id = "model-length-input", type = "number", min = 0, value = 100, style = Dict("text-align" => "right"))
    end,
    html_br(),
    dbc_inputgroup(size = "sm") do
        dbc_inputgrouptext("Seeds"),
        dbc_input(id = "model-seed-input", type = "number", min = 1, value = 3, style = Dict("text-align" => "right"))
    end,
    html_br(),
    dbc_inputgroup(size = "sm") do
        dbc_inputgrouptext("Proportion Masked"),
        dbc_input(id = "model-mask-input", type = "number", min = 0, max = 100, value = 0, style = Dict("text-align" => "right"))
    end,
    html_br(),
    dbc_inputgroup(size = "sm") do
        dbc_inputgrouptext("Proportion Vaccinated"),
        dbc_input(id = "model-vacc-input", type = "number", min = 0, max = 100, value = 0, style = Dict("text-align" => "right"))
    end
end

infection_graph = html_div(className = "table-col-2") do
    dcc_graph(id="infection-graph",figure=blank_model_graph())
end

model_run_ss = html_div(className = "table-col-3 model-ss-style") do
    dbc_listgroup(horizontal = true) do
        dbc_listgroupitem("Infected"),
        dbc_listgroupitem(0,id="SS_Infected")
    end,
    html_br(),
    dbc_listgroup(horizontal = true) do
        dbc_listgroupitem("Recovered"),
        dbc_listgroupitem(0,id="SS_Recovered")
    end,
    html_br(),
    dbc_listgroup(horizontal = true) do
        dbc_listgroupitem("Day of Peak"),
        dbc_listgroupitem(0,id="SS_DayOfPeak")
    end
end

#============================================================
Main App Layout
============================================================#

# Table head construction
table_head = dbc_row(dbc_col(html_div("Rural ABM", className="float-right")))

# Table row_1 construction
row_1 = html_div() do
    dbc_row(align = "center") do
        dbc_col(construct_town_variables),
        dbc_col(network_graph),
        dbc_col(network_graph_slider, width = "auto"),
        dbc_col(network_ss)
    end
end

# Table row_2 construction
row_2 = html_div() do
    dbc_row(align = "center") do
        dbc_col(run_model_variables),
        dbc_col(infection_graph),
        dbc_col(model_run_ss)
    end
end

table = html_div(className = "table-adj") do
    table_head,
    row_1,
    row_2
end

# App layout construction
app.layout = html_div() do
    dcc_store(id="model_container"),
    table
end

#============================================================
----------------------- Callbacks ---------------------------
============================================================#

#============================================================
Run Model Callback: takes all model variables listed below
and runs the model. Outputs certain data from the model run
into "infection-graph". Model data is taken and deserialized
from "model_container". Therefore, each run acts on a new copy
of the model object.

     model-length-input: Number of steps (in days) the model
     			 will take
     model-seed-input: Number of agents infected intially
     model-mask-input: Percentage of population masking (rand)
     model-vacc-input: Percentage of population vaccinated (rand)

============================================================#
callback!(
    app,
    Output("infection-graph", "figure"),
    Output("SS_Infected","children"),
    Output("SS_Recovered","children"),
    Output("SS_DayOfPeak","children"),
    Input("run-model", "n_clicks"),
    State("model_container","data"),
    State("model-length-input","value"),
    State("model-seed-input","value"),
    State("model-mask-input","value"),
    State("model-vacc-input","value")
) do clicks, model_ser, numdays, seed_num, por_mask, por_vacc
    # Prevent callback on startup
    if iszero(clicks)
        throw(PreventUpdate())
    end

    # Run Model with all variables storing results in DataFrame
    model = Deserialize_Model(model_ser)
    update_agents_attribute!(model, get_portion_random(model, por_mask/100), :will_mask, [true, true, true])
    update_agents_attribute!(model, get_portion_random(model, por_vacc/100), :status, :V)
    seed_contagen!(model, seed_num)
    AgentData = start_run(model, numdays)

    # Parse the DataFrames
    AgentData = parse_to_daily!(AgentData)

    # Compute Statistics
    total_infected = AgentData[end,2] + AgentData[end,3] + (model.init_pop_size - AgentData[end,4]) # Current_Infected + Recovered + Dead
    total_recovered = AgentData[end,3]
    max_infected, peak_day = findmax(AgentData.Symptomatic)
    peak_day -= 1

    # Build Plots
    graph_data = AbstractTrace[]
    for col in names(AgentData)[2:end]
        push!(graph_data, scatter(x=AgentData[!,1], y=AgentData[!,col], mode = "lines", name = col))
    end

    return Plot(graph_data,
                Layout(
                    title = attr(
                        text = "Infection Over Time",
                        y=0.9,
                        x=0.5,
                        xanchor= "center",
                        yanchor= "top"
                    ),
                    xaxis_title = "Days",
                    yaxis_title = "Case Count",
                    paper_bgcolor= RGBA(0,0,0,0),
                    plot_bgcolor= RGBA(0,0,0,0),
                    height = 450,
                    width = 550
                    )
                ),
            total_infected,
            total_recovered,
            peak_day
end

# Update Network Graph Callback
callback!(
    app,
    Output("network-graph","figure"),
    Output("SS_Nodes","children"),
    Output("SS_Edges","children"),
    Output("SS_Density","children"),
    Output("SS_ConnComp","children"),
    Input("min_w_slider_input","value"),
    Input("model_container","data")
) do min_w_given, model_ser
    if isnothing(model_ser)
        throw(PreventUpdate())
    end
    model = Deserialize_Model(model_ser)
    M = Adjacency_Matrix(model)
    num_agents = Int(sqrt(length(M)))
    num_edges = 0
    # Create Graph object
    for i in 1:num_agents-1
        for j in i+1:num_agents
            if M[i,j] >= min_w_given
                num_edges += 1
            end
        end
    end
    density = round(num_edges / (num_agents*(num_agents-1)/2), digits = 3)
    num_ConnComp = length(Connected_Components(model,min_w = min_w_given))
    graph_data = Plot_Adj_Matrix(model, min_w = min_w_given)
    return Plot(graph_data,
                Layout(
                    hovermode="closest",
                    title=attr(
                        text = "Network Graph",
                        y=0.9,
                        x=0.5,
                        xanchor= "center",
                        yanchor= "top"
                    ),
                    titlefont_size=16,
                    showlegend=false,
                    showarrow=false,
                    xaxis=attr(showgrid=false, zeroline=false, showticklabels=false),
                    yaxis=attr(showgrid=false, zeroline=false, showticklabels=false),
                    paper_bgcolor= RGBA(0,0,0,0),
                    plot_bgcolor= RGBA(0,0,0,0),
                    height = 450,
                    width = 450
                    )
                ),
            num_agents,
            num_edges,
            density,
            num_ConnComp
end

# Build Town Callback
callback!(
    app,
    Output("model_container","data"),
    Output("run-model","disabled"),
    Input("build-town","n_clicks"),
    State("construct-length-input","value"),
    State("construct_comm_gath_switch","value")
) do clicks, run_length, do_comm_gaths
    # Prevent callback on startup
    if iszero(clicks)
        throw(PreventUpdate())
    end
    model = construct_town("ABM_Input/Town_Data/abm_cityoutput_Dubois_ID_10_mile_income_ind.csv", "ABM_Input/Business_Data/Dubois_Idaho_10mile_biz.csv")

    #Turn off/on community gatherings
    if length(do_comm_gaths) == 0
        switch_off_comm_gaths!(model)
    end

    # Create a social network by running the model for run_length
    run_model!(model, run_length)

    # Serialize the model to store in dcc_store
    model_ser = Serialize_Model(model)

    return model_ser,false
end

#============================================================
----------------------- Run Server --------------------------
============================================================#
run_server(app, "0.0.0.0", parse(Int, ARGS[1]),debug=true)
