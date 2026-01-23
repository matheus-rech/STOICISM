//
//  ComplicationController.swift
//  StoicCamarade
//
//  Watch face complications for quick access to stoic wisdom
//

import ClockKit
import SwiftUI

class ComplicationController: NSObject, CLKComplicationDataSource {
    
    // MARK: - Complication Configuration
    
    func getSupportedTimeTravelDirections(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationTimeTravelDirections) -> Void) {
        handler([])
    }
    
    // MARK: - Timeline Population
    
    func getCurrentTimelineEntry(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationTimelineEntry?) -> Void) {
        let template = makeTemplate(for: complication)
        let entry = CLKComplicationTimelineEntry(date: Date(), complicationTemplate: template)
        handler(entry)
    }
    
    // MARK: - Template Creation
    
    private func makeTemplate(for complication: CLKComplication) -> CLKComplicationTemplate {
        switch complication.family {
        case .modularSmall:
            return modularSmallTemplate()
        case .modularLarge:
            return modularLargeTemplate()
        case .utilitarianSmall, .utilitarianSmallFlat:
            return utilitarianSmallTemplate()
        case .utilitarianLarge:
            return utilitarianLargeTemplate()
        case .circularSmall:
            return circularSmallTemplate()
        case .extraLarge:
            return extraLargeTemplate()
        case .graphicCorner:
            return graphicCornerTemplate()
        case .graphicCircular:
            return graphicCircularTemplate()
        case .graphicRectangular:
            return graphicRectangularTemplate()
        case .graphicBezel:
            return graphicBezelTemplate()
        case .graphicExtraLarge:
            return graphicExtraLargeTemplate()
        @unknown default:
            return fallback()
        }
    }
    
    // MARK: - Individual Templates
    
    private func modularSmallTemplate() -> CLKComplicationTemplate {
        let image = UIImage(systemName: "laurel.leading") ?? UIImage(systemName: "star.fill")!
        let imageProvider = CLKImageProvider(onePieceImage: image)
        return CLKComplicationTemplateModularSmallSimpleImage(imageProvider: imageProvider)
    }
    
    private func modularLargeTemplate() -> CLKComplicationTemplate {
        let header = CLKSimpleTextProvider(text: "Stoic")
        let body = CLKSimpleTextProvider(text: "Tap for wisdom")
        return CLKComplicationTemplateModularLargeStandardBody(headerTextProvider: header, body1TextProvider: body)
    }
    
    private func utilitarianSmallTemplate() -> CLKComplicationTemplate {
        let image = UIImage(systemName: "laurel.leading") ?? UIImage(systemName: "star.fill")!
        let imageProvider = CLKImageProvider(onePieceImage: image)
        return CLKComplicationTemplateUtilitarianSmallSquare(imageProvider: imageProvider)
    }
    
    private func utilitarianLargeTemplate() -> CLKComplicationTemplate {
        let textProvider = CLKSimpleTextProvider(text: "Stoic Wisdom")
        let template = CLKComplicationTemplateUtilitarianLargeFlat(textProvider: textProvider)
        let image = UIImage(systemName: "laurel.leading") ?? UIImage(systemName: "star.fill")!
        template.imageProvider = CLKImageProvider(onePieceImage: image)
        return template
    }
    
    private func circularSmallTemplate() -> CLKComplicationTemplate {
        let image = UIImage(systemName: "laurel.leading") ?? UIImage(systemName: "star.fill")!
        let imageProvider = CLKImageProvider(onePieceImage: image)
        return CLKComplicationTemplateCircularSmallSimpleImage(imageProvider: imageProvider)
    }

    private func extraLargeTemplate() -> CLKComplicationTemplate {
        let image = UIImage(systemName: "laurel.leading") ?? UIImage(systemName: "star.fill")!
        let imageProvider = CLKImageProvider(onePieceImage: image)
        return CLKComplicationTemplateExtraLargeSimpleImage(imageProvider: imageProvider)
    }

    private func graphicCornerTemplate() -> CLKComplicationTemplate {
        let image = UIImage(systemName: "laurel.leading") ?? UIImage(systemName: "star.fill")!
        let imageProvider = CLKFullColorImageProvider(fullColorImage: image)
        return CLKComplicationTemplateGraphicCornerTextImage(textProvider: CLKSimpleTextProvider(text: "Stoic"), imageProvider: imageProvider)
    }

    private func graphicCircularTemplate() -> CLKComplicationTemplate {
        let image = UIImage(systemName: "laurel.leading") ?? UIImage(systemName: "star.fill")!
        let imageProvider = CLKFullColorImageProvider(fullColorImage: image)
        return CLKComplicationTemplateGraphicCircularImage(imageProvider: imageProvider)
    }
    
    private func graphicRectangularTemplate() -> CLKComplicationTemplate {
        let header = CLKSimpleTextProvider(text: "Stoic Camarade")
        let body = CLKSimpleTextProvider(text: "Wisdom for your day")
        return CLKComplicationTemplateGraphicRectangularStandardBody(headerTextProvider: header, body1TextProvider: body)
    }
    
    private func graphicBezelTemplate() -> CLKComplicationTemplate {
        let image = UIImage(systemName: "laurel.leading") ?? UIImage(systemName: "star.fill")!
        let imageProvider = CLKFullColorImageProvider(fullColorImage: image)
        let circularTemplate = CLKComplicationTemplateGraphicCircularImage(imageProvider: imageProvider)
        return CLKComplicationTemplateGraphicBezelCircularText(circularTemplate: circularTemplate, textProvider: CLKSimpleTextProvider(text: "Stoic Wisdom"))
    }

    private func graphicExtraLargeTemplate() -> CLKComplicationTemplate {
        let image = UIImage(systemName: "laurel.leading") ?? UIImage(systemName: "star.fill")!
        let imageProvider = CLKFullColorImageProvider(fullColorImage: image)
        return CLKComplicationTemplateGraphicExtraLargeCircularImage(imageProvider: imageProvider)
    }
    
    private func fallback() -> CLKComplicationTemplate {
        return modularSmallTemplate()
    }
    
    // MARK: - Placeholder
    
    func getLocalizableSampleTemplate(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationTemplate?) -> Void) {
        handler(makeTemplate(for: complication))
    }
}
