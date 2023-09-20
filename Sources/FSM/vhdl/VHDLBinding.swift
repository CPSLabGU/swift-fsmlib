// VHDLBinding.swift
// swift-fsmlib
// 
// Created by Morgan McColl.
// Copyright © 2023 Morgan McColl. All rights reserved.
// 
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions
// are met:
// 
// 1. Redistributions of source code must retain the above copyright
//    notice, this list of conditions and the following disclaimer.
// 
// 2. Redistributions in binary form must reproduce the above
//    copyright notice, this list of conditions and the following
//    disclaimer in the documentation and/or other materials
//    provided with the distribution.
// 
// 3. All advertising materials mentioning features or use of this
//    software must display the following acknowledgement:
// 
//    This product includes software developed by Morgan McColl.
// 
// 4. Neither the name of the author nor the names of contributors
//    may be used to endorse or promote products derived from this
//    software without specific prior written permission.
// 
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
// "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
// LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
// A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER
// OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
// EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
// PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
// PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
// LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
// NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
// SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
// 
// -----------------------------------------------------------------------
// This program is free software; you can redistribute it and/or
// modify it under the above terms or under the terms of the GNU
// General Public License as published by the Free Software Foundation;
// either version 2 of the License, or (at your option) any later version.
// 
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
// 
// You should have received a copy of the GNU General Public License
// along with this program; if not, see http://www.gnu.org/licenses/
// or write to the Free Software Foundation, Inc., 51 Franklin Street,
// Fifth Floor, Boston, MA  02110-1301, USA.
// 

import Foundation

public struct VHDLBinding: OutputLanguage {

    public let name: String

    public let numberOfTransitions: (URL, StateName) -> Int = {
        do {
            return try vhdlGetTransitions(path: $0, name: $1).count
        } catch {
            fputs(
                "Error: cannot read transitions in state \($1) for machine (\($0.path)): " +
                    "\(error.localizedDescription)'\n",
                stderr
            )
            return 0
        }
    }

    public let expressionOfTransition: (URL, StateName) -> (Int) -> String = {
        do {
            let expressions = try vhdlGetTransitions(path: $0, name: $1).map {
                guard let expression = $0.split(separator: ",").first else {
                    throw VHDLError.malformed(value: $0)
                }
                return String(expression)
            }
            return { expressions[$0] }
        } catch {
            fputs(
                "Error: cannot read transitions in state \($1) for machine (\($0.path)): " +
                    "\(error.localizedDescription)'\n",
                stderr
            )
            return { _ in "" }
        }
    }

    public let targetOfTransition: (URL, [State], StateName) -> (Int) -> StateID? = {
        do {
            let targets = try vhdlGetTransitions(path: $0, name: $2).map {
                let expressionAndTarget: [Substring] = $0.split(separator: ",")
                guard
                    expressionAndTarget.count == 2,
                    let id = StateID(
                        uuidString: expressionAndTarget[1].trimmingCharacters(in: .whitespacesAndNewlines)
                    )
                else {
                    throw VHDLError.malformed(value: $0)
                }
                return id
            }
            let stateSet = Set($1.map { $0.id})
            return {
                let id = targets[$0]
                guard stateSet.contains(id) else {
                    return nil
                }
                return id
            }
        } catch {
            fputs(
                "Error: cannot read transitions in state \($1) for machine (\($0.path)): " +
                    "\(error.localizedDescription)'\n",
                stderr
            )
            return { _ in nil }
        }
    }

    public let suspendState: (URL, [State]) -> StateID? = {
        let suspendFile = $0.appendingPathComponent("SuspendedState", isDirectory: false)
        do {
            let contents = try String(contentsOf: suspendFile).trimmingCharacters(in: .whitespacesAndNewlines)
            if let value = Int(contents), value == -1 {
                return nil
            }
            return $1.first { $0.name == contents }?.id
        } catch {
            fputs(
                "Error: cannot read suspended state for machine (\($0.path)): " +
                    "\(error.localizedDescription)'\n",
                stderr
            )
            return nil
        }
    }

    public let boilerplate: (URL) -> any Boilerplate = { path in
        let sectionNames = VHDLBoilerplate.SectionName.allCases
        do {
            let contents = try sectionNames.map {
                try String(contentsOf: path.appendingPathComponent($0.rawValue, isDirectory: false))
            }
            let sections = Dictionary(uniqueKeysWithValues: zip(sectionNames, contents))
            return VHDLBoilerplate(sections: sections)
        } catch {
            fputs(
                "Error: cannot read boilerplate for machine (\(path.path)): " +
                    "\(error.localizedDescription)'\n",
                stderr
            )
            return VHDLBoilerplate()
        }
    }

    public let stateBoilerplate: (URL, StateName) -> any Boilerplate = { path, name in
        let sectionNames = VHDLStateBoilerplate.SectionName.allCases
        do {
            let contents = try sectionNames.map {
                try String(
                    contentsOf: path.appendingPathComponent(
                        "STATE_\(name)_\($0.rawValue)", isDirectory: false
                    )
                )
            }
            let sections = Dictionary(uniqueKeysWithValues: zip(sectionNames, contents))
            return VHDLStateBoilerplate(name: name, sections: sections)
        } catch {
            fputs(
                "Error: cannot read boilerplate for machine (\(path.path)): " +
                    "\(error.localizedDescription)'\n",
                stderr
            )
            return VHDLStateBoilerplate()
        }
    }

    public func write(boilerplate: any Boilerplate, to url: URL) throws {
        try boilerplate.write(to: url)
    }

    public func write(stateBoilerplate: any Boilerplate, to url: URL, for stateName: String) throws {
        try stateBoilerplate.write(state: stateName, to: url)
    }

    public func writeTransitionCode(for fsm: LLFSM, to url: URL, isSuspensible: Bool) throws {
        let transitionsSet = Set(fsm.transitions)
        let transitions = fsm.transitionMap.filter { transitionsSet.contains($0.key) }
        var stateTransitionsMap: [StateName: [(Expression, StateName)]] = [:]
        try transitions.values.forEach {
            guard let source = fsm.stateMap[$0.source]?.name else {
                throw VHDLError.missingState(id: $0.source)
            }
            guard let target = fsm.stateMap[$0.target]?.name else {
                throw VHDLError.missingState(id: $0.target)
            }
            let newValue = [($0.label, target)]
            guard let currentValue = stateTransitionsMap[source] else {
                stateTransitionsMap[source] = newValue
                return
            }
            stateTransitionsMap[source] = currentValue + newValue
        }
        try stateTransitionsMap.forEach {
            let path = url.appendingPathComponent("STATE_\($0.key)_Transitions", isDirectory: false)
            let contents = $0.value.map { "\($0.0),\($0.1)" }.joined(separator: "\n")
            try contents.write(to: path, atomically: true, encoding: .utf8)
        }
    }

}

public extension VHDLBinding {

    func writeInterface(for llfsm: LLFSM, to url: URL, isSuspensible: Bool) throws {}

    func writeStateInterface(for fsm: LLFSM, to url: URL, isSuspensible: Bool) throws {}

    func writeArrangementInterface(for instances: [Instance], to url: URL, isSuspensible: Bool) throws {}

    func writeCode(for llfsm: LLFSM, to url: URL, isSuspensible: Bool) throws {}

    func writeStateCode(for fsm: LLFSM, to url: URL, isSuspensible: Bool) throws {}

    func writeArrangementCode(for instances: [Instance], to url: URL, isSuspensible: Bool) throws {}

    func writeArrangementCMakeFile(for instances: [Instance], to url: URL, isSuspensible: Bool) throws {}

    func writeCMakeFile(
        for fsm: LLFSM, boilerplate: any Boilerplate, to url: URL, isSuspensible: Bool
    ) throws {}

}

func vhdlGetTransitions(path: URL, name: StateName) throws -> [String] {
    let transitionsFilePath = path.appendingPathComponent("STATE_\(name)_Transitions", isDirectory: false)
    let transitionsContent = try String(contentsOf: transitionsFilePath)
    return transitionsContent.components(separatedBy: .newlines).filter {
        !$0.trimmingCharacters(in: .whitespaces).isEmpty
    }
}
