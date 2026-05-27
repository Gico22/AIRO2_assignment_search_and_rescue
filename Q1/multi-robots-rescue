(define (problem cooperation-rescue)
  (:domain search-and-rescue-multi-robot-coop)

  (:objects
    entrance hub
    n-hall n-room n-deep
    s-hall s-room s-deep  - location
    light-robot heavy-robot - robot
    victim1 victim2         - victim
  )

  (:init
    ; --- map: trunk ---
    (connected entrance hub)   (connected hub entrance)
    ; --- north wing ---
    (connected hub     n-hall) (connected n-hall hub)
    (connected n-hall  n-room) (connected n-room n-hall)
    (connected n-room  n-deep) (connected n-deep n-room)
    ; --- south wing ---
    (connected hub     s-hall) (connected s-hall hub)
    (connected s-hall  s-room) (connected s-room s-hall)
    (connected s-room  s-deep) (connected s-deep s-room)
    ; --- cross-passage (the shortcut) ---
    (connected n-room  s-room) (connected s-room n-room)

    (safe-zone entrance)

    (robot-at light-robot entrance)
    (robot-at heavy-robot entrance)

    (victim-at victim1 n-deep)
    (victim-at victim2 s-deep)

    (can-search    light-robot)
    (can-stabilize light-robot)
    (can-carry     heavy-robot)
  )

  (:goal (and
    (victim-rescued victim1)
    (victim-rescued victim2)
  ))
)