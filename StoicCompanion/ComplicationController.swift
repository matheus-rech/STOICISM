//
//  ComplicationController.swift
//  StoicCompanion
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
        case .utilitarianSmall:
            return utilitarianSmallTemplate()
        case .utilitarianLarge:
            return utilitarianLargeTemplate()
        case .circularSmall:
            return circularSmallTemplate()
        case .graphicCorner:
            return graphicCornerTemplate()
        case .graphicCircular:
            return graphicCircularTemplate()
        case .graphicRectangular:
            return graphicRectangularTemplate()
        case .graphicBezel:
            return graphicBezelTemplate()
        case .graphicExtraLarge:
            if #available(watchOS 7.0, *) {
                return graphicExtraLargeTemplate()
            }
            fallback()
        @unknown default:
            return fallback()
        }
    }
    
    // MARK: - Individual Templates
    
    private func modularSmallTemplate() -> CLKComplicationTemplate {
        let template = CLKComplicationTemplateModularSmallSimpleImage()
        template.imageProvider = CLKImageProvider(onePieceImage: UIImage(systemName: "laurel.leading")!)
        return template
    }
    
    private func modularLargeTemplate() -> CLKComplicationTemplate {
        let template = CLKComplicationTemplateModularLargeStandardBody()
        template.headerTextProvider = CLKSimpleTextProvider(text: "Stoic")
        template.body1TextProvider = CLKSimpleTextProvider(text: "Tap for wisdom")
        return template
    }
    
    private func utilitarianSmallTemplate() -> CLKComplicationTemplate {
        let template = CLKComplicationTemplateUtilitarianSmallSquare()
        template.imageProvider = CLKImageProvider(onePieceImage: UIImage(systemName: "laurel.leading")!)
        return template
    }
    
    private func utilitarianLargeTemplate() -> CLKComplicationTemplate {
        let template = CLKComplicationTemplateUtilitarianLargeFlat()
        template.textProvider = CLKSimpleTextProvider(text: "Stoic Wisdom")
        template.imageProvider = CLKImageProvider(onePieceImage: UIImage(systemName: "laurel.leading")!)
        return template
    }
    
    private func circularSmallTemplate() -> CLKComplicationTemplate {
        let template = CLKComplicationTemplateCircularSmallSimpleImage()
        template.imageProvider = CLKImageProvider(onePieceImage: UIImage(systemName: "laurel.leading")!)
        return template
    }
    
    private func graphicCornerTemplate() -> CLKComplicationTemplate {
        let template = CLKComplicationTemplateGraphicCornerTextImage()
        template.textProvider = CLKSimpleTextProvider(text: "Stoic")
        template.imageProvider = CLKFullColorImageProvider(fullColorImage: UIImage(systemName: "laurel.leading")!)
        return template
    }
    
    private func graphicCircularTemplate() -> CLKComplicationTemplate {
        let template = CLKComplicationTemplateGraphicCircularImage()
        template.imageProvider = CLKFullColorImageProvider(fullColorImage: UIImage(systemName: "laurel.leading")!)
        return template
    }
    
    private func graphicRectangularTemplate() -> CLKComplicationTemplate {
        let template = CLKComplicationTemplateGraphicRectangularStandardBody()
        template.headerTextProvider = CLKSimpleTextProvider(text: "Stoic Companion")
        template.body1TextProvider = CLKSimpleTextProvider(text: "Wisdom for your day")
        return template
    }
    
    private func graphicBezelTemplate() -> CLKComplicationTemplate {
        let circularTemplate = CLKComplicationTemplateGraphicCircularImage()
        circularTemplate.imageProvider = CLKFullColorImageProvider(fullColorImage: UIImage(systemName: "laurel.leading")!)
        
        let template = CLKComplicationTemplateGraphicBezelCircularText()
        template.circularTemplate = circularTemplate
        template.textProvider = CLKSimpleTextProvider(text: "Stoic Wisdom")
        return template
    }
    
    @available(watchOS 7.0, *)
    private func graphicExtraLargeTemplate() -> CLKComplicationTemplate {
        let template = CLKComplicationTemplateGraphicExtraLargeCircularImage()
        template.imageProvider = CLKFullColorImageProvider(fullColorImage: UIImage(systemName: "laurel.leading")!)
        return template
    }
    
    private func fallback() -> CLKComplicationTemplate {
        return modularSmallTemplate()
    }
    
    // MARK: - Placeholder
    
    func getLocalizableSampleTemplate(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationTemplate?) -> Void) {
        handler(makeTemplate(for: complication))
    }
}
