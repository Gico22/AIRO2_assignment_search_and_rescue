(define (domain search-and-rescue-multi-robot-coop)

  (:requirements :strips :typing :negative-preconditions)

  (:types
    location
    robot
    victim
  )

  (:predicates
    ; --- MAP ---
    (connected ?l1 - location ?l2 - location)
    (safe-zone ?l - location)

    ; --- POSITIONS ---
    (robot-at ?r - robot ?l - location)
    (victim-at ?v - victim ?l - location)

    ; --- VICTIM STATE ---
    (victim-found      ?v - victim)
    (victim-stabilized ?v - victim)
    (victim-rescued    ?v - victim)

    ; --- CARRYING ---
    (carrying ?r - robot ?v - victim)

    ; --- CAPABILITIES ---
    ; Searcher robot
    (can-search    ?r - robot)
    (can-stabilize ?r - robot)
    
    ; Rescuer robot
    (can-carry     ?r - robot)
  )


  ; Robot moves between adjacent locations.
  ; Works whether or not the robot is carrying someone.
  ; victim location is tracked by (carrying), not (victim-at), during transport.
  (:action move
    :parameters (?r - robot ?from - location ?to - location)
    :precondition (and
      (robot-at ?r ?from)
      (connected ?from ?to)
    )
    :effect (and
      (robot-at ?r ?to)
      (not (robot-at ?r ?from))
    )
  )

  ; Light robot assesses a room and registers any victim present.
  ; Precondition: robot and victim share a location, victim not yet found.
  (:action search
    :parameters (?r - robot ?v - victim ?l - location)
    :precondition (and
      (can-search ?r)
      (robot-at ?r ?l)
      (victim-at ?v ?l)
      (not (victim-found ?v))
    )
    :effect (victim-found ?v)
  )

  ; Light robot stabilizes a found victim.
  ; Precondition: victim must already be found, enforces search before stabilize.
  (:action stabilize
    :parameters (?r - robot ?v - victim ?l - location)
    :precondition (and
      (can-stabilize ?r)
      (robot-at ?r ?l)
      (victim-at ?v ?l)
      (victim-found ?v)
      (not (victim-stabilized ?v))
    )
    :effect (victim-stabilized ?v)
  )

  ; Heavy robot picks up a stabilized victim.
  ; (victim-stabilized ?v) is the cooperation lock: heavy robot is blocked
  ; until the light robot has completed both search and stabilize.
  ; Effect removes (victim-at), victim location is now implicit in (carrying).
  (:action pickup
    :parameters (?r - robot ?v - victim ?l - location)
    :precondition (and
      (can-carry ?r)
      (robot-at ?r ?l)
      (victim-at ?v ?l)
      (victim-stabilized ?v)
      (not (carrying ?r ?v))
    )
    :effect (and
      (carrying ?r ?v)
      (not (victim-at ?v ?l))
    )
  )

  ; Heavy robot delivers a carried victim to the safe zone.
  ; Restores (victim-at) at the safe zone for bookkeeping and sets rescued.
  (:action rescue
    :parameters (?r - robot ?v - victim ?l - location)
    :precondition (and
      (carrying ?r ?v)
      (robot-at ?r ?l)
      (safe-zone ?l)
    )
    :effect (and
      (victim-rescued ?v)
      (victim-at ?v ?l)
      (not (carrying ?r ?v))
    )
  )

)