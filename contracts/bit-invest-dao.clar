;; Bitcoin Investment DAO
;; A decentralized autonomous organization for managing Bitcoin investments

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-member (err u101))
(define-constant err-already-member (err u102))
(define-constant err-insufficient-balance (err u103))
(define-constant err-proposal-not-found (err u104))
(define-constant err-already-voted (err u105))
(define-constant err-proposal-expired (err u106))
(define-constant err-insufficient-quorum (err u107))
(define-constant err-proposal-not-passed (err u108))
(define-constant err-invalid-amount (err u109))
(define-constant err-unauthorized (err u110))

;; Data Variables
(define-data-var minimum-membership-fee uint u1000000) ;; in microSTX
(define-data-var proposal-duration uint u144) ;; ~1 day in blocks
(define-data-var quorum-threshold uint u51) ;; 51% required for proposal passage
(define-data-var total-members uint u0)
(define-data-var treasury-balance uint u0)

;; Data Maps
(define-map members principal 
    {
        joined-at: uint,
        stx-balance: uint,
        voting-power: uint,
        proposals-created: uint,
        last-vote-height: uint
    }
)

(define-map proposals uint 
    {
        creator: principal,
        title: (string-ascii 50),
        description: (string-ascii 500),
        amount: uint,
        recipient: principal,
        created-at: uint,
        expires-at: uint,
        yes-votes: uint,
        no-votes: uint,
        executed: bool,
        total-votes: uint
    }
)

(define-map votes {proposal-id: uint, voter: principal} 
    {
        vote: bool,
        power: uint
    }
)

;; Private Functions
(define-private (is-member (address principal))
    (is-some (map-get? members address))
)

(define-private (check-is-member (address principal))
    (if (is-member address)
        (ok true)
        err-not-member
    )
)