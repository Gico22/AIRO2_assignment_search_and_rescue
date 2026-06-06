;;  PROBLEM 3 — COORDINATION FAILURE (victim2 cannot be saved)
;;
;;  Same map and robots as Problem 2. victim1 is saveable with
;;  the same tight margin. victim2's initial health is set below
;;  the survivability threshold of 43 — no valid plan exists.
;;
;;  victim2 is stabilized at t=7 with health 30-14 = 16.
;;  Degrading at rate 1, it dies at t = 7 + 16 = 23.
;;  The rescue robot is still transporting victim1 at t=23
;;  (delivering at t=20, then departing for victim2 at t=20).
;;  It would only reach s-deep at t=28 — five time units too late.
;;  victim-dies fires at t=23, making (rescued victim2) permanently
;;  unreachable regardless of what either robot does afterward.
;;
;;  This demonstrates that even with optimal coordination,
;;  a single rescue robot cannot always reach two victims in time.
;;  The bottleneck is the rescue robot's travel speed, not
;;  the quality of the plan.

(define (problem time-cooperation-rescue-failure)
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

    ;; victim1: same as Problem 2, saveable with health at delivery = 2
    ;; victim2: below survivability threshold (43) — dies at t=23
    ;;          while rescue robot is still transporting victim1
    (= (health victim1) 26)
    (= (health victim2) 30)

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
