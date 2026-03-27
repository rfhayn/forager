//
//  ViterbiDecoder.swift
//  forager
//
//  Created for M8.4: ML-Powered Parsing
//  Pure-Swift Viterbi decoder for CRF label sequence decoding
//

import Foundation

// MARK: - ViterbiDecoder

/// Decodes the optimal label sequence from emission scores using the Viterbi algorithm.
/// This is the CRF decoding step that runs in Swift because CoreML cannot represent
/// the dynamic programming required for CRF inference.
///
/// Consumes ALL CRF parameters: 7×7 transitions + start_transitions + end_transitions.
/// Omitting start/end transitions produces different label sequences for some inputs,
/// even when emissions match.
struct ViterbiDecoder {
    let transitions: [[Float]]      // 7×7 transition scores (label_i → label_j)
    let startTransitions: [Float]   // 1×7 start-of-sequence scores
    let endTransitions: [Float]     // 1×7 end-of-sequence scores
    let labels: [String]            // ["QTY", "UNIT", "NAME", "MODIFIER", "PREP", "COMMENT", "OTHER"]

    /// Decode the optimal label sequence from emission scores.
    /// - Parameter emissions: (seq_len × num_labels) emission scores from CoreML
    /// - Returns: Array of label strings, one per token
    func decode(emissions: [[Float]]) -> [String] {
        let seqLen = emissions.count
        let numLabels = labels.count
        guard seqLen > 0 else { return [] }

        // Viterbi scores and backpointers
        var viterbi = [[Float]](repeating: [Float](repeating: -Float.infinity, count: numLabels), count: seqLen)
        var backpointers = [[Int]](repeating: [Int](repeating: 0, count: numLabels), count: seqLen)

        // Initialize: start transitions + first token emissions
        for j in 0..<numLabels {
            viterbi[0][j] = startTransitions[j] + emissions[0][j]
        }

        // Forward pass
        for t in 1..<seqLen {
            for j in 0..<numLabels {
                for i in 0..<numLabels {
                    let score = viterbi[t - 1][i] + transitions[i][j] + emissions[t][j]
                    if score > viterbi[t][j] {
                        viterbi[t][j] = score
                        backpointers[t][j] = i
                    }
                }
            }
        }

        // Add end transitions before backtrace
        for j in 0..<numLabels {
            viterbi[seqLen - 1][j] += endTransitions[j]
        }

        // Backtrace: find best final label, then follow backpointers
        var bestLast = 0
        var bestScore = -Float.infinity
        for j in 0..<numLabels {
            if viterbi[seqLen - 1][j] > bestScore {
                bestScore = viterbi[seqLen - 1][j]
                bestLast = j
            }
        }

        var bestPath = [Int](repeating: 0, count: seqLen)
        bestPath[seqLen - 1] = bestLast
        for t in stride(from: seqLen - 2, through: 0, by: -1) {
            bestPath[t] = backpointers[t + 1][bestPath[t + 1]]
        }

        return bestPath.map { labels[$0] }
    }
}
