//
//  SILGattXmlParser.swift
//  BlueGecko
//
//  Created by Kamil Czajka on 31.5.2021.
//  Copyright © 2021 SiliconLabs. All rights reserved.
//

import Foundation
import AEXML

protocol SILGattXmlFile { }

extension URL: SILGattXmlFile { }

enum SILGattXmlParserError: Error, LocalizedError {
    case parsingError(description: String)
    case unknownError
    
    public var errorDescription: String? {
        switch self {
        case let .parsingError(description: description):
            return NSLocalizedString(description, comment: "")
            
        case .unknownError:
            return NSLocalizedString("Unknown error", comment: "")
        }
    }
}

protocol SILGattXmlParserType {
    func parse(file: SILGattXmlFile) -> Result<SILGattConfigurationEntity, SILGattXmlParserError>
}

class SILGattXmlParser: SILGattXmlParserType {
    private let gattAssignedRepository: SILGattAssignedNumbersRepository
    private let helper = SILGattImportHelper.shared
    
    init(gattAssignedRepository: SILGattAssignedNumbersRepository) {
        self.gattAssignedRepository = gattAssignedRepository
    }
    
    func parse(file url: SILGattXmlFile) -> Result<SILGattConfigurationEntity, SILGattXmlParserError> {
        guard let data = try? Data(contentsOf: url as! URL) else {
            return .failure(.parsingError(description: "Resource not found!"))
        }

        var options = AEXMLOptions()
        options.parserSettings.shouldProcessNamespaces = false
        options.parserSettings.shouldReportNamespacePrefixes = false
        options.parserSettings.shouldResolveExternalEntities = false

        do {
            let xmlDoc = try AEXMLDocument(xml: data, options: options)
            
            if xmlDoc.root.count == 1 {
                if xmlDoc.root.name == "gatt" {
                    return SILGattMarker(element: xmlDoc.root, gattAssignedRepository: gattAssignedRepository).parse()
                } else if xmlDoc.root.name == "project" {
                    let result = SILGattProjectMarker(element: xmlDoc.root).parse()
                    switch result {
                    case let .success(projectEntity):
                        if let gattElement = xmlDoc.root.children.first {
                            var gattMarker = SILGattMarker(element: gattElement, gattAssignedRepository: gattAssignedRepository)
                            return gattMarker.parse(withProjectEntity: projectEntity)
                        } else {
                            return .failure(.parsingError(description: helper.errorMissingElement(name: "<gatt>", inMarker: "<project>")))
                        }
                    case let .failure(error):
                        return .failure(error)
                    }
                } else {
                    return .failure(.parsingError(description: helper.errorNotAllowedElementName(element: xmlDoc.root, expectedName: "<project>")))
                }
            } else {
                return .failure(.parsingError(description: helper.errorTooManyMarkers(inMarker: "root marker")))
            }
        } catch let error as AEXMLError {
            switch error {
            case .elementNotFound, .rootElementMissing:
                return .failure(.parsingError(description: "Syntax is incorrect"))
            case .parsingFailed:
                return .failure(.parsingError(description: "Parsing XML file failed"))
            }
        } catch {
            return .failure(.unknownError)
        }
    }
}
