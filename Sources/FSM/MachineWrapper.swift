//
//  MachineWrapper.swift
//
//
//  Created by Rene Hexel on 30/9/2023.
//
import Foundation

/// Directory file wrapper wrapping an Arrangement of Machines
public typealias ArrangementWrapper = FileWrapper

/// Directory file wrapper wrapping a Machine
public typealias MachineWrapper = FileWrapper

extension FileWrapper {
    /// Machine directory name.
    @usableFromInline var directoryName: String {
        preferredFilename ?? filename ?? FileManager.default.currentDirectoryName
    }

    /// Machine name without the file extension.
    @usableFromInline var machineName: String {
        let dirName = directoryName
        return dirName.lastIndex(of: ".").map {
            String(dirName[dirName.startIndex..<$0])
        } ?? dirName
    }

    /// Return the contents of the given file as a String.
    ///
    /// - Parameter fileName: Name of the file inside the receiver.
    /// - Returns: The contents of the file as a String.
    @usableFromInline
    func stringContents(of fileName: String) -> String? {
        fileWrappers?[fileName]?.stringContents
    }

    /// Return the regular file contents as a String.
    @usableFromInline var stringContents: String? {
        regularFileContents.flatMap { String(data: $0, encoding: .utf8) }
    }
}
