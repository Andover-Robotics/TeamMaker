function test()
    df = readStats()
    println("annealing...")

    out = wanderMaxima(df, 1800000)

    for (score, dict, df) = sort(out, by=x -> x[1])
        groups = groupby(df, :Team)

        println(score)
        for (team, roster) = pairs(dict)
            println("   $team:")
            for name = roster
                println("      $name")
            end
        end
        println()

        for key = keys(groups)
            summary(groups[key], string(key.Team))
            println(summaryInR(groups[key], string(key.Team)))
        end
    end
end
