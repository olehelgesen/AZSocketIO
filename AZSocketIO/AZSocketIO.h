//
//  AZSocketIO.h
//  AZSocketIO
//
//  Created by Patrick Shields on 4/6/12.
//  Copyright (c) 2012 Rally Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AZsocketIOTransportDelegate.h"

typedef void (^MessageRecievedBlock)(id data);
typedef void (^EventRecievedBlock)(NSString *eventName, id data);
typedef void (^ConnectedBlock)();
typedef void (^FailedConnectionBlock)(NSError *error);
typedef void (^DisconnectedBlock)();

@interface AZSocketIO : NSObject <AZSocketIOTransportDelegate>
@property(nonatomic, strong)NSString *host;
@property(nonatomic, strong)NSString *port;
@property(nonatomic, strong)NSArray *transports;
@property(nonatomic, strong)NSString *sessionId;
@property(nonatomic, strong)NSCondition *connected;

@property(nonatomic, copy)MessageRecievedBlock messageRecievedBlock;
@property(nonatomic, copy)EventRecievedBlock eventRecievedBlock;
@property(nonatomic, copy)DisconnectedBlock disconnectedBlock;
- (id)initWithHost:(NSString *)host andPort:(NSString *)port;
- (void)connectWithSuccess:(ConnectedBlock)success andFailure:(FailedConnectionBlock)failure;
@end
