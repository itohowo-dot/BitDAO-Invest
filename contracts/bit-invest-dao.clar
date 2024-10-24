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

(define-private (calculate-voting-power (balance uint))
    (/ balance u1000000) ;; 1 voting power per STX
)

;; Public Functions
(define-public (join-dao)
    (let
        (
            (payment (stx-transfer? minimum-membership-fee tx-sender (as-contract tx-sender)))
        )
        (asserts! (is-ok payment) err-insufficient-balance)
        (asserts! (not (is-member tx-sender)) err-already-member)
        
        (map-set members tx-sender
            {
                joined-at: block-height,
                stx-balance: minimum-membership-fee,
                voting-power: (calculate-voting-power minimum-membership-fee),
                proposals-created: u0,
                last-vote-height: u0
            }
        )
        
        (var-set total-members (+ (var-get total-members) u1))
        (var-set treasury-balance (+ (var-get treasury-balance) minimum-membership-fee))
        (ok true)
    )
)

(define-public (create-proposal (title (string-ascii 50)) (description (string-ascii 500)) (amount uint) (recipient principal))
    (let
        (
            (member-data (unwrap! (map-get? members tx-sender) err-not-member))
            (proposal-id (+ (default-to u0 (get proposals-created member-data)) u1))
        )
        (asserts! (<= amount (var-get treasury-balance)) err-insufficient-balance)
        
        (map-set proposals proposal-id
            {
                creator: tx-sender,
                title: title,
                description: description,
                amount: amount,
                recipient: recipient,
                created-at: block-height,
                expires-at: (+ block-height (var-get proposal-duration)),
                yes-votes: u0,
                no-votes: u0,
                executed: false,
                total-votes: u0
            }
        )
        
        (map-set members tx-sender
            (merge member-data 
                {
                    proposals-created: proposal-id
                }
            )
        )
        (ok proposal-id)
    )
)

(define-public (vote-on-proposal (proposal-id uint) (vote-bool bool))
    (let
        (
            (proposal (unwrap! (map-get? proposals proposal-id) err-proposal-not-found))
            (member-data (unwrap! (map-get? members tx-sender) err-not-member))
            (voting-power (get voting-power member-data))
        )
        (asserts! (< block-height (get expires-at proposal)) err-proposal-expired)
        (asserts! (is-none (map-get? votes {proposal-id: proposal-id, voter: tx-sender})) err-already-voted)
        
        (map-set votes {proposal-id: proposal-id, voter: tx-sender}
            {
                vote: vote-bool,
                power: voting-power
            }
        )
        
        (map-set proposals proposal-id
            (merge proposal
                {
                    yes-votes: (if vote-bool (+ (get yes-votes proposal) voting-power) (get yes-votes proposal)),
                    no-votes: (if vote-bool (get no-votes proposal) (+ (get no-votes proposal) voting-power)),
                    total-votes: (+ (get total-votes proposal) voting-power)
                }
            )
        )
        
        (map-set members tx-sender
            (merge member-data
                {
                    last-vote-height: block-height
                }
            )
        )
        (ok true)
    )
)

(define-public (execute-proposal (proposal-id uint))
    (let
        (
            (proposal (unwrap! (map-get? proposals proposal-id) err-proposal-not-found))
            (total-votes (get total-votes proposal))
            (yes-votes (get yes-votes proposal))
        )
        (asserts! (>= block-height (get expires-at proposal)) err-proposal-expired)
        (asserts! (not (get executed proposal)) err-proposal-executed)
        (asserts! (>= (* yes-votes u100) (* total-votes (var-get quorum-threshold))) err-insufficient-quorum)
        
        (try! (as-contract (stx-transfer? (get amount proposal) tx-sender (get recipient proposal))))
        
        (map-set proposals proposal-id
            (merge proposal
                {
                    executed: true
                }
            )
        )
        
        (var-set treasury-balance (- (var-get treasury-balance) (get amount proposal)))
        (ok true)
    )
)

(define-read-only (get-vote (proposal-id uint) (voter principal))
    (map-get? votes {proposal-id: proposal-id, voter: voter})
)

(define-read-only (get-dao-info)
    {
        total-members: (var-get total-members),
        treasury-balance: (var-get treasury-balance),
        minimum-membership-fee: (var-get minimum-membership-fee),
        quorum-threshold: (var-get quorum-threshold)
    }
)