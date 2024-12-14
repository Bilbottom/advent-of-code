with

input(data) as (
    select *
    from read_csv('{{ file }}', header=false, sep='')
),

machines as (
    from (
        from input
        select
            data,
            sum((data is null)::int) over (order by 1 rows unbounded preceding) as claw_id
    )
    select
        claw_id,

        max(regexp_extract(data, 'Button A: X\+(\d+), Y\+(\d+)', ['x', 'y']))::struct(x int, y int) as button_a,
        max(regexp_extract(data, 'Button B: X\+(\d+), Y\+(\d+)', ['x', 'y']))::struct(x int, y int) as button_b,
        max(regexp_extract(data, 'Prize: X=(\d+), Y=(\d+)',      ['x', 'y']))::struct(x int, y int) as prize,
    where data is not null
    group by claw_id
)

/* Solve the equations */
from (
    from machines
    select
        *,
        (1
            * ((prize['y'] * button_a['x']) - (prize['x'] * button_a['y']))
            / ((button_b['y'] * button_a['x']) - (button_a['y'] * button_b['x']))
        ) as times_press_b,
        (1
            * (prize['x'] - (times_press_b * button_b['x']))
            / button_a['x']
        ) as times_press_a,
        (times_press_a % 1 = 0) and (times_press_b % 1 = 0) as is_solvable,
        if(is_solvable, times_press_a * 3 + times_press_b, 0) as cost
)
select sum(cost)
;


/*
    Let:

    - Px = prize['x']
    - Py = prize['y']
    - Ax = button_a['x']
    - Ay = button_a['y']
    - Bx = button_b['x']
    - By = button_b['y']
    - Na = times_press_a
    - Nb = times_press_b

    We need to solve the equations:

        (Px, Py) = (Na * Ax + Nb * Bx, Na * Ay + Nb * By)

    This has the solution:

    - Nb = (Py * Ax - Px * Ay) / (By * Ax - Ay * Bx)
    - Na = (Px - Nb * Bx) / Ax

    The claw machine only moves in intervals of 1, so Na and Nb must be
    whole numbers.
*/
