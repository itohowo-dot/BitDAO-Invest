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