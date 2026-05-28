;;  SEARCH AND RESCUE — PDDL+ DOMAIN
;;
;;  Two heterogeneous robots cooperate to rescue victims:
;;    - search robot: fast, finds and stabilizes victims
;;    - transport robot: slower, carries victims to safety
;;
;;  PDDL+ constructs used:
;;    ACTIONS — agent-controlled, instantaneous decisions
;;    PROCESSES — world-driven continuous change (health, movement)
;;    EVENTS — world-triggered instantaneous transitions
;;
;;  Key modelling choices:
;;    - Health degrades from t=0 for all victims, at rate 2.
;;      Finding a victim does not start the clock, the clock
;;      is already running. This creates urgency for the search
;;      robot to move fast and prioritise correctly.
;;    - Stabilization (search robot only) switches the rate from
;;      2 to 1, buying time for the transport robot to arrive.
;;    - Movement is a genuine PDDL+ process: travel-progress
;;      accumulates continuously, so health degradation and travel
;;      interact in real time.
;;    - Cooperation is structurally required: only the search robot
;;      can find and stabilize; only the transport robot can carry
;;      and deliver. Neither alone can complete a rescue.


(define (domain search-and-rescue)

  (:requirements :typing :fluents :time)

  ;; TYPES
  (:types
    robot victim location - object
  )

  ;; PREDICATES
  (:predicates

    ;; Role constraints, enforces heterogeneity between robots
    (is-search-robot    ?r - robot)
    (is-transport-robot ?r - robot)

    ;; Spatial state
    (at        ?r  - robot    ?l  - location)
    (victim-at ?v  - victim   ?l  - location)
    (adjacent  ?l1 - location ?l2 - location)
    (safe-zone ?l  - location)

    ;; Rescue pipeline: each predicate gates the next action
    ;;   (nothing) -> found -> stabilized -> carrying -> rescued
    (found       ?v - victim)  ;; search robot has located the victim
    (stabilized  ?v - victim)  ;; search robot has performed first aid
    (rescued     ?v - victim)  ;; victim delivered to safe zone
    (victim-lost ?v - victim)  ;; victim died — coordination failure

    ;; Robot operational state
    (carrying        ?r - robot ?v - victim)
    (moving          ?r - robot ?from - location ?to - location)
    (robot-available ?r - robot)
  )

  ;; FUNCTIONS (numeric fluents)
  (:functions
    (health          ?v  - victim)
    (travel-progress ?r  - robot)
    (distance        ?l1 - location ?l2 - location)
    (speed           ?r  - robot)
  )


  ;; ACTIONS
  ;; Instantaneous. The planner decides when to apply these.

  ;; Any robot initiates movement to an adjacent location.
  ;; Activates the robot-traveling process until robot-arrives fires.
  (:action start-move
    :parameters (?r - robot ?from - location ?to - location)
    :precondition (and
      (robot-available ?r)
      (at ?r ?from)
      (adjacent ?from ?to)
    )
    :effect (and
      (not (robot-available ?r))
      (not (at ?r ?from))
      (moving ?r ?from ?to)
      (assign (travel-progress ?r) 0)
    )
  )

  ;; Search robot locates a victim at its current position.
  ;; Does not affect health rate, degradation was already running.
  ;; Sets (found ?v), which is required before stabilization.
  (:action search
    :parameters (?r - robot ?l - location ?v - victim)
    :precondition (and
      (is-search-robot ?r)
      (robot-available ?r)
      (at ?r ?l)
      (victim-at ?v ?l)
      (not (found ?v))
      (not (victim-lost ?v))
    )
    :effect (and
      (found ?v)
    )
  )

  ;; Search robot performs first aid on a found victim.
  ;; Switches health degradation from rate 2 to rate 1 by setting
  ;; (stabilized ?v), which deactivates health-degrading-critical
  ;; and activates health-degrading-stable.
  (:action stabilize
    :parameters (?r - robot ?l - location ?v - victim)
    :precondition (and
      (is-search-robot ?r)
      (robot-available ?r)
      (at ?r ?l)
      (victim-at ?v ?l)
      (found ?v)
      (not (stabilized ?v))
      (not (victim-lost ?v))
    )
    :effect (and
      (stabilized ?v)
    )
  )

  ;; Transport robot picks up a stabilized victim.
  ;; Requires both robots to have acted, enforces cooperation.
  ;; Health continues degrading at rate 1 during transport.
  (:action pickup
    :parameters (?r - robot ?l - location ?v - victim)
    :precondition (and
      (is-transport-robot ?r)
      (robot-available ?r)
      (at ?r ?l)
      (victim-at ?v ?l)
      (stabilized ?v)
      (not (rescued ?v))
      (not (victim-lost ?v))
    )
    :effect (and
      (carrying ?r ?v)
      (not (victim-at ?v ?l))
    )
  )

  ;; Transport robot delivers a victim at the safe zone.
  ;; Sets (rescued ?v), deactivating health-degrading-stable.
  (:action deliver
    :parameters (?r - robot ?l - location ?v - victim)
    :precondition (and
      (is-transport-robot ?r)
      (robot-available ?r)
      (at ?r ?l)
      (safe-zone ?l)
      (carrying ?r ?v)
    )
    :effect (and
      (rescued ?v)
      (not (carrying ?r ?v))
    )
  )


  ;; PROCESSES
  ;; Continuous, world-driven. Active whenever precondition holds.
  ;; Effects use (* #t rate), change per unit time.

  ;; Phase 1: victim not yet stabilized.
  ;; Active from t=0, health degrades regardless of whether
  ;; the victim has been found. Rate 2 creates strong urgency.
  ;; Deactivates the moment (stabilized ?v) becomes true.
  (:process health-degrading-critical
    :parameters (?v - victim)
    :precondition (and
      (not (stabilized ?v))
      (not (victim-lost ?v))
    )
    :effect (and
      (decrease (health ?v) (* #t 2.0))
    )
  )

  ;; Phase 2: victim stabilized but not yet rescued.
  ;; Rate 1, buys time but does not eliminate urgency.
  ;; Also active during transport (carrying does not stop it).
  ;; Deactivates the moment (rescued ?v) becomes true.
  (:process health-degrading-stable
    :parameters (?v - victim)
    :precondition (and
      (stabilized ?v)
      (not (rescued ?v))
      (not (victim-lost ?v))
    )
    :effect (and
      (decrease (health ?v) (* #t 1.0))
    )
  )

  ;; Robot moves continuously toward its destination.
  ;; travel-progress accumulates at the robot's speed.
  ;; Health degradation and travel interact in real time,
  ;; the planner must reason about their concurrent evolution.
  (:process robot-traveling
    :parameters (?r - robot ?from - location ?to - location)
    :precondition (and
      (moving ?r ?from ?to)
    )
    :effect (and
      (increase (travel-progress ?r) (* #t (speed ?r)))
    )
  )


  ;; EVENTS
  ;; Instantaneous, world-triggered. Fire when condition becomes true.
  ;; The planner cannot execute events — it can only avoid them.

  ;; Coordination failure: victim health reached zero.
  ;; Fires regardless of whether the victim has been found,
  ;; a victim can be lost before the search robot even arrives.
  ;; Any valid plan must ensure this never triggers.
  (:event victim-dies
    :parameters (?v - victim)
    :precondition (and
      (not (rescued ?v))
      (not (victim-lost ?v))
      (<= (health ?v) 0)
    )
    :effect (and
      (victim-lost ?v)
    )
  )

  ;; Robot completes its movement when travel-progress covers
  ;; the full distance. Restores availability for the next action.
  (:event robot-arrives
    :parameters (?r - robot ?from - location ?to - location)
    :precondition (and
      (moving ?r ?from ?to)
      (>= (travel-progress ?r) (distance ?from ?to))
    )
    :effect (and
      (at ?r ?to)
      (not (moving ?r ?from ?to))
      (robot-available ?r)
      (assign (travel-progress ?r) 0)
    )
  )

)
