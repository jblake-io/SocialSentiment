
;; title: SocialSentiment
;; version: 1.0.0
;; summary: A synthetic assets smart contract tracking social media sentiment and its market impact
;; description: This contract allows users to submit social sentiment data, creates synthetic assets based on sentiment scores, and tracks market impact

;; traits
(define-trait sentiment-oracle-trait
  (
    (submit-sentiment (uint uint) (response bool uint))
    (get-sentiment (uint) (response (optional uint) uint))
  )
)

;; token definitions
(define-fungible-token synthetic-asset)

;; constants
(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-OWNER-ONLY (err u100))
(define-constant ERR-INVALID-SENTIMENT (err u101))
(define-constant ERR-ASSET-NOT-FOUND (err u102))
(define-constant ERR-INSUFFICIENT-BALANCE (err u103))
(define-constant ERR-INVALID-AMOUNT (err u104))
(define-constant ERR-SENTIMENT-EXISTS (err u105))
(define-constant ERR-UNAUTHORIZED (err u106))

(define-constant MIN-SENTIMENT u0)
(define-constant MAX-SENTIMENT u100)
(define-constant ASSET-PRECISION u1000000) ;; 6 decimal places

;; data vars
(define-data-var contract-active bool true)
(define-data-var total-assets uint u0)
(define-data-var sentiment-count uint u0)
(define-data-var oracle-fee uint u1000) ;; 0.001 STX in microSTX

;; data maps
;; Store sentiment data for specific topics/assets
(define-map sentiment-data
  { topic-id: uint }
  {
    sentiment-score: uint,
    submission-count: uint,
    last-updated: uint,
    weighted-average: uint,
    market-impact: int
  }
)

;; Store synthetic assets created based on sentiment
(define-map synthetic-assets
  { asset-id: uint }
  {
    topic-id: uint,
    total-supply: uint,
    base-price: uint,
    current-multiplier: uint,
    created-at: uint,
    active: bool
  }
)

;; Track user sentiment submissions
(define-map user-submissions
  { user: principal, topic-id: uint }
  {
    sentiment-score: uint,
    weight: uint,
    submitted-at: uint
  }
)

;; Store oracle addresses authorized to submit sentiment
(define-map authorized-oracles
  { oracle: principal }
  { authorized: bool }
)

;; Track user balances for synthetic assets
(define-map user-asset-balances
  { user: principal, asset-id: uint }
  { balance: uint }
)

;; public functions

;; Initialize or update sentiment data for a topic
(define-public (submit-sentiment (topic-id uint) (sentiment-score uint))
  (let (
    (sender tx-sender)
    (current-height block-height)
  )
    (asserts! (var-get contract-active) ERR-UNAUTHORIZED)
    (asserts! (and (>= sentiment-score MIN-SENTIMENT) (<= sentiment-score MAX-SENTIMENT)) ERR-INVALID-SENTIMENT)

    ;; Update or create sentiment data
    (let (
      (existing-data (default-to
        { sentiment-score: u0, submission-count: u0, last-updated: u0, weighted-average: u0, market-impact: 0 }
        (map-get? sentiment-data { topic-id: topic-id })
      ))
      (new-count (+ (get submission-count existing-data) u1))
      (new-weighted-avg (/ (+ (* (get weighted-average existing-data) (get submission-count existing-data)) sentiment-score) new-count))
    )
      ;; Store user submission
      (map-set user-submissions
        { user: sender, topic-id: topic-id }
        { sentiment-score: sentiment-score, weight: u1, submitted-at: current-height }
      )

      ;; Update sentiment data
      (map-set sentiment-data
        { topic-id: topic-id }
        {
          sentiment-score: sentiment-score,
          submission-count: new-count,
          last-updated: current-height,
          weighted-average: new-weighted-avg,
          market-impact: (calculate-market-impact new-weighted-avg)
        }
      )

      ;; Update sentiment count if this is a new topic
      (if (is-eq (get submission-count existing-data) u0)
        (var-set sentiment-count (+ (var-get sentiment-count) u1))
        true
      )

      (ok true)
    )
  )
)

;; Create a synthetic asset based on sentiment data
(define-public (create-synthetic-asset (topic-id uint) (base-price uint))
  (let (
    (asset-id (+ (var-get total-assets) u1))
    (sentiment-data-result (map-get? sentiment-data { topic-id: topic-id }))
  )
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-OWNER-ONLY)
    (asserts! (is-some sentiment-data-result) ERR-ASSET-NOT-FOUND)
    (asserts! (> base-price u0) ERR-INVALID-AMOUNT)

    (let (
      (sentiment-info (unwrap-panic sentiment-data-result))
      (initial-multiplier (sentiment-to-multiplier (get weighted-average sentiment-info)))
    )
      ;; Create synthetic asset
      (map-set synthetic-assets
        { asset-id: asset-id }
        {
          topic-id: topic-id,
          total-supply: u0,
          base-price: base-price,
          current-multiplier: initial-multiplier,
          created-at: block-height,
          active: true
        }
      )

      (var-set total-assets asset-id)
      (ok asset-id)
    )
  )
)

;; Mint synthetic asset tokens
(define-public (mint-synthetic-asset (asset-id uint) (amount uint) (recipient principal))
  (let (
    (asset-info (unwrap! (map-get? synthetic-assets { asset-id: asset-id }) ERR-ASSET-NOT-FOUND))
  )
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-OWNER-ONLY)
    (asserts! (get active asset-info) ERR-ASSET-NOT-FOUND)
    (asserts! (> amount u0) ERR-INVALID-AMOUNT)

    ;; Mint tokens
    (try! (ft-mint? synthetic-asset amount recipient))

    ;; Update asset total supply
    (map-set synthetic-assets
      { asset-id: asset-id }
      (merge asset-info { total-supply: (+ (get total-supply asset-info) amount) })
    )

    ;; Update user balance tracking
    (let (
      (current-balance (default-to u0 (get balance (map-get? user-asset-balances { user: recipient, asset-id: asset-id }))))
    )
      (map-set user-asset-balances
        { user: recipient, asset-id: asset-id }
        { balance: (+ current-balance amount) }
      )
    )

    (ok amount)
  )
)

;; Update asset price based on new sentiment data
(define-public (update-asset-price (asset-id uint))
  (let (
    (asset-info (unwrap! (map-get? synthetic-assets { asset-id: asset-id }) ERR-ASSET-NOT-FOUND))
    (sentiment-info (unwrap! (map-get? sentiment-data { topic-id: (get topic-id asset-info) }) ERR-ASSET-NOT-FOUND))
  )
    (asserts! (get active asset-info) ERR-ASSET-NOT-FOUND)

    (let (
      (new-multiplier (sentiment-to-multiplier (get weighted-average sentiment-info)))
    )
      (map-set synthetic-assets
        { asset-id: asset-id }
        (merge asset-info { current-multiplier: new-multiplier })
      )

      (ok new-multiplier)
    )
  )
)

;; Authorize oracle to submit sentiment data
(define-public (authorize-oracle (oracle principal))
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-OWNER-ONLY)
    (map-set authorized-oracles { oracle: oracle } { authorized: true })
    (ok true)
  )
)

;; Deauthorize oracle
(define-public (deauthorize-oracle (oracle principal))
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-OWNER-ONLY)
    (map-set authorized-oracles { oracle: oracle } { authorized: false })
    (ok true)
  )
)

;; Emergency pause contract
(define-public (toggle-contract-active)
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-OWNER-ONLY)
    (var-set contract-active (not (var-get contract-active)))
    (ok (var-get contract-active))
  )
)

;; read only functions

;; Get sentiment data for a topic
(define-read-only (get-sentiment-data (topic-id uint))
  (map-get? sentiment-data { topic-id: topic-id })
)

;; Get synthetic asset information
(define-read-only (get-synthetic-asset (asset-id uint))
  (map-get? synthetic-assets { asset-id: asset-id })
)

;; Get user's sentiment submission for a topic
(define-read-only (get-user-submission (user principal) (topic-id uint))
  (map-get? user-submissions { user: user, topic-id: topic-id })
)

;; Get user's balance for a synthetic asset
(define-read-only (get-user-asset-balance (user principal) (asset-id uint))
  (default-to u0 (get balance (map-get? user-asset-balances { user: user, asset-id: asset-id })))
)

;; Calculate current price of synthetic asset
(define-read-only (get-current-asset-price (asset-id uint))
  (match (map-get? synthetic-assets { asset-id: asset-id })
    asset-info
      (ok (/ (* (get base-price asset-info) (get current-multiplier asset-info)) ASSET-PRECISION))
    ERR-ASSET-NOT-FOUND
  )
)

;; Get total number of sentiment submissions
(define-read-only (get-sentiment-count)
  (var-get sentiment-count)
)

;; Get total number of synthetic assets
(define-read-only (get-total-assets)
  (var-get total-assets)
)

;; Check if oracle is authorized
(define-read-only (is-authorized-oracle (oracle principal))
  (default-to false (get authorized (map-get? authorized-oracles { oracle: oracle })))
)

;; Get contract status
(define-read-only (get-contract-active)
  (var-get contract-active)
)

;; private functions

;; Convert sentiment score to price multiplier
(define-private (sentiment-to-multiplier (sentiment uint))
  (if (<= sentiment u20)
    u500000    ;; 0.5x for very negative sentiment (0-20)
    (if (<= sentiment u40)
      u750000  ;; 0.75x for negative sentiment (21-40)
      (if (<= sentiment u60)
        u1000000 ;; 1.0x for neutral sentiment (41-60)
        (if (<= sentiment u80)
          u1250000 ;; 1.25x for positive sentiment (61-80)
          u1500000 ;; 1.5x for very positive sentiment (81-100)
        )
      )
    )
  )
)

;; Calculate market impact based on sentiment
(define-private (calculate-market-impact (weighted-avg uint))
  (if (< weighted-avg u50)
    (- 0 (to-int (- u50 weighted-avg))) ;; Negative impact for sentiment < 50
    (to-int (- weighted-avg u50))       ;; Positive impact for sentiment >= 50
  )
)
