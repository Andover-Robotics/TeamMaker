function readStats()
    df = DataFrame(CSV.File("members2020.csv"))

    categoricalVariables = [:Gender, :Cohort, :Team]
    for variable = categoricalVariables
        categorical!(df, variable)
    end

    return df
end