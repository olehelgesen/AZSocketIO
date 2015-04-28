//
//  AZSocketIOTests.m
//  AZSocketIO
//
//  Created by Patrick Shields on 4/6/12.
//  Copyright 2012 Patrick Shields
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#import "Kiwi.h"
#import "AZSocketIO.h"

SPEC_BEGIN(Tests)
describe(@"The socket", ^{
    __block AZSocketIO *socket;
    context(@"before connection", ^{
        it(@"should be constructable", ^{
            socket = [[AZSocketIO alloc] initWithHost:@"localhost" andPort:@"9000" secure:NO];
            [socket shouldNotBeNil];
        });
        it(@"should queue messages", ^{
            NSError *error = nil;
            [[theValue([socket send:@"Hi" error:&error]) should] beFalse];
            [error shouldBeNil];
        });
        it(@"should say it's not connected", ^{
            [[theValue(socket.state) should] equal:@(AZSocketIOStateDisconnected)];
        });
    });
    context(@"when connecting", ^{
        __block NSDictionary *args;
        __block NSNumber *connected;
        it(@"can connect", ^{
            [socket connectWithSuccess:^{
                connected = [NSNumber numberWithBool:YES];
                socket.eventReceivedBlock = ^(NSString *name, id _args) {
                    args = _args;
                };
            } andFailure:^(NSError *error) {
                connected = [NSNumber numberWithBool:NO];
            }];
            [[expectFutureValue(connected) shouldEventually] equal:[NSNumber numberWithBool:YES]];
        });
        it(@"recieves an initial event", ^{
            [[expectFutureValue(args) shouldEventually] beNonNil];
        });
        it(@"should say it's connected", ^{
            [[theValue(socket.state) should] equal:@(AZSocketIOStateConnected)];
        });
    });
    context(@"after connecting", ^{
        it(@"can send a message and recieve the return val", ^{
            __block NSString *sent = @"FOO";
            __block NSString *received;
            [socket setEventReceivedBlock:^(NSString *eventName, id data) {
                received = [data objectAtIndex:0];
            }];
            [socket send:sent error:nil];
            [[expectFutureValue(received) shouldEventually] equal:sent];
        });
        it(@"can send a json message and recieve the return val", ^{
            __block NSDictionary *sent = [NSDictionary dictionaryWithObject:@"bar" forKey:@"foo"];;
            __block NSDictionary *received;
            [socket setEventReceivedBlock:^(NSString *eventName, id data) {
                received = [data objectAtIndex:0];
            }];
            [socket send:sent error:nil];
            [[expectFutureValue(received) shouldEventually] equal:sent];
        });
        it(@"can emit an event and recieve the return val", ^{
            __block NSString *name = @"ackLessEvent";
            __block NSArray *args = [NSArray arrayWithObject:@"bar"];
            __block NSString *receivedName;
            __block NSArray *receivedArgs;
            [socket addCallbackForEventName:name callback:^(NSString *eventName, id data) {
                receivedName = eventName;
                receivedArgs = data;
            }];
            [socket emit:name args:args error:nil];
            [[expectFutureValue(receivedName) shouldEventually] equal:name];
            [[expectFutureValue(receivedArgs) shouldEventually] equal:args];
        });
        it(@"can add and retrive and event callback", ^{
            NSString *eventName = @"testEvent";
            [socket addCallbackForEventName:eventName
                                   callback:^(NSString *eventName, id data) {
                                       
                                   }];
            
            NSArray *callbacks = [socket callbacksForEvent:eventName];
            [callbacks shouldNotBeNil];
            [[callbacks should] beKindOfClass:[NSArray class]];
            [[theValue(callbacks.count) should] equal:theValue(1)];
        });
        it(@"can add an event callback and remove when receiving event", ^{
            NSString *eventName = @"Oh happy day.";
            
            __block NSDictionary *sent = [NSDictionary dictionaryWithObject:@"bar" forKey:@"foo"];;
            __block NSDictionary *received;
            
            EventReceivedBlock __block callback = ^(NSString *eventName, id data) {
                received = [data objectAtIndex:0];
                [socket removeCallbackForEvent:eventName callback:callback];
            };
            
            [socket addCallbackForEventName:eventName callback:^(NSString *eventName, id data) {}];
            [socket addCallbackForEventName:eventName
                                   callback:callback];
            [socket addCallbackForEventName:eventName callback:^(NSString *eventName, id data) {}];
            
            NSArray *callbacks = [socket callbacksForEvent:eventName];
            [callbacks shouldNotBeNil];
            [[callbacks should] beKindOfClass:[NSArray class]];
            [[theValue(callbacks.count) should] equal:theValue(3)];
            
            [socket send:sent error:nil];
            [[expectFutureValue(received) shouldEventually] equal:sent];
            
            [socket removeCallbacksForEvent:eventName];
        });
        it(@"can register an ack callback", ^{
            __block NSString *name;
            [socket emit:@"ackWithArg" args:@"kthx"
                   error:nil
             ackWithArgs:^(NSArray *args) {
                 name = [args objectAtIndex:0];
             }];
            [[expectFutureValue(name) shouldEventually] equal:@"kthx"];
        });
        it(@"can recieve an empty ack callback", ^{
            __block BOOL empty = NO;
            [socket emit:@"ackWithoutArgs" args:@"never going to see this"
                   error:nil
                     ack:^() {
                         empty = YES;
                     }];
            [[expectFutureValue(theValue(empty)) shouldEventually] beTrue];
        });
        it(@"can recieve an ack callback with multiple return values", ^{
            __block NSString *one;
            __block NSString *two;
            [socket emit:@"ackWithArgs" args:[NSArray arrayWithObjects:@"one", @"two", nil]
                   error:nil
             ackWithArgs:^(NSArray *args) {
                 one = [args objectAtIndex:0];
                 two = [args objectAtIndex:1];
             }];
            [[expectFutureValue(one) shouldEventually] equal:@"one"];
            [[expectFutureValue(two) shouldEventually] equal:@"two"];
        });
        // https://github.com/pashields/AZSocketIO/issues/10
        it(@"should be able to emit with nil args", ^{
            [socket emit:@"foobar"
                    args:nil
                   error:nil
                     ack:nil];
        });
    });
    context(@"when disconnecting", ^{
        it(@"can disconnect", ^{
            __block BOOL disconnected = FALSE;
            [socket setDisconnectedBlock:^{
                disconnected = TRUE;
            }];
            [socket disconnect];
            [[expectFutureValue(theValue(disconnected)) shouldEventually] beTrue];
        });
    });
    context(@"after disconnecting", ^{
        it(@"should say it's not connected", ^{
            [[theValue(socket.state) should] equal:@(AZSocketIOStateDisconnected)];
        });
        __block NSString *sent = @"Hi", *received;
        it(@"can still queue messages", ^{
            [[theValue([socket send:sent error:nil]) should] beFalse];
        });
        __block BOOL connected = NO;
        __block NSString *initialEvent;
        it(@"can connect again using a different transport", ^{
            socket.transports = [NSSet setWithObject:@"xhr-polling"];
            [socket connectWithSuccess:^{
                connected = YES;
                socket.eventReceivedBlock = ^(NSString *name, id _args) {
                    initialEvent = name;
                    socket.eventReceivedBlock = ^(NSString *name, id _args) {
                        received = [_args objectAtIndex:0];
                    };
                };
            } andFailure:^(NSError *error) {}];
            [[expectFutureValue(theValue(connected)) shouldEventually] beYes];
            [[expectFutureValue(initialEvent) shouldEventually] equal:@"news"];
        });
        it(@"recieves a response from the queue message", ^{
            [[expectFutureValue(received) shouldEventually] equal:sent];
        });
    });
});
SPEC_END