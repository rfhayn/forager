//
//  ViterbiDecoderTests.swift
//  foragerTests
//
//  Created for M8.4: ML-Powered Parsing (Phase 6)
//  Pure algorithm tests — no CoreML dependency, runs in CI
//

import XCTest
@testable import forager

/// Tests ViterbiDecoder with hand-crafted emission matrices.
/// These are pure algorithm tests — they validate forward pass, backpointers,
/// start/end transitions, and edge cases without requiring the CoreML model.
final class ViterbiDecoderTests: XCTestCase {

    // MARK: - Helpers

    /// Minimal 3-label decoder for compact test matrices.
    /// Labels: A, B, C with uniform transitions and neutral start/end.
    private func makeSimpleDecoder(
        transitions: [[Float]]? = nil,
        startTransitions: [Float]? = nil,
        endTransitions: [Float]? = nil
    ) -> ViterbiDecoder {
        let labels = ["A", "B", "C"]
        let defaultTransitions: [[Float]] = [
            [0.0, 0.0, 0.0],  // A → A, A → B, A → C
            [0.0, 0.0, 0.0],  // B → A, B → B, B → C
            [0.0, 0.0, 0.0],  // C → A, C → B, C → C
        ]
        return ViterbiDecoder(
            transitions: transitions ?? defaultTransitions,
            startTransitions: startTransitions ?? [0.0, 0.0, 0.0],
            endTransitions: endTransitions ?? [0.0, 0.0, 0.0],
            labels: labels
        )
    }

    // MARK: - Empty Input

    func testEmptyEmissionsReturnsEmptyLabels() {
        let decoder = makeSimpleDecoder()
        let result = decoder.decode(emissions: [])
        XCTAssertEqual(result, [], "Empty emissions should produce empty labels")
    }

    // MARK: - Single Token

    func testSingleTokenSelectsHighestEmission() {
        let decoder = makeSimpleDecoder()
        // Token 0: A=1.0, B=5.0, C=2.0 → B wins
        let result = decoder.decode(emissions: [[1.0, 5.0, 2.0]])
        XCTAssertEqual(result, ["B"])
    }

    func testSingleTokenWithStartTransitions() {
        // Start transitions heavily favor A, but emissions favor B
        // A: start(10) + emit(1) = 11, B: start(0) + emit(5) = 5 → A wins
        let decoder = makeSimpleDecoder(
            startTransitions: [10.0, 0.0, 0.0]
        )
        let result = decoder.decode(emissions: [[1.0, 5.0, 2.0]])
        XCTAssertEqual(result, ["A"], "Strong start transition should override emission preference")
    }

    func testSingleTokenWithEndTransitions() {
        // End transitions heavily favor C
        // A: start(0) + emit(1) + end(0) = 1
        // B: start(0) + emit(5) + end(0) = 5
        // C: start(0) + emit(2) + end(10) = 12 → C wins
        let decoder = makeSimpleDecoder(
            endTransitions: [0.0, 0.0, 10.0]
        )
        let result = decoder.decode(emissions: [[1.0, 5.0, 2.0]])
        XCTAssertEqual(result, ["C"], "Strong end transition should override emission preference")
    }

    // MARK: - Two Token Sequences

    func testTwoTokensFollowEmissions() {
        let decoder = makeSimpleDecoder()
        // Token 0: A=10, B=0, C=0 → A
        // Token 1: A=0, B=10, C=0 → B
        let result = decoder.decode(emissions: [
            [10.0, 0.0, 0.0],
            [0.0, 10.0, 0.0],
        ])
        XCTAssertEqual(result, ["A", "B"])
    }

    func testTransitionsOverrideEmissions() {
        // Emissions favor A→B, but transition A→C is very strong
        // Token 0: A dominates
        // Token 1: B has higher emission, but A→C transition compensates
        let transitions: [[Float]] = [
            [0.0, 0.0, 20.0],   // A→C is +20
            [0.0, 0.0, 0.0],
            [0.0, 0.0, 0.0],
        ]
        let decoder = makeSimpleDecoder(transitions: transitions)
        let result = decoder.decode(emissions: [
            [10.0, 0.0, 0.0],   // A wins first
            [0.0, 5.0, 1.0],    // B=5 emission, but A→C=20+1=21 > A→B=0+5=5
        ])
        XCTAssertEqual(result, ["A", "C"], "Strong transition should override emission preference")
    }

    // MARK: - Longer Sequences

    func testThreeTokenSequence() {
        let decoder = makeSimpleDecoder()
        let result = decoder.decode(emissions: [
            [10.0, 0.0, 0.0],  // A
            [0.0, 0.0, 10.0],  // C
            [0.0, 10.0, 0.0],  // B
        ])
        XCTAssertEqual(result, ["A", "C", "B"])
    }

    func testFiveTokenSequenceWithClearPath() {
        let decoder = makeSimpleDecoder()
        let result = decoder.decode(emissions: [
            [10.0, 0.0, 0.0],  // A
            [0.0, 10.0, 0.0],  // B
            [0.0, 0.0, 10.0],  // C
            [10.0, 0.0, 0.0],  // A
            [0.0, 10.0, 0.0],  // B
        ])
        XCTAssertEqual(result, ["A", "B", "C", "A", "B"])
    }

    // MARK: - Edge Cases

    func testAllLabelsEqualScore() {
        let decoder = makeSimpleDecoder()
        // All emissions identical — first label (A, index 0) wins because
        // the Viterbi algorithm initializes with -infinity and uses strict >
        let result = decoder.decode(emissions: [[1.0, 1.0, 1.0]])
        // With uniform everything, first label wins (> not >=)
        XCTAssertEqual(result.count, 1, "Should produce exactly one label")
        XCTAssertTrue(["A", "B", "C"].contains(result[0]),
                       "Should produce a valid label")
    }

    func testNegativeEmissions() {
        let decoder = makeSimpleDecoder()
        // All negative, but B is least negative
        let result = decoder.decode(emissions: [[-10.0, -1.0, -5.0]])
        XCTAssertEqual(result, ["B"], "Least negative emission should win")
    }

    func testVeryLargeEmissions() {
        let decoder = makeSimpleDecoder()
        let result = decoder.decode(emissions: [[1e6, -1e6, 0.0]])
        XCTAssertEqual(result, ["A"], "Very large positive emission should win")
    }

    // MARK: - Start + End Transitions Combined

    func testStartAndEndTransitionsShapeSequence() {
        // Start favors A, end favors C, emissions are ambiguous
        let decoder = makeSimpleDecoder(
            startTransitions: [5.0, 0.0, 0.0],
            endTransitions: [0.0, 0.0, 5.0]
        )
        let result = decoder.decode(emissions: [
            [1.0, 1.0, 1.0],  // Start bias → A
            [1.0, 1.0, 1.0],  // Uniform
            [1.0, 1.0, 1.0],  // End bias → C
        ])
        XCTAssertEqual(result.first, "A", "Start transition should influence first token")
        XCTAssertEqual(result.last, "C", "End transition should influence last token")
    }

    // MARK: - Backpointer Correctness

    func testBackpointersTraceCorrectPath() {
        // Design a sequence where the optimal path requires non-greedy choices
        // Token 0: B is best locally
        // Token 1: But B→A transition is strong, making B→A better than B→B
        let transitions: [[Float]] = [
            [0.0, 0.0, 0.0],
            [10.0, -10.0, 0.0],  // B→A is +10, B→B is -10
            [0.0, 0.0, 0.0],
        ]
        let decoder = makeSimpleDecoder(transitions: transitions)
        let result = decoder.decode(emissions: [
            [0.0, 5.0, 0.0],   // B wins first
            [1.0, 3.0, 0.0],   // B→A = 5+10+1=16, B→B = 5-10+3=-2 → A wins
        ])
        XCTAssertEqual(result, ["B", "A"])
    }

    // MARK: - Full 7-Label (Forager Labels)

    func testForagerLabelsDecodeCorrectly() {
        let labels = ["QTY", "UNIT", "NAME", "MODIFIER", "PREP", "COMMENT", "OTHER"]
        let numLabels = labels.count
        let zeroRow = [Float](repeating: 0.0, count: numLabels)
        let transitions = [[Float]](repeating: zeroRow, count: numLabels)

        let decoder = ViterbiDecoder(
            transitions: transitions,
            startTransitions: zeroRow,
            endTransitions: zeroRow,
            labels: labels
        )

        // "2 cups flour" → QTY UNIT NAME
        let emissions: [[Float]] = [
            [10, 0, 0, 0, 0, 0, 0],   // QTY
            [0, 10, 0, 0, 0, 0, 0],   // UNIT
            [0, 0, 10, 0, 0, 0, 0],   // NAME
        ]
        let result = decoder.decode(emissions: emissions)
        XCTAssertEqual(result, ["QTY", "UNIT", "NAME"])
    }

    func testForagerLabelsWithModifierAndPrep() {
        let labels = ["QTY", "UNIT", "NAME", "MODIFIER", "PREP", "COMMENT", "OTHER"]
        let numLabels = labels.count
        let zeroRow = [Float](repeating: 0.0, count: numLabels)
        let transitions = [[Float]](repeating: zeroRow, count: numLabels)

        let decoder = ViterbiDecoder(
            transitions: transitions,
            startTransitions: zeroRow,
            endTransitions: zeroRow,
            labels: labels
        )

        // "2 cups fresh basil, chopped" → QTY UNIT MODIFIER NAME OTHER PREP
        let emissions: [[Float]] = [
            [10, 0, 0, 0, 0, 0, 0],   // QTY
            [0, 10, 0, 0, 0, 0, 0],   // UNIT
            [0, 0, 0, 10, 0, 0, 0],   // MODIFIER
            [0, 0, 10, 0, 0, 0, 0],   // NAME
            [0, 0, 0, 0, 0, 0, 10],   // OTHER (comma)
            [0, 0, 0, 0, 10, 0, 0],   // PREP
        ]
        let result = decoder.decode(emissions: emissions)
        XCTAssertEqual(result, ["QTY", "UNIT", "MODIFIER", "NAME", "OTHER", "PREP"])
    }
}
