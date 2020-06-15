/*

Copyright 2015-2016 Andreas Würl

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

*/

import Foundation
import MapKit

public class StrikeOverlayRenderer: MKOverlayRenderer {

    public let strikeOverlay: StrikeOverlay

    private let colorScheme: ColorScheme

    public override init(overlay: MKOverlay) {
        strikeOverlay = overlay as! StrikeOverlay
        colorScheme = ColorScheme()
        super.init(overlay: overlay)
    }

    public override func canDraw(_ mapRect: MKMapRect, zoomScale: MKZoomScale) -> Bool {
        return true
    }

    public override func draw(_ mapRect: MKMapRect, zoomScale: MKZoomScale, in context: CGContext) {
        super.draw(mapRect, zoomScale: zoomScale, in: context)

        let color = colorScheme.getColor(now: strikeOverlay.referenceTimestamp,
                eventTime: strikeOverlay.strike.timestamp,
                intervalDuration: strikeOverlay.parameters.intervalDuration)
        
        let red = CGFloat((color & 0xff0000) >> 16) / 255.0
        let green = CGFloat((color & 0x00ff00) >> 8) / 255.0
        let blue = CGFloat(color & 0x0000ff) / 255.0
        
        context.setFillColor(red: red , green: green, blue: blue, alpha: 1.0)

        let rasterElement = strikeOverlay.boundingMapRect

        let rasterRect = rect(for: rasterElement);

        context.fill(rasterRect);
    }
}
