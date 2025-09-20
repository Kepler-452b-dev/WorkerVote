
;; title: WorkerVote
;; version: 1.0.0
;; summary: A secure platform for workplace democracy and union contract ratification
;; description: This contract enables workers to create and vote on workplace proposals,
;;              including union contract ratifications, with secure identity verification
;;              and transparent voting processes.

;; traits
;;

;; token definitions
;;

;; constants
;;
(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u100))
(define-constant ERR_PROPOSAL_NOT_FOUND (err u101))
(define-constant ERR_PROPOSAL_ENDED (err u102))
(define-constant ERR_ALREADY_VOTED (err u103))
(define-constant ERR_NOT_ELIGIBLE (err u104))
(define-constant ERR_INVALID_PROPOSAL (err u105))
(define-constant ERR_PROPOSAL_ACTIVE (err u106))

;; data vars
;;
(define-data-var next-proposal-id uint u1)
(define-data-var admin principal CONTRACT_OWNER)

;; data maps
;;
;; Worker eligibility mapping
(define-map eligible-workers principal bool)

;; Proposal structure
(define-map proposals uint {
  title: (string-ascii 100),
  description: (string-ascii 500),
  creator: principal,
  start-block: uint,
  end-block: uint,
  yes-votes: uint,
  no-votes: uint,
  total-eligible: uint,
  proposal-type: (string-ascii 20), ;; "contract", "policy", "general"
  status: (string-ascii 10) ;; "active", "passed", "failed", "cancelled"
})

;; Track individual votes
(define-map votes {proposal-id: uint, voter: principal} {vote: bool, block-height: uint})

;; Track vote participation
(define-map voter-participation {proposal-id: uint, voter: principal} bool)

;; public functions
;;

;; Admin function to add eligible workers
(define-public (add-eligible-worker (worker principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) ERR_UNAUTHORIZED)
    (ok (map-set eligible-workers worker true))
  )
)

;; Admin function to remove eligible workers
(define-public (remove-eligible-worker (worker principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) ERR_UNAUTHORIZED)
    (ok (map-delete eligible-workers worker))
  )
)

;; Function to create a new proposal
(define-public (create-proposal
  (title (string-ascii 100))
  (description (string-ascii 500))
  (duration-blocks uint)
  (proposal-type (string-ascii 20)))
  (let
    (
      (proposal-id (var-get next-proposal-id))
      (start-block block-height)
      (end-block (+ block-height duration-blocks))
      (eligible-count (get-eligible-worker-count))
    )
    (asserts! (is-eligible-worker tx-sender) ERR_NOT_ELIGIBLE)
    (asserts! (> duration-blocks u0) ERR_INVALID_PROPOSAL)
    (asserts! (> (len title) u0) ERR_INVALID_PROPOSAL)

    (map-set proposals proposal-id {
      title: title,
      description: description,
      creator: tx-sender,
      start-block: start-block,
      end-block: end-block,
      yes-votes: u0,
      no-votes: u0,
      total-eligible: eligible-count,
      proposal-type: proposal-type,
      status: "active"
    })

    (var-set next-proposal-id (+ proposal-id u1))
    (ok proposal-id)
  )
)

;; Function to cast a vote
(define-public (cast-vote (proposal-id uint) (vote bool))
  (let
    (
      (proposal (unwrap! (map-get? proposals proposal-id) ERR_PROPOSAL_NOT_FOUND))
      (voter-key {proposal-id: proposal-id, voter: tx-sender})
    )
    (asserts! (is-eligible-worker tx-sender) ERR_NOT_ELIGIBLE)
    (asserts! (is-none (map-get? votes voter-key)) ERR_ALREADY_VOTED)
    (asserts! (<= block-height (get end-block proposal)) ERR_PROPOSAL_ENDED)
    (asserts! (is-eq (get status proposal) "active") ERR_PROPOSAL_ENDED)

    ;; Record the vote
    (map-set votes voter-key {vote: vote, block-height: block-height})
    (map-set voter-participation voter-key true)

    ;; Update vote counts
    (if vote
      (map-set proposals proposal-id (merge proposal {yes-votes: (+ (get yes-votes proposal) u1)}))
      (map-set proposals proposal-id (merge proposal {no-votes: (+ (get no-votes proposal) u1)}))
    )

    (ok true)
  )
)

;; Function to finalize a proposal (can be called by anyone after end block)
(define-public (finalize-proposal (proposal-id uint))
  (let
    (
      (proposal (unwrap! (map-get? proposals proposal-id) ERR_PROPOSAL_NOT_FOUND))
      (total-votes (+ (get yes-votes proposal) (get no-votes proposal)))
      (majority-threshold (/ (get total-eligible proposal) u2))
    )
    (asserts! (> block-height (get end-block proposal)) ERR_PROPOSAL_ACTIVE)
    (asserts! (is-eq (get status proposal) "active") ERR_PROPOSAL_ENDED)

    ;; Determine if proposal passed (simple majority of eligible voters)
    (let
      (
        (new-status
          (if (and (> (get yes-votes proposal) (get no-votes proposal))
                   (> (get yes-votes proposal) majority-threshold))
            "passed"
            "failed"
          )
        )
      )
      (map-set proposals proposal-id (merge proposal {status: new-status}))
      (ok new-status)
    )
  )
)

;; Admin function to cancel a proposal
(define-public (cancel-proposal (proposal-id uint))
  (let
    (
      (proposal (unwrap! (map-get? proposals proposal-id) ERR_PROPOSAL_NOT_FOUND))
    )
    (asserts! (is-eq tx-sender (var-get admin)) ERR_UNAUTHORIZED)
    (asserts! (is-eq (get status proposal) "active") ERR_PROPOSAL_ENDED)

    (map-set proposals proposal-id (merge proposal {status: "cancelled"}))
    (ok true)
  )
)

;; Function to transfer admin rights
(define-public (transfer-admin (new-admin principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) ERR_UNAUTHORIZED)
    (var-set admin new-admin)
    (ok true)
  )
)

;; read only functions
;;

;; Check if a worker is eligible to vote
(define-read-only (is-eligible-worker (worker principal))
  (default-to false (map-get? eligible-workers worker))
)

;; Get proposal details
(define-read-only (get-proposal (proposal-id uint))
  (map-get? proposals proposal-id)
)

;; Get a voter's vote for a specific proposal
(define-read-only (get-vote (proposal-id uint) (voter principal))
  (map-get? votes {proposal-id: proposal-id, voter: voter})
)

;; Check if a voter has voted on a proposal
(define-read-only (has-voted (proposal-id uint) (voter principal))
  (is-some (map-get? voter-participation {proposal-id: proposal-id, voter: voter}))
)

;; Get current proposal ID counter
(define-read-only (get-next-proposal-id)
  (var-get next-proposal-id)
)

;; Get current admin
(define-read-only (get-admin)
  (var-get admin)
)

;; Get proposal results
(define-read-only (get-proposal-results (proposal-id uint))
  (match (map-get? proposals proposal-id)
    proposal (some {
      yes-votes: (get yes-votes proposal),
      no-votes: (get no-votes proposal),
      total-eligible: (get total-eligible proposal),
      status: (get status proposal),
      participation-rate: (/ (* (+ (get yes-votes proposal) (get no-votes proposal)) u100) (get total-eligible proposal))
    })
    none
  )
)

;; Check if proposal is active
(define-read-only (is-proposal-active (proposal-id uint))
  (match (map-get? proposals proposal-id)
    proposal (and
      (is-eq (get status proposal) "active")
      (<= block-height (get end-block proposal))
    )
    false
  )
)

;; private functions
;;

;; Count eligible workers (simplified version - in production might use a more efficient approach)
(define-private (get-eligible-worker-count)
  ;; This is a simplified implementation
  ;; In a real scenario, you might want to track this more efficiently
  u100  ;; Placeholder - return estimated worker count
)

;; Initialize the contract by making the deployer an eligible worker
(map-set eligible-workers CONTRACT_OWNER true)
