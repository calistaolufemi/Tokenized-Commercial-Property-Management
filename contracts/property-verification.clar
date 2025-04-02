;; Property Verification Contract
;; This contract validates ownership and condition of commercial properties

(define-data-var contract-owner principal tx-sender)

;; Property status enum
(define-constant STATUS_PENDING u0)
(define-constant STATUS_VERIFIED u1)
(define-constant STATUS_REJECTED u2)

;; Property data structure
(define-map properties
  { property-id: uint }
  {
    owner: principal,
    address: (string-utf8 256),
    square-footage: uint,
    status: uint,
    verification-date: uint,
    condition-score: uint
  }
)

;; Property ownership tokens
(define-non-fungible-token property-token uint)

;; Initialize a new property
(define-public (register-property (property-id uint) (address (string-utf8 256)) (square-footage uint))
  (let
    ((caller tx-sender))
    (asserts! (is-none (map-get? properties { property-id: property-id })) (err u101))

    (try! (nft-mint? property-token property-id caller))

    (map-set properties
      { property-id: property-id }
      {
        owner: caller,
        address: address,
        square-footage: square-footage,
        status: STATUS_PENDING,
        verification-date: u0,
        condition-score: u0
      }
    )
    (ok property-id)
  )
)

;; Verify a property
(define-public (verify-property (property-id uint) (condition-score uint))
  (let
    ((caller tx-sender)
     (property (unwrap! (map-get? properties { property-id: property-id }) (err u102))))

    (asserts! (is-eq caller (var-get contract-owner)) (err u100))
    (asserts! (<= condition-score u10) (err u103))

    (map-set properties
      { property-id: property-id }
      (merge property {
        status: STATUS_VERIFIED,
        verification-date: block-height,
        condition-score: condition-score
      })
    )
    (ok true)
  )
)

;; Transfer property ownership
(define-public (transfer-property (property-id uint) (recipient principal))
  (let
    ((caller tx-sender)
     (property (unwrap! (map-get? properties { property-id: property-id }) (err u102))))

    (asserts! (is-eq (get owner property) caller) (err u104))
    (try! (nft-transfer? property-token property-id caller recipient))

    (map-set properties
      { property-id: property-id }
      (merge property { owner: recipient })
    )
    (ok true)
  )
)

;; Get property details
(define-read-only (get-property (property-id uint))
  (map-get? properties { property-id: property-id })
)

;; Check if caller is property owner
(define-read-only (is-property-owner (property-id uint) (owner principal))
  (match (map-get? properties { property-id: property-id })
    property (is-eq (get owner property) owner)
    false
  )
)
