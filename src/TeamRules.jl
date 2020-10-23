const strengthCategories = ["Mechanical", "Software", "Outreach", "Notebook", "Physics", "CAD"]
# Relative importance of each strength
const strengthWeights = [0.7, 0.6, 0.3, 0.4, 0.25, 0.3]

# Team-agnostic evaluation function
function genericEvaluate(df::AbstractDataFrame, team::String) 
    preferences = df[!, "Preference.$team"]
    meanStrengths = [mean(df[!, "Strength.$column"]) for column = strengthCategories]

    factors = [
        mean(df.Experience ./ 4) * 0.8,
        var(df.Experience)/4 * 0.3,
        mean(df.Commitment)^2 * 0.6,
        mean(meanStrengths .* strengthWeights)^2 * 1,
        mean(preferences) * 2
        # TODO cohort, availability, CAD, grade
    ]
    result = mean(factors)

    return result * minimum(preferences)
end

function summary(df::AbstractDataFrame, team::String)
    strengthsPerCategory = map(cat -> "Strength ($cat)" => summarystats(df[!, "Strength.$cat"]), strengthCategories)
    formatStats(stats) = "$(round(stats.min, digits=2)) - $(round(stats.q25, digits=2)) - $(round(stats.median, digits=2)) - $(round(stats.q75, digits=2)) - $(round(stats.max, digits=2)) [μ=$(round(stats.mean, digits=3))]"

    stats = vcat([
        "Experience (years)" => summarystats(df.Experience),
        "Commitment (0 to 1)" => summarystats(df.Commitment),
        "Preference (0 to 1)" => summarystats(df[!, "Preference.$team"])
    ], strengthsPerCategory)

    println("Summary of $team:")
    for (key, valueStats) = stats
        println("   $key => $(formatStats(valueStats))")
    end
end

function summaryInR(df::AbstractDataFrame, team::String)
    categoryLine(category) = "    Strength.$category = c($(join(df[!, "Strength.$category"], ", ")))"

    return "teamSummary <- data.frame(
    Experience = c($(join(df.Experience ./ 4, ", "))),
    Commitment = c($(join(df.Commitment, ", "))),
    Preference = c($(join(df[!, "Preference.$team"], ", "))),\n" *
        join(map(categoryLine, strengthCategories), ",\n") * ")"
end

# Combine the scores of all teams into one score.
function joinScores(scores::Array{Float64, 1}, frames::GroupedDataFrame)
    factors = [
        # No team can be bad
        minimum(scores)^2,
        # Teams shall be good
        mean(scores) * 0.9,
        # Teams shall be balanced
        (1 - var(scores)*3) * 0.65,
        # In strength as well as in size
        (1 - tanh(var(combine(frames, nrow).nrow) / 6)) * 1.8
    ]

    return mean(factors)
end

function checkRequirements(frames::GroupedDataFrame)
    for key = keys(frames)
        if size(frames[key], 1) <= 1
            return false
        # No member assigned to this team should hate this team
        elseif minimum(frames[key][!, "Preference.$(string(key.Team))"]) < 0.2
            return false
        elseif !TeamRequirements[string(key.Team)](frames[key])
            return false
        end
    end
    return true
end

function evaluate(frames::GroupedDataFrame)
    scores = [genericEvaluate(frames[key], String(key.Team)) for key = keys(frames)]
    return joinScores(scores, frames)
end

# Team Rule Configuration Begins Here ---

# function that checks against hard constraints, like gender of Hailstorm
# the team leaders are public on andoverrobotics.com
const TeamRequirements = Dict(
    "Hailstorm" => function (df::AbstractDataFrame)
        return all(df.Gender .== "Female") && "Helina Dicovitsky" in df.Name
    end,
    "Lightning" => function (df::AbstractDataFrame)
        # Co-ed, no hard limits
        return "Michael Peng" in df.Name
    end,
    "Thunder" => function (df::AbstractDataFrame)
        # Co-ed, no hard limits
        return "Anderson Hsiao" in df.Name && "Daniel Ivanovich" in df.Name
    end
)

const TeamEvaluators = Dict(
    "Hailstorm" => genericEvaluate,
    "Lightning" => genericEvaluate,
    "Thunder" => genericEvaluate,
)