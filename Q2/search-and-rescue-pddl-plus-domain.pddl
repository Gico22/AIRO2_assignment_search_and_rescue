;;  SEARCH AND RESCUE — PDDL+ DOMAIN
;;
;;  Two heterogeneous robots cooperate to rescue victims:
;;    - search robot: fast, finds and stabilizes victims
;;    - rescue robot: slower, carries victims to safety
;;
;;  PDDL+ constructs used:
;;    ACTIONS   — agent-controlled, instantaneous decisions
;;    PROCESSES — world-driven continuous change (health, movement)
;;    EVENTS    — world-triggered instantaneous transitions
;;
;;  Key modelling choices:
;;    - Health degrades from t=0 for all victims, at rate 2.
;;      The clock is already running before any robot acts.
;;    - Stabilization (search robot only) switches rate 2 → 1,
;;      buying time for the rescue robot to arrive.
;;    - victim-in-area is a static fact known at planning time.
;;      victim-at is only set by the search action, modelling
;;      that the rescue robot cannot navigate to a victim until
;;      the search robot has confirmed the exact location.
;;    - Movement is a PDDL+ process: travel-progress accumulates
;;      continuously, interacting with health degradation in real time.
;;    - Cooperation is structurally required: only the search robot
;;      can find and stabilize; only the rescue robot can carry
;;      and deliver. Neither alone can complete a rescue.

(define (domain search-and-rescue-time-coordination)

  (:requirements :typing :fluents :time)

  (:types
    robot victim location - object
  )

  (:predicates

    ;; Role constraints
    (is-search-robot ?r - robot)
    (is-rescue-robot ?r - robot)

    ;; Spatial state
    (at        ?r  - robot    ?l  - location)
    (connected ?l1 - location ?l2 - location)
    (safe-zone ?l  - location)

    ;; victim-in-area: static, set in problem init.
    ;; Encodes that a victim exists somewhere in that zone,
    ;; but exact position is not yet confirmed.
    (victim-in-area ?v - victim ?l - location)

    ;; victim-at: dynamic, set only by the search action.
    ;; Confirmed exact location — required for stabilize and pickup.
    ;; The rescue robot has no destination until this is true.
    (victim-at ?v - victim ?l - location)

    ;; Rescue pipeline: each predicate gates the next action
    ;;   (nothing) -> found -> stabilized -> carrying -> rescued
    (found       ?v - victim)
    (stabilized  ?v - victim)
    (rescued     ?v - victim)
    (victim-lost ?v - victim)

    ;; Robot operational state
    (carrying        ?r - robot ?v - victim)
    (moving          ?r - robot ?from - location ?to - location)
    (robot-available ?r - robot)
  )

  (:functions
    (health          ?v  - victim)
    (travel-progress ?r  - robot)
    (distance        ?l1 - location ?l2 - location)
    (speed           ?r  - robot)
  )


  ;; ============================================================
  ;; ACTIONS
  ;; ============================================================

  (:action start-move
    :parameters (?r - robot ?from - location ?to - location)
    :precondition (and
      (robot-available ?r)
      (at ?r ?from)
      (connected ?from ?to)
    )
    :effect (and
      (not (robot-available ?r))
      (not (at ?r ?from))
      (moving ?r ?from ?to)
      (assign (travel-progress ?r) 0)
    )
  )

  ;; Search robot physically locates the victim.
  ;; Sets victim-at, enabling stabilize and pickup.
  ;; Uses victim-in-area as precondition — the zone was known,
  ;; but exact location is confirmed only upon arrival.
  (:action search
    :parameters (?r - robot ?l - location ?v - victim)
    :precondition (and
      (is-search-robot ?r)
      (robot-available ?r)
      (at ?r ?l)
      (victim-in-area ?v ?l)
      (not (found ?v))
      (not (victim-lost ?v))
    )
    :effect (and
      (found ?v)
      (victim-at ?v ?l)
    )
  )

  ;; Search robot performs first aid. Switches health rate 2 → 1.
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

  ;; Rescue robot picks up a stabilized victim.
  ;; Requires victim-at — only reachable after search has run.
  (:action pickup
    :parameters (?r - robot ?l - location ?v - victim)
    :precondition (and
      (is-rescue-robot ?r)
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

  ;; Rescue robot delivers victim at safe zone.
  (:action deliver
    :parameters (?r - robot ?l - location ?v - victim)
    :precondition (and
      (is-rescue-robot ?r)
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


  ;; ============================================================
  ;; PROCESSES
  ;; ============================================================

  ;; Phase 1: active from t=0, rate 2. Deactivates on stabilization.
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

  ;; Phase 2: active after stabilization, rate 1. Deactivates on rescue.
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

  ;; Robot moves continuously. Health and travel interact in real time.
  (:process robot-traveling
    :parameters (?r - robot ?from - location ?to - location)
    :precondition (and
      (moving ?r ?from ?to)
    )
    :effect (and
      (increase (travel-progress ?r) (* #t (speed ?r)))
    )
  )


  ;; ============================================================
  ;; EVENTS
  ;; ============================================================

  ;; Coordination failure. Any valid plan must ensure this never fires.
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

  ;; Robot completes movement. Restores availability.
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
