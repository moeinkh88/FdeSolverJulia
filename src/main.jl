function FDEsolver(F, tSpan, y0, β, ::Nothing, par...; h = 0.01, nc = 3, StopIt = "Standard", tol = 10e-10, itmax = 10)

    # Time discretization
    N::Int64 = cld(tSpan[2] - tSpan[1], h)
    t = tSpan[1] .+ collect(0:N) .* h

    # Enter the initial values
    Y = defineY(N, y0, β)

    # Calculate T with taylor expansion
    m::Int64 = ceil(β[1])
    
    for n in 1:N

        T0 = taylor_expansion(tSpan[1], t[n], y0, β, m)

        if n == 1

            # Y1
            Y1 = T0 .+ h .^ β .* F(t, n, β, Y, par...) ./ Γ(β .+ 1)
            Y = indexY(n, Y, Y1)

            if StopIt == "Standard"

                for j in 1:nc

                    # Y11
                    Y11 = T0 .+ h .^ β .* β .* F(t, n, β, Y, par...) ./ Γ(β .+ 2) .+ h .^ β .* F(t, n + 1, β, Y, par...) ./ Γ(β .+ 2)
                    σ = sqrt(sum((Y11 .- Y[n + 1, :]) .^ 2))
                    Y = indexY(n, Y, Y11)

                end

            elseif StopIt == "Convergence"

                σ = 1.1 * tol
                j = 0

                while (σ > tol && j < itmax)

                    # Y11
                    Y11 = T0 .+ h .^ β .* β .* F(t, n, β, Y, par...) ./ Γ(β .+ 2) .+ h .^ β .* F(t, n + 1, β, Y, par...) ./ Γ(β .+ 2)
                    σ = sqrt(sum((Y11 .- Y[n + 1, :]) .^ 2))
                    Y = indexY(n, Y, Y11)

                    j += 1

                end

            end

        else

            ϕ = Phi(Y, F, β, t, n, par...)

            # Yp
            Yp = T0 .+ h .^ β .* (ϕ .- α(0, β) .* F(t, n - 1, β, Y, par...) .+ 2 .* α(0, β) .* F(t, n, β, Y, par...))
            Y = indexY(n, Y, Yp)

            if StopIt == "Standard"

                for j in 1:nc

                    # Y2
                    Y2 = T0 .+ h .^ β .* (ϕ .+ α(0, β) .* F(t, n + 1, β, Y, par...))
                    σ = sqrt(sum((Y2 .- Y[n + 1, :]) .^ 2))
                    Y = indexY(n, Y, Y2)

                end

            elseif StopIt == "Convergence"

                σ = 1.1 * tol
                j = 0

                while (σ > tol && j < itmax)

                    # Y2
                    Y2 = T0 .+ h .^ β .* (ϕ .+ α(0, β) .* F(t, n + 1, β, Y, par...))
                    σ = sqrt(sum((Y2 .- Y[n + 1, :]) .^ 2))
                    Y = indexY(n, Y, Y2)

                    j += 1

                end

            end

        end

    end

    # Output
    t, Y

end
