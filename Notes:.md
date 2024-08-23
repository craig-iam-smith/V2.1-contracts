Notes:
1) Got the publically available codebase (V2.1) to the point where most of the existing foundry tests are running
2) Read the published audit of V3
3) Question about code snippets from V3
3a) I don't see gating of the redeem functions, (can they be executed while pool is open?) 
    If redeeming can be done while pool is open doesn't that lead to the possibility of much larger payout than amount collected?
3b) PoolParams is used for a argument (calldata) in a significant number of functions
    wouldn't passing just (address/index of the the pool) provide simplification (some functions may cost more gas due to it not being in calldata, but others may not)

