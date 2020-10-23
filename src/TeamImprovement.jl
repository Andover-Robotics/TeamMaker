Random.seed!()

const Delta = Tuple{Int64, String, String}

function randomChange(df::AbstractDataFrame)::Delta
    row = rand(eachrow(df))
    newTeam = rand(setdiff(levels(df.Team), [row.Team]))
    oldTeam = row.Team
    return (getfield(row, :row), newTeam, String(oldTeam))
end

function perform!(change::Delta, df::AbstractDataFrame)
    row, newTeam, _ = change
    df[row, :].Team = newTeam
end

function revert!(change::Delta, df::AbstractDataFrame)
    row, _, oldTeam = change
    df[row, :].Team = oldTeam
end

function anneal(df::AbstractDataFrame, iterations::Int64 = 10000)
    grouped(f) = groupby(f, :Team)
    
    groups = grouped(df)
    scoreNew = evaluate(groups)

    # P(ΔE, i) = 30 * i / iterations * (ΔE - 0.05) + 0.8
    P(ΔE, i) = 1 ÷ (1 + exp(-8 * ΔE * 50 * i / iterations))

    for i in 1:iterations
        scoreOriginal = scoreNew
        Δ = randomChange(df)
        perform!(Δ, df)

        groups = grouped(df)
        scoreNew = evaluate(groups)
        probAccept = P(scoreNew - scoreOriginal, i)
        if !checkRequirements(groups) || rand() > probAccept
            revert!(Δ, df)
            scoreNew = scoreOriginal
        else
            @show Δ, scoreOriginal, scoreNew
        end
    end
end

function wanderMaxima(df::AbstractDataFrame, iterations::Int64 = 100000)
    grouped(f::AbstractDataFrame) = groupby(f, :Team)
    assignments(groups::GroupedDataFrame) = Dict([String(key.Team) => groups[key].Name for key = keys(groups)])
    
    initialBest = let groups = grouped(df)
        [evaluate(groups), assignments(groups), df]
    end

    bests = [copy(initialBest) for i = 1:Threads.nthreads()]
    dfs = [copy(df) for i = 1:Threads.nthreads()]

    Threads.@threads for i = 1:iterations
        if i % 50000 == 0
            println(i)
        end

        threadNum = Threads.threadid()
        localdf, best = dfs[threadNum], bests[threadNum]

        Δ = randomChange(localdf)
        perform!(Δ, localdf)

        let groups = grouped(localdf)
            if !checkRequirements(groups)
                revert!(Δ, localdf)
            else
                newScore = evaluate(groups)
                if newScore > best[1]
                # if newScore < best[1]
                    best[1] = newScore
                    best[2] = assignments(groups)
                    best[3] = localdf
                elseif newScore < best[1] - 0.3
                # elseif newScore > best[1] + 0.3
                    revert!(Δ, df)
                end
            end
        end

        dfs[threadNum], bests[threadNum] = localdf, best
    end

    return bests
end