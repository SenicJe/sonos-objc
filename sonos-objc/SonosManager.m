//
//  SonosManager.m
//  Sonos Controller
//
//  Created by Axel Möller on 14/01/14.
//  Copyright (c) 2014 Appreviation AB. All rights reserved.
//

#import "SonosManager.h"
#import "SonosController.h"
#import "SonosDiscover.h"

@implementation SonosManager

+ (instancetype)sharedInstance {
    static SonosManager *sharedInstanceInstance = nil;
    static dispatch_once_t p;
    dispatch_once(&p, ^{
        sharedInstanceInstance = [[self alloc] init];
    });
    return sharedInstanceInstance;
}

- (id)init {
    self = [super init];
    
    if(self){
        self.coordinators = [[NSMutableArray alloc] init];
        self.slaves = [[NSMutableArray alloc] init];
    }
    
    return self;
}

- (void)refresh:(void (^)(SonosManager *))completionHandler {
    [SonosDiscover discoverControllers:^(NSArray *devices, NSError *error){
        
        [self willChangeValueForKey:@"allDevices"];
        
        self.coordinators = [[NSMutableArray alloc] init];
        self.slaves = [[NSMutableArray alloc] init];
        
        // Save all devices
        for(NSDictionary *device in devices) {
            SonosController *controller = [[SonosController alloc] initWithIP:[device valueForKey:@"ip"] port:[[device valueForKey:@"port"] intValue]];
            [controller setGroup:[device valueForKey:@"group"]];
            [controller setName:[device valueForKey:@"name"]];
            [controller setUuid:[device valueForKey:@"uuid"]];
            [controller setCoordinator:[[device valueForKey:@"coordinator"] boolValue]];
            if([controller isCoordinator])
                [self.coordinators addObject:controller];
            else
                [self.slaves addObject:controller];
        }
        
        // Add slaves to masters
        for(SonosController *slave in self.slaves) {
            for(SonosController *coordinator in self.coordinators) {
                if([[coordinator group] isEqualToString:[slave group]]) {
                    [[coordinator slaves] addObject:slave];
                    break;
                }
            }
        }
        
        [self didChangeValueForKey:@"allDevices"];
        
        if (completionHandler) {
            completionHandler(self);
        }
        
    }];
}

- (NSArray *)allDevices {
    return [self.coordinators arrayByAddingObjectsFromArray:self.slaves];
}

@end