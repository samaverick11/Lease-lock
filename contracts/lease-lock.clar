;; LeaseLock - Trustless NFT rental marketplace (Corrected)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Errors
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define-constant ERR_NOT_OWNER (err u100))
(define-constant ERR_NOT_LISTED (err u101))
(define-constant ERR_ALREADY_RENTED (err u102))
(define-constant ERR_INSUFFICIENT_PAYMENT (err u103))
(define-constant ERR_NOT_RENTER (err u104))
(define-constant ERR_NOT_EXPIRED (err u105))
(define-constant ERR_NO_COLLATERAL (err u106))
(define-constant ERR_INVALID_PARAM (err u107))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Data structures
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define-data-var next-listing-id uint u1)

(define-map listings
  { listing-id: uint }
  {
    nft-contract: principal,
    token-id: uint,
    owner: principal,
    price: uint,
    collateral: uint,
    duration: uint,
    active: bool
  })

(define-map rentals
  { listing-id: uint }
  {
    renter: principal,
    rented-at-block: uint,
    expires-at-block: uint,
    collateral: uint,
    paid: uint
  })

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Public API
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define-public (create-listing (nft-contract principal) (token-id uint) (price uint) (collateral uint) (duration uint))
  (begin
    (asserts! (> price u0) ERR_INVALID_PARAM)
    (asserts! (> duration u0) ERR_INVALID_PARAM)

    (let ((id (var-get next-listing-id)))
      (map-set listings { listing-id: id } {
        nft-contract: nft-contract,
        token-id: token-id,
        owner: tx-sender,
        price: price,
        collateral: collateral,
        duration: duration,
        active: true
      })
      (var-set next-listing-id (+ id u1))
      (ok id)
    )
  )
)

(define-public (cancel-listing (listing-id uint))
  (let ((listing (unwrap! (map-get? listings { listing-id: listing-id }) ERR_NOT_LISTED)))
    (asserts! (is-eq (get owner listing) tx-sender) ERR_NOT_OWNER)
    (asserts! (is-none (map-get? rentals { listing-id: listing-id })) ERR_ALREADY_RENTED)
    (map-delete listings { listing-id: listing-id })
    (ok true)
  )
)

;; Rent an available listing
(define-public (rent (listing-id uint))
  (let (
    (listing (unwrap! (map-get? listings { listing-id: listing-id }) ERR_NOT_LISTED))
    (price (get price listing))
    (coll (get collateral listing))
    (dur (get duration listing))
  )
    ;; 1. Validation
    (asserts! (get active listing) ERR_NOT_LISTED)
    (asserts! (is-none (map-get? rentals { listing-id: listing-id })) ERR_ALREADY_RENTED)

    ;; 2. Payment Transfers
    (try! (stx-transfer? price tx-sender (get owner listing)))
    
    ;; FIXED: Both arms now return a boolean. 
    ;; (try! (stx-transfer? ...)) returns the inner 'bool' on success.
    (if (> coll u0)
        (try! (stx-transfer? coll tx-sender (as-contract tx-sender)))
        true 
    )

    ;; 3. Update State
    (let (
      (now stacks-block-height)
      (expires (+ stacks-block-height dur))
    )
      (map-set rentals { listing-id: listing-id } {
        renter: tx-sender,
        rented-at-block: now,
        expires-at-block: expires,
        collateral: coll,
        paid: price
      })
      (map-set listings { listing-id: listing-id } (merge listing { active: false }))
      (ok true)
    )
  )
)

;; Reclaim NFT after expiry
(define-public (reclaim (listing-id uint))
  (let (
    (rental (unwrap! (map-get? rentals { listing-id: listing-id }) ERR_NOT_LISTED))
    (listing (unwrap! (map-get? listings { listing-id: listing-id }) ERR_NOT_LISTED))
  )
    (asserts! (is-eq (get owner listing) tx-sender) ERR_NOT_OWNER)
    (asserts! (<= (get expires-at-block rental) stacks-block-height) ERR_NOT_EXPIRED)

    ;; FIXED: Ensure arms match (both bool)
    (if (> (get collateral rental) u0)
        (try! (as-contract (stx-transfer? (get collateral rental) tx-sender (get renter rental))))
        true
    )

    (map-delete rentals { listing-id: listing-id })
    (map-set listings { listing-id: listing-id } (merge listing { active: true }))
    (ok true)
  )
)

;; Owner claims collateral if renter misbehaves
(define-public (claim-collateral (listing-id uint))
  (let (
    (rental (unwrap! (map-get? rentals { listing-id: listing-id }) ERR_NOT_LISTED))
    (listing (unwrap! (map-get? listings { listing-id: listing-id }) ERR_NOT_LISTED))
  )
    (asserts! (is-eq (get owner listing) tx-sender) ERR_NOT_OWNER)
    (asserts! (>= stacks-block-height (get expires-at-block rental)) ERR_NOT_EXPIRED)
    (asserts! (> (get collateral rental) u0) ERR_NO_COLLATERAL)

    (try! (as-contract (stx-transfer? (get collateral rental) tx-sender (get owner listing))))
    
    (map-delete rentals { listing-id: listing-id })
    (map-set listings { listing-id: listing-id } (merge listing { active: true }))
    (ok true)
  )
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Read-only helpers
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define-read-only (get-listing (listing-id uint))
  (map-get? listings { listing-id: listing-id }))

(define-read-only (get-rental (listing-id uint))
  (map-get? rentals { listing-id: listing-id }))

(define-read-only (is-leased (listing-id uint))
  (match (map-get? rentals { listing-id: listing-id })
    rental (ok (< stacks-block-height (get expires-at-block rental)))
    (ok false)))