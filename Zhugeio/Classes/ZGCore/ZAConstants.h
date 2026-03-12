//
//  ZAConstants.h
//  ZhugeioAnanlytics
//
//  Created by Good_Morning_ on 2021/6/29.
//

#import <Foundation/Foundation.h>


/**
 * @abstract
 * AutoTrack 中的事件类型
 *
 * @discussion
 *   ZhugeioAnalyticsEventTypeAppStart - $AppStart
 *   ZhugeioAnalyticsEventTypeAppEnd - $AppEnd
 *   ZhugeioAnalyticsEventTypeAppClick - $AppClick
 *   ZhugeioAnalyticsEventTypeAppViewScreen - $AppViewScreen
 */
typedef NS_OPTIONS(NSInteger, ZhugeioAnalyticsAutoTrackEventType) {
    ZhugeioAnalyticsEventTypeNone      = 0,
    ZhugeioAnalyticsEventTypeAppStart      = 1 << 0,
    ZhugeioAnalyticsEventTypeAppEnd        = 1 << 1,
    ZhugeioAnalyticsEventTypeAppClick      = 1 << 2,
    ZhugeioAnalyticsEventTypeAppViewScreen = 1 << 3,
};
