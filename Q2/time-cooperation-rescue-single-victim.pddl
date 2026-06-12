;;  PROBLEM 1 — SINGLE VICTIM, COOPERATIVE RESCUE
;;
;;  Baseline problem. Victim at the far end of the north wing.
;;  Health is comfortable — validates that cooperation works
;;  before introducing timing pressure in Problems 2 and 3.
;;
;;  Sequential timing (distances=2, search speed=2, rescue speed=1):
;;    t=0   search-robot departs entrance
;;    t=4   search-robot arrives n-deep: search + stabilize victim1
;;          health at stabilization: 30 - 4x2 = 22
;;    t=4   rescue-robot departs entrance (victim location now known)
;;    t=12  rescue-robot arrives n-deep: pickup victim1
;;          health at pickup: 22 - (12-4)x1 = 14
;;    t=20  rescue-robot delivers victim1 at entrance
;;          health at delivery: 14 - 8x1 = 6  -> SAFE

(define (problem time-cooperation-rescue-p1)
  (:domain search-and-rescue-time-coordination)

  (:objects
    entrance hub
    n-hall n-room n-deep
    s-hall s-room s-deep - location
    search-robot rescue-robot - robot
    victim1                   - victim
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
    (hands-free rescue-robot)

    (is-search-robot search-robot)
    (is-rescue-robot rescue-robot)

    ;; Zone known, exact position confirmed only by search action
    (victim-in-area victim1 n-deep)

    (= (health victim1) 30)

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
  ))
)
