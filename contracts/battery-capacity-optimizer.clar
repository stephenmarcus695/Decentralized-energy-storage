;; Battery Capacity Optimizer Contract
;; Monitors battery levels in real-time, coordinates grid services provision,
;; manages demand response participation, and distributes compensation payments

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-authorized (err u101))
(define-constant err-invalid-data (err u102))
(define-constant err-battery-not-found (err u103))
(define-constant err-insufficient-capacity (err u104))
(define-constant err-below-minimum-reserve (err u105))
(define-constant err-already-registered (err u106))
(define-constant err-inactive-battery (err u107))
(define-constant err-no-earnings (err u108))

;; Minimum reserve threshold (30% = 30)
(define-constant MIN-RESERVE-PERCENT u30)

;; Battery status constants
(define-constant STATUS-ACTIVE u1)
(define-constant STATUS-INACTIVE u2)
(define-constant STATUS-MAINTENANCE u3)

;; Data Variables
(define-data-var next-battery-id uint u0)
(define-data-var next-dispatch-id uint u0)
(define-data-var total-network-capacity uint u0)
(define-data-var total-available-capacity uint u0)
(define-data-var base-rate-per-kwh uint u50) ;; In cents, so 50 = $0.50
(define-data-var availability-payment uint u10) ;; $10 per month
(define-data-var dr-event-bonus uint u25) ;; $25 per DR event

;; Maps
(define-map batteries
  uint
  {
    owner: principal,
    capacity-kwh: uint, ;; Total capacity in kWh * 100 for precision
    current-level: uint, ;; Current charge level (0-10000 = 0-100%)
    minimum-reserve: uint, ;; Minimum % to maintain (0-10000)
    status: uint,
    device-address: (string-ascii 100),
    registered-at: uint,
    last-updated: uint,
    total-dispatched: uint, ;; Total kWh dispatched * 100
    participation-count: uint
  }
)

(define-map battery-owners
  principal
  uint ;; battery-id
)

(define-map dispatch-events
  uint
  {
    battery-id: uint,
    energy-kwh: uint, ;; kWh * 100
    compensation: uint, ;; Amount in cents
    timestamp: uint,
    event-type: (string-ascii 20), ;; "peak-demand", "dr-event", "frequency-reg"
    completed: bool
  }
)

(define-map battery-earnings
  uint ;; battery-id
  {
    total-earned: uint, ;; Total earnings in cents
    available-balance: uint, ;; Unclaimed earnings
    last-claim: uint,
    total-claimed: uint
  }
)

(define-map utility-partners
  principal
  {
    name: (string-ascii 50),
    is-active: bool,
    registered-at: uint
  }
)

(define-map grid-parameters
  (string-ascii 20)
  uint
)

;; Initialize contract
(begin
  (map-set utility-partners contract-owner
    {
      name: "System Operator",
      is-active: true,
      registered-at: burn-block-height
    }
  )
  (map-set grid-parameters "peak-threshold" u8000) ;; 80% grid utilization
  (map-set grid-parameters "dispatch-min-kwh" u500) ;; 5 kWh minimum dispatch
)

;; Public Functions

;; Register a new battery in the network
(define-public (register-battery 
  (capacity-kwh uint) 
  (device-address (string-ascii 100)))
  (let
    (
      (battery-id (var-get next-battery-id))
      (existing-battery (map-get? battery-owners tx-sender))
    )
    (asserts! (is-none existing-battery) err-already-registered)
    (asserts! (>= capacity-kwh u500) err-invalid-data) ;; Minimum 5 kWh
    
    (map-set batteries battery-id
      {
        owner: tx-sender,
        capacity-kwh: capacity-kwh,
        current-level: u10000, ;; Start at 100%
        minimum-reserve: (* MIN-RESERVE-PERCENT u100),
        status: STATUS-ACTIVE,
        device-address: device-address,
        registered-at: burn-block-height,
        last-updated: burn-block-height,
        total-dispatched: u0,
        participation-count: u0
      }
    )
    
    (map-set battery-owners tx-sender battery-id)
    
    (map-set battery-earnings battery-id
      {
        total-earned: u0,
        available-balance: u0,
        last-claim: burn-block-height,
        total-claimed: u0
      }
    )
    
    (var-set total-network-capacity (+ (var-get total-network-capacity) capacity-kwh))
    (var-set next-battery-id (+ battery-id u1))
    (ok battery-id)
  )
)

;; Update battery charge level
(define-public (update-battery-level (battery-id uint) (new-level uint))
  (let
    (
      (battery (unwrap! (map-get? batteries battery-id) err-battery-not-found))
    )
    (asserts! (is-eq tx-sender (get owner battery)) err-not-authorized)
    (asserts! (<= new-level u10000) err-invalid-data) ;; Max 100%
    
    (ok (map-set batteries battery-id
      (merge battery {
        current-level: new-level,
        last-updated: burn-block-height
      })
    ))
  )
)

;; Set minimum reserve for a battery
(define-public (set-minimum-reserve (battery-id uint) (reserve-percent uint))
  (let
    (
      (battery (unwrap! (map-get? batteries battery-id) err-battery-not-found))
    )
    (asserts! (is-eq tx-sender (get owner battery)) err-not-authorized)
    (asserts! (and (>= reserve-percent u2000) (<= reserve-percent u8000)) err-invalid-data) ;; 20-80%
    
    (ok (map-set batteries battery-id
      (merge battery { minimum-reserve: reserve-percent })
    ))
  )
)

;; Deactivate battery from grid services
(define-public (deactivate-battery (battery-id uint))
  (let
    (
      (battery (unwrap! (map-get? batteries battery-id) err-battery-not-found))
    )
    (asserts! (or (is-eq tx-sender (get owner battery)) 
                  (is-eq tx-sender contract-owner)) 
              err-not-authorized)
    
    (ok (map-set batteries battery-id
      (merge battery { status: STATUS-INACTIVE })
    ))
  )
)

;; Reactivate battery
(define-public (reactivate-battery (battery-id uint))
  (let
    (
      (battery (unwrap! (map-get? batteries battery-id) err-battery-not-found))
    )
    (asserts! (is-eq tx-sender (get owner battery)) err-not-authorized)
    
    (ok (map-set batteries battery-id
      (merge battery { status: STATUS-ACTIVE })
    ))
  )
)

;; Dispatch energy from battery during grid event
(define-public (dispatch-energy 
  (battery-id uint) 
  (energy-kwh uint)
  (event-type (string-ascii 20)))
  (let
    (
      (battery (unwrap! (map-get? batteries battery-id) err-battery-not-found))
      (dispatch-id (var-get next-dispatch-id))
      (available-energy (calculate-available-energy 
        (get capacity-kwh battery)
        (get current-level battery)
        (get minimum-reserve battery)))
      (compensation (calculate-compensation energy-kwh event-type))
      (earnings (default-to 
        { total-earned: u0, available-balance: u0, last-claim: u0, total-claimed: u0 }
        (map-get? battery-earnings battery-id)))
    )
    (asserts! (is-eq (get status battery) STATUS-ACTIVE) err-inactive-battery)
    (asserts! (>= available-energy energy-kwh) err-insufficient-capacity)
    
    ;; Record dispatch event
    (map-set dispatch-events dispatch-id
      {
        battery-id: battery-id,
        energy-kwh: energy-kwh,
        compensation: compensation,
        timestamp: burn-block-height,
        event-type: event-type,
        completed: true
      }
    )
    
    ;; Update battery stats
    (map-set batteries battery-id
      (merge battery {
        total-dispatched: (+ (get total-dispatched battery) energy-kwh),
        participation-count: (+ (get participation-count battery) u1),
        last-updated: burn-block-height
      })
    )
    
    ;; Update earnings
    (map-set battery-earnings battery-id
      {
        total-earned: (+ (get total-earned earnings) compensation),
        available-balance: (+ (get available-balance earnings) compensation),
        last-claim: (get last-claim earnings),
        total-claimed: (get total-claimed earnings)
      }
    )
    
    (var-set next-dispatch-id (+ dispatch-id u1))
    (ok dispatch-id)
  )
)

;; Claim earnings
(define-public (claim-rewards (battery-id uint))
  (let
    (
      (battery (unwrap! (map-get? batteries battery-id) err-battery-not-found))
      (earnings (unwrap! (map-get? battery-earnings battery-id) err-no-earnings))
      (claimable (get available-balance earnings))
    )
    (asserts! (is-eq tx-sender (get owner battery)) err-not-authorized)
    (asserts! (> claimable u0) err-no-earnings)
    
    (map-set battery-earnings battery-id
      (merge earnings {
        available-balance: u0,
        last-claim: burn-block-height,
        total-claimed: (+ (get total-claimed earnings) claimable)
      })
    )
    
    (ok claimable)
  )
)

;; Register utility partner
(define-public (register-utility (utility principal) (name (string-ascii 50)))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (ok (map-set utility-partners utility
      {
        name: name,
        is-active: true,
        registered-at: burn-block-height
      }
    ))
  )
)

;; Update service rates
(define-public (set-service-rates 
  (base-rate uint)
  (availability uint)
  (dr-bonus uint))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (var-set base-rate-per-kwh base-rate)
    (var-set availability-payment availability)
    (var-set dr-event-bonus dr-bonus)
    (ok true)
  )
)

;; Update grid parameters
(define-public (update-grid-parameter (param (string-ascii 20)) (value uint))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (ok (map-set grid-parameters param value))
  )
)

;; Read-only functions

;; Get battery status
(define-read-only (get-battery-status (battery-id uint))
  (map-get? batteries battery-id)
)

;; Get battery by owner
(define-read-only (get-battery-by-owner (owner principal))
  (match (map-get? battery-owners owner)
    battery-id (map-get? batteries battery-id)
    none
  )
)

;; Get earnings summary
(define-read-only (get-earnings-summary (battery-id uint))
  (map-get? battery-earnings battery-id)
)

;; Get dispatch event
(define-read-only (get-dispatch-event (dispatch-id uint))
  (map-get? dispatch-events dispatch-id)
)

;; Get network capacity
(define-read-only (get-network-capacity)
  (ok {
    total: (var-get total-network-capacity),
    available: (var-get total-available-capacity)
  })
)

;; Check battery availability for dispatch
(define-read-only (check-availability (battery-id uint) (required-kwh uint))
  (match (map-get? batteries battery-id)
    battery
    (let
      (
        (available (calculate-available-energy 
          (get capacity-kwh battery)
          (get current-level battery)
          (get minimum-reserve battery)))
      )
      (ok (and 
        (is-eq (get status battery) STATUS-ACTIVE)
        (>= available required-kwh)
      ))
    )
    (err err-battery-not-found)
  )
)

;; Get utility partner info
(define-read-only (get-utility-partner (utility principal))
  (map-get? utility-partners utility)
)

;; Get grid parameter
(define-read-only (get-grid-parameter (param (string-ascii 20)))
  (map-get? grid-parameters param)
)

;; Get service rates
(define-read-only (get-service-rates)
  (ok {
    base-rate: (var-get base-rate-per-kwh),
    availability: (var-get availability-payment),
    dr-bonus: (var-get dr-event-bonus)
  })
)

;; Private functions

;; Calculate available energy above minimum reserve
(define-private (calculate-available-energy 
  (capacity uint)
  (current-level uint)
  (min-reserve uint))
  (let
    (
      (current-kwh (/ (* capacity current-level) u10000))
      (reserve-kwh (/ (* capacity min-reserve) u10000))
    )
    (if (> current-kwh reserve-kwh)
      (- current-kwh reserve-kwh)
      u0
    )
  )
)

;; Calculate compensation for energy dispatch
(define-private (calculate-compensation (energy-kwh uint) (event-type (string-ascii 20)))
  (let
    (
      (base-comp (/ (* energy-kwh (var-get base-rate-per-kwh)) u100))
      (bonus (if (is-eq event-type "dr-event")
        (var-get dr-event-bonus)
        u0))
    )
    (+ base-comp bonus)
  )
)

;; Calculate current charge percentage
(define-private (get-charge-percentage (current-level uint))
  (/ current-level u100) ;; Convert from 0-10000 to 0-100
)

;; title: battery-capacity-optimizer
;; version:
;; summary:
;; description:

;; traits
;;

;; token definitions
;;

;; constants
;;

;; data vars
;;

;; data maps
;;

;; public functions
;;

;; read only functions
;;

;; private functions
;;

