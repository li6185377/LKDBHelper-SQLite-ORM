//
//  ComplicationController.m
//  Watch WatchKit Extension
//
//  Created by ljh on 2022/3/17.
//  Copyright © 2022 ljh. All rights reserved.
//

#import "ComplicationController.h"

@implementation ComplicationController

#pragma mark - Complication Configuration

- (void)getComplicationDescriptorsWithHandler:(void (^)(NSArray<CLKComplicationDescriptor *> * _Nonnull))handler {
    NSArray<CLKComplicationDescriptor *> *descriptors = @[
        [[CLKComplicationDescriptor alloc] initWithIdentifier:@"complication"
                                                  displayName:@"iOS-Demo"
                                            supportedFamilies:CLKAllComplicationFamilies()]
        // Multiple complication support can be added here with more descriptors
    ];
    
    // Call the handler with the currently supported complication descriptors
    handler(descriptors);
}

- (void)handleSharedComplicationDescriptors:(NSArray<CLKComplicationDescriptor *> *)complicationDescriptors {
    // Do any necessary work to support these newly shared complication descriptors
}

#pragma mark - Timeline Configuration

- (void)getTimelineEndDateForComplication:(CLKComplication *)complication withHandler:(void(^)(NSDate * __nullable date))handler {
    // Call the handler with the last entry date you can currently provide or nil if you can't support future timelines
    handler(nil);
}

- (void)getPrivacyBehaviorForComplication:(CLKComplication *)complication withHandler:(void(^)(CLKComplicationPrivacyBehavior privacyBehavior))handler {
    // Call the handler with your desired behavior when the device is locked
    handler(CLKComplicationPrivacyBehaviorShowOnLockScreen);
}

#pragma mark - Timeline Population

- (void)getCurrentTimelineEntryForComplication:(CLKComplication *)complication withHandler:(void(^)(CLKComplicationTimelineEntry * __nullable))handler {
    // Call the handler with the current timeline entry
    handler(nil);
}

- (void)getTimelineEntriesForComplication:(CLKComplication *)complication afterDate:(NSDate *)date limit:(NSUInteger)limit withHandler:(void(^)(NSArray<CLKComplicationTimelineEntry *> * __nullable entries))handler {
    // Call the handler with the timeline entries after the given date
    handler(nil);
}

#pragma mark - Sample Templates

- (void)getLocalizableSampleTemplateForComplication:(CLKComplication *)complication withHandler:(void(^)(CLKComplicationTemplate * __nullable complicationTemplate))handler {
    // This method will be called once per supported complication, and the results will be cached
    handler(nil);
}

@end
