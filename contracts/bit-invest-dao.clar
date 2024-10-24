;; Bitcoin Investment DAO
;; A decentralized autonomous organization for managing Bitcoin investments

;; Error Codes
(define-constant ERR-OWNER-ONLY (err u100))
(define-constant ERR-NOT-MEMBER (err u101))
(define-constant ERR-ALREADY-MEMBER (err u102))
(define-constant ERR-INSUFFICIENT-BALANCE (err u103))
(define-constant ERR-PROPOSAL-NOT-FOUND (err u104))
(define-constant ERR-ALREADY-VOTED (err u105))
(define-constant ERR-PROPOSAL-EXPIRED (err u106))
(define-constant ERR-INSUFFICIENT-QUORUM (err u107))
(define-constant ERR-PROPOSAL-NOT-PASSED (err u108))
(define-constant ERR-INVALID-AMOUNT (err u109))
(define-constant ERR-UNAUTHORIZED (err u110))
(define-constant ERR-PROPOSAL-EXECUTED (err u111))

;; Data Variables
(define-data-var minimum-membership-fee uint u1000000) ;; in microSTX
(define-data-var proposal-duration uint u144) ;; ~1 day in blocks
(define-data-var quorum-threshold uint u51) ;; 51% required for proposal passage
(define-data-var total-members uint u0)
(define-data-var treasury-balance uint u0)
(define-data-var next-proposal-id uint u0)

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
        ERR-NOT-MEMBER
    )
)

(define-private (calculate-voting-power (balance uint))
    (/ balance u1000000) ;; 1 voting power per STX
)

;; Public Functions
(define-public (join-dao)
    (let 
        (
            (membership-fee (var-get minimum-membership-fee))
        )
        ;; Check if not already a member
        (asserts! (not (is-member tx-sender)) ERR-ALREADY-MEMBER)
        ;; Transfer membership fee
        (try! (stx-transfer? membership-fee tx-sender (as-contract tx-sender)))
        
        ;; Add member data
        (map-set members tx-sender
            {
                joined-at: block-height,
                stx-balance: membership-fee,
                voting-power: (calculate-voting-power membership-fee),
                proposals-created: u0,
                last-vote-height: u0
            }
        )
        
        ;; Update DAO stats
        (var-set total-members (+ (var-get total-members) u1))
        (var-set treasury-balance (+ (var-get treasury-balance) membership-fee))
        (ok true)
    )
)

(define-public (create-proposal (title (string-ascii 50)) (description (string-ascii 500)) (amount uint) (recipient principal))
    (let
        (
            (member-data (unwrap! (map-get? members tx-sender) ERR-NOT-MEMBER))
            (proposal-id (var-get next-proposal-id))
        )
        ;; Check if amount is valid
        (asserts! (<= amount (var-get treasury-balance)) ERR-INSUFFICIENT-BALANCE)
        
        ;; Create proposal
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
        
        ;; Update member data and proposal counter
        (map-set members tx-sender
            (merge member-data 
                {
                    proposals-created: (+ (get proposals-created member-data) u1)
                }
            )
        )
        (var-set next-proposal-id (+ proposal-id u1))
        (ok proposal-id)
    )
)

(define-public (vote-on-proposal (proposal-id uint) (vote-bool bool))
    (let
        (
            (proposal (unwrap! (map-get? proposals proposal-id) ERR-PROPOSAL-NOT-FOUND))
            (member-data (unwrap! (map-get? members tx-sender) ERR-NOT-MEMBER))
            (voting-power (get voting-power member-data))
        )
        ;; Check proposal validity
        (asserts! (< block-height (get expires-at proposal)) ERR-PROPOSAL-EXPIRED)
        (asserts! (is-none (map-get? votes {proposal-id: proposal-id, voter: tx-sender})) ERR-ALREADY-VOTED)
        
        ;; Record vote
        (map-set votes {proposal-id: proposal-id, voter: tx-sender}
            {
                vote: vote-bool,
                power: voting-power
            }
        )
        
        ;; Update proposal vote counts
        (map-set proposals proposal-id
            (merge proposal
                {
                    yes-votes: (if vote-bool (+ (get yes-votes proposal) voting-power) (get yes-votes proposal)),
                    no-votes: (if vote-bool (get no-votes proposal) (+ (get no-votes proposal) voting-power)),
                    total-votes: (+ (get total-votes proposal) voting-power)
                }
            )
        )
        
        ;; Update member's last vote
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
            (proposal (unwrap! (map-get? proposals proposal-id) ERR-PROPOSAL-NOT-FOUND))
            (total-votes (get total-votes proposal))
            (yes-votes (get yes-votes proposal))
        )
        ;; Check proposal status
        (asserts! (>= block-height (get expires-at proposal)) ERR-PROPOSAL-EXPIRED)
        (asserts! (not (get executed proposal)) ERR-PROPOSAL-EXECUTED)
        (asserts! (>= (* yes-votes u100) (* total-votes (var-get quorum-threshold))) ERR-INSUFFICIENT-QUORUM)
        
        ;; Execute transfer
        (try! (as-contract (stx-transfer? (get amount proposal) tx-sender (get recipient proposal))))
        
        ;; Update proposal status
        (map-set proposals proposal-id
            (merge proposal
                {
                    executed: true
                }
            )
        )
        
        ;; Update treasury
        (var-set treasury-balance (- (var-get treasury-balance) (get amount proposal)))
        (ok true)
    )
)

;; Read-only Functions
(define-read-only (get-proposal (proposal-id uint))
    (map-get? proposals proposal-id)
)

(define-read-only (get-member (address principal))
    (map-get? members address)
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