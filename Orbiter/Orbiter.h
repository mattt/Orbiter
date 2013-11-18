// Orbiter.h
// 
// Copyright (c) 2012 Mattt Thompson (http://mattt.me/)
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
// 
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
// 
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import <Foundation/Foundation.h>

/**
 Orbiter provides simple interfaces to register (and unregister) for Push Notifications with Urban Airship and Parse (without needing to include their SDKs), as well as Helios apps.
 */
@interface Orbiter : NSObject

/**
 Initializes an Orbiter with the specified base URL and default credential.
 
 @param baseURL The base URL to be used to construct requests.
 @param credential The default credential to used for authentication challenges.
 */
- (id)initWithBaseURL:(NSURL *)baseURL
           credential:(NSURLCredential *)credential;

///----------------------------------
/// @name Registering / Unregistering
///----------------------------------

/**
 Register a given device token with specified alias to receive push notifications..
 
 @param deviceToken The device token. This can be either an `NSString` or `NSData` representation.
 @param alias The alias to be associated with the device token, such as a username or email address.
 @param success A block to be executed after successfully registering the device token for push notifications. The block has no return value and takes a single argument: the response object returned by the web service.
 @param failure A block to be executed after failing to register the device token for push notifications. The block has no return value and takes a single argument: the error encountered.
 */
- (void)registerDeviceToken:(id)deviceToken
                  withAlias:(NSString *)alias
                    success:(void (^)(id responseObject))success
                    failure:(void (^)(NSError *error))failure;

/**
 Register a given device token with specified alias to receive push notifications.
 
 @param deviceToken The device token. This can be either an `NSString` or `NSData` representation.
 @param payload The associated data to be passed along with the request.
 @param success A block to be executed after successfully registering the device token for push notifications. The block has no return value and takes a single argument: the response object returned by the web service.
 @param failure A block to be executed after failing to register the device token for push notifications. The block has no return value and takes a single argument: the error encountered.
 */
- (void)registerDeviceToken:(id)deviceToken
                withPayload:(NSDictionary *)payload
                    success:(void (^)(id responseObject))success
                    failure:(void (^)(NSError *error))failure;

/**
 Unregister a given device token with specified alias for push notifications.
 
 @param deviceToken The device token. This can be either an `NSString` or `NSData` representation.
 @param success A block to be executed after successfully unregistering the device token for push notifications. The block has no return value and takes no arguments.
 @param failure A block to be executed after failing to unregister the device token for push notifications. The block has no return value and takes a single argument: the error encountered.
 */
- (void)unregisterDeviceToken:(id)deviceToken
                      success:(void (^)())success
                      failure:(void (^)(NSError *error))failure;

///------------------------
/// @name Creating Requests
///------------------------

/**
 Creates a request for the registration of the specified device token with an optional payload.
 
 @param deviceToken The device token. This can be either an `NSString` or `NSData` representation.
 @param payload The associated data to be passed along with the request.
 
 @return The constructed push notification registration request.
 */
- (NSURLRequest *)requestForRegistrationOfDeviceToken:(id)deviceToken
                                          withPayload:(NSDictionary *)payload;

/**
 Creates a request for the unregistration of the specified device token.
 
 @param deviceToken The device token. This can be either an `NSString` or `NSData` representation.
 
 @return The constructed push notification unregistration request.
*/
- (NSURLRequest *)requestForUnregistrationOfDeviceToken:(id)deviceToken;

@end

#pragma mark -

/**
 A subclass of Orbiter for communicating with the Urban Airship push notification service.
 
 @see http://docs.urbanairship.com
 */
@interface UrbanAirshipOrbiter : Orbiter

/**
 Initializes an Urban Airship Orbiter with the specified API credentials.
 
 @param key Urban Airship generated string identifying the app setup. (e.g. -XurP5jfDUF1w01U9UUbNN)
 @param secret Urban Airship generated string identifying the app setup secret. (e.g. kFixrCslEgTUQHBOzXFFVN)
 */
+ (instancetype)urbanAirshipManagerWithApplicationKey:(NSString *)key
                                    applicationSecret:(NSString *)secret;

/**
 Register a given device token to receive push notifications.
 
 @param deviceToken The device token. This can be either an `NSString` or `NSData` representation.
 @param alias The alias to be associated with the device token, such as a username or email address.
 @param badge The badge count.
 @param tags The tags to be associated with the registration
 @param timeZone The time zone for this device
 @param quietTimeStartComponents The date components representing the daily start time for not receiving notifications.
 @param quietTimeEndComponents The date components representing the daily end time for not receiving notifications.
 @param success A block to be executed after successfully registering the device token for push notifications. The block has no return value and takes a single argument: the response object returned by the web service.
 @param failure A block to be executed after failing to register the device token for push notifications. The block has no return value and takes a single argument: the error encountered.
 */
- (void)registerDeviceToken:(id)deviceToken
                  withAlias:(NSString *)alias
                      badge:(NSNumber *)badge
                       tags:(NSSet *)tags
                   timeZone:(NSTimeZone *)timeZone
             quietTimeStart:(NSDateComponents *)quietTimeStartComponents
               quietTimeEnd:(NSDateComponents *)quietTimeEndComponents
                    success:(void (^)(id responseObject))success
                    failure:(void (^)(NSError *error))failure;

@end

#pragma mark -

/**
 A subclass of Orbiter for communicating with the Parse push notification service.

 @see https://parse.com/docs/push_guide
 */
@interface ParseOrbiter : Orbiter

/**
 Initializes a Parse Orbiter with the specified API credentials.

 @param applicationID The application identifier.
 @param RESTAPIKey The REST API key.
 */
+ (instancetype)parseManagerWithApplicationID:(NSString *)applicationID
                                   RESTAPIKey:(NSString *)RESTAPIKey;

/**
 Register a given device token to receive push notifications.
 
 @param deviceToken The device token. This can be either an `NSString` or `NSData` representation.
 @param alias The alias to be associated with the device token, such as a username or email address.
 @param badge The badge count.
 @param channels The channels to be associated with the registration
 @param success A block to be executed after successfully registering the device token for push notifications. The block has no return value and takes a single argument: the response object returned by the web service.
 @param failure A block to be executed after failing to register the device token for push notifications. The block has no return value and takes a single argument: the error encountered.
 */
- (void)registerDeviceToken:(id)deviceToken
                  withAlias:(NSString *)alias
                      badge:(NSNumber *)badge
                   channels:(NSSet *)tags
                   timeZone:(NSTimeZone *)timeZone
                    success:(void (^)(id responseObject))success
                    failure:(void (^)(NSError *error))failure;

@end
