for a in selection do(
    hi = a.name

    byeprelim = substring hi 1 1
    byeprelim1 = toUpper byeprelim
    byeprelim2 = replace hi 1 1 byeprelim1

    a.name = byeprelim2
)
