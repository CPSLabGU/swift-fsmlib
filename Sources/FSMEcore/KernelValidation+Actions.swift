//
//  KernelValidation+Actions.swift
//  FSMEcore
//
//  Created by Rene Hexel on 23/10/2026.
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import ECore
import EMFBase

/// The checks of the single assignment rule for the actions of a kernel model.
extension KernelValidation {
    // MARK: - W6

    /// Check that within one action every variable is assigned at most once
    /// and is not read after it has been assigned.
    mutating func checkSingleAssignment() {
        for state in objects(of: kernel.stateClass) {
            var assigned = Set<EUUID>()
            for statement in index.objects(.actions, of: state) {
                let target = isKind(statement, kernel.assignmentClass) ? index.target(.target, of: statement) : nil
                var reported = Set<EUUID>()
                for variable in variablesRead(by: statement, excluding: target)
                where assigned.contains(variable.id) && reported.insert(variable.id).inserted {
                    report(
                        .singleAssignment,
                        statement,
                        "The variable \(label(variable)) is read after it was assigned in the same action"
                    )
                }
                guard let target, let variable = index.target(.variable, of: target),
                      isAnalysed(variable) else { continue }
                if !assigned.insert(variable.id).inserted {
                    report(
                        .singleAssignment,
                        statement,
                        "The variable \(label(variable)) is assigned more than once in the same action"
                    )
                }
            }
        }
    }

    /// The analysed variables that a statement reads, in order of first occurrence.
    ///
    /// - Parameters:
    ///   - statement: The statement whose expressions are searched.
    ///   - target: The variable reference that the statement assigns, whose
    ///     own variable is written rather than read.
    /// - Returns: The variables read.
    private func variablesRead(by statement: DynamicEObject, excluding target: DynamicEObject?) -> [DynamicEObject] {
        var result: [DynamicEObject] = []
        var seen = Set<EUUID>()
        for object in index.subtree(of: statement)
        where isKind(object, kernel.variableReferenceClass) && object.id != target?.id {
            guard let variable = index.target(.variable, of: object), isAnalysed(variable),
                  seen.insert(variable.id).inserted else { continue }
            result.append(variable)
        }
        return result
    }

    /// Whether the single-assignment rule applies to a variable under the profile.
    ///
    /// The relaxed profile analyses only variables of typed kernel types.
    private func isAnalysed(_ variable: DynamicEObject) -> Bool {
        profile == .strict || declaredType(index.target(.type, of: variable)).isKnown
    }
}
