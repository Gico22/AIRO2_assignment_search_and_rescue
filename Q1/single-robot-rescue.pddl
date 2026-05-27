(define (problem single-robot-rescue)
  (:domain search-and-rescue-multi-robot-coop)

  (:objects
    entrance room1 - location
    heavy-robot    - robot
    victim1        - victim
  )

  (:init
    ; map
    (connected entrance room1)
    (connected room1 entrance)
    (safe-zone entrance)

    ; robot starts at entrance
    (robot-at heavy-robot entrance)

    ; victim is already found and stabilized — no search needed
    (victim-at victim1 room1)
    (victim-found victim1)
    (victim-stabilized victim1)

    ; capabilities
    (can-carry heavy-robot)
  )

  (:goal (victim-rescued victim1))
)