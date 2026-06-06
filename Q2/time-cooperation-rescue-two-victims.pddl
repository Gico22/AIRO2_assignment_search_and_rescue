;;  PROBLEM 2 — TWO VICTIMS UNDER TIME PRESSURE
;;
;;  The main cooperative scenario. Victims in opposite wings.
;;  Health values are tight: the rescue robot must depart as
;;  soon as victim1 is found and rescue them in the correct order.
;;  The planner must discover that rescuing victim2 first causes
;;  victim1 to die — the ordering is not given, it emerges from
;;  the timing constraints.
;;
;;  Sequential timing (distances=2, search speed=2, rescue speed=1):
;;    t=0   search-robot departs entrance
;;    t=4   search-robot arrives n-deep: search + stabilize victim1
;;          victim1 health: 26 - 8 = 18
;;          rescue-robot departs entrance for n-deep
;;    t=7   search-robot arrives s-deep (via cross-passage, 3 hops)
;;          search + stabilize victim2
;;          victim2 health: 46 - 14 = 32
;;    t=12  rescue-robot arrives n-deep: pickup victim1
;;          victim1 health: 18 - 8 = 10
;;    t=20  rescue-robot delivers victim1
;;          victim1 health: 10 - 8 = 2  -> SAFE (barely)
;;          rescue-robot departs for s-deep
;;    t=28  rescue-robot arrives s-deep: pickup victim2
;;          victim2 health: 32 - 21 = 11
;;    t=36  rescue-robot delivers victim2
;;          victim2 health: 11 - 8 = 3  -> SAFE (barely)
;;
;;  Wrong ordering (rescue goes victim2 first):
;;    t=8   rescue arrives s-deep, picks up victim2 (valid)
;;    t=24  rescue arrives n-deep for victim1
;;          victim1 health: 18 - 20 = -2  -> DEAD

(define (problem time-cooperation-rescue-two-victims)
  (:domain search-and-rescue-time-coordination)

  (:objects
    entrance hub
    n-hall n-room n-deep
    s-hall s-room s-deep - location
    search-robot rescue-robot - robot
    victim1 victim2           - victim
  )

  (:init

    (connected entrance hub)   (connected hub entrance)
    (connected hub     n-hall) (connected n-hall hub)
    (connected n-hall  n-room) (connected n-room n-hall)
    (connected n-room  n-deep) (connected n-deep n-room)
    (connected hub     s-hall) (connected s-hall hub)
    (connected s-hall  s-room) (connected s-room s-hall)
    (connected s-room  s-deep) (connected s-deep s-room)
    (connected n-room  s-room) (connected s-room n-room)

    (safe-zone entrance)

    (at search-robot entrance)
    (at rescue-robot entrance)
    (robot-available search-robot)
    (robot-available rescue-robot)

    (is-search-robot search-robot)
    (is-rescue-robot rescue-robot)

    (victim-in-area victim1 n-deep)
    (victim-in-area victim2 s-deep)

    ;; Tight values: both victims survive only if rescue robot
    ;; departs immediately after victim1 is found and rescues
    ;; victim1 before victim2. Any delay causes coordination failure.
    (= (health victim1) 26)
    (= (health victim2) 46)

    (= (speed search-robot) 2.0)
    (= (speed rescue-robot) 1.0)

    (= (travel-progress search-robot) 0)
    (= (travel-progress rescue-robot) 0)

    (= (distance entrance hub)   2) (= (distance hub entrance)   2)
    (= (distance hub     n-hall) 2) (= (distance n-hall hub)     2)
    (= (distance n-hall  n-room) 2) (= (distance n-room n-hall)  2)
    (= (distance n-room  n-deep) 2) (= (distance n-deep n-room)  2)
    (= (distance hub     s-hall) 2) (= (distance s-hall hub)     2)
    (= (distance s-hall  s-room) 2) (= (distance s-room s-hall)  2)
    (= (distance s-room  s-deep) 2) (= (distance s-deep s-room)  2)
    (= (distance n-room  s-room) 2) (= (distance s-room n-room)  2)
  )

  (:goal (and
    (rescued victim1)
    (rescued victim2)
  ))
)
