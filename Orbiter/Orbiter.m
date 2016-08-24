// Orbiter.m
//
// Copyright (c) 2012-2014 Mattt Thompson (http://mattt.me/)
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

#import "Orbiter.h"
#import "AFNetworking.h"

#if defined(__IPHONE_OS_VERSION_MIN_REQUIRED)
#import <UIKit/UIKit.h>
#endif

static NSString * AFNormalizedDeviceTokenStringWithDeviceToken(id deviceToken) {
  if ([deviceToken isKindOfClass:[NSData class]]) {
    const unsigned *bytes = [(NSData *)deviceToken bytes];
    return [NSString stringWithFormat:@"%08x%08x%08x%08x%08x%08x%08x%08x", ntohl(bytes[0]), ntohl(bytes[1]), ntohl(bytes[2]), ntohl(bytes[3]), ntohl(bytes[4]), ntohl(bytes[5]), ntohl(bytes[6]), ntohl(bytes[7])];
  } else {
    return [[[[deviceToken description] uppercaseString] stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"<>"]] stringByReplacingOccurrencesOfString:@" " withString:@""];
  }
}

@interface Orbiter ()
@property (readwrite, nonatomic, strong) AFHTTPSessionManager *SessionManager;
@end

@implementation Orbiter

#ifdef __CORELOCATION__
+ (CLLocationManager *)sharedLocationManager {
  static CLLocationManager *_sharedLocationManager = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    if ([CLLocationManager locationServicesEnabled]) {
      _sharedLocationManager = [[CLLocationManager alloc] init];
      _sharedLocationManager.desiredAccuracy = kCLLocationAccuracyKilometer;
      [_sharedLocationManager startUpdatingLocation];
    }
  });

  return _sharedLocationManager;
}
#endif

- (id)initWithBaseURL:(NSURL *)baseURL
           credential:(NSURLCredential *)credential
{
  self = [super init];
  if (!self) {
    return nil;
  }

  self.SessionManager = [[AFHTTPSessionManager alloc] initWithBaseURL:baseURL];
  //    self.SessionManager.credential = credential;

  AFJSONRequestSerializer *requestSerializer = [AFJSONRequestSerializer serializer];
  [requestSerializer setValue:@"application/json" forHTTPHeaderField:@"Accept"];
  self.SessionManager.requestSerializer = requestSerializer;

  self.SessionManager.responseSerializer = [AFHTTPResponseSerializer serializer];
  [self.SessionManager.responseSerializer setAcceptableContentTypes:[NSSet setWithObjects:@"application/json", @"text/plain", nil]];

  return self;
}

- (NSURLRequest *)requestForRegistrationOfDeviceToken:(id)deviceToken
                                          withPayload:(NSDictionary *)payload
{
  NSString *path = [NSString stringWithFormat:@"devices/%@", AFNormalizedDeviceTokenStringWithDeviceToken(deviceToken)];
  NSString *urlString = [[self.SessionManager.baseURL URLByAppendingPathComponent:path] absoluteString];
  return [self.SessionManager.requestSerializer requestWithMethod:@"PUT" URLString:urlString parameters:payload error:nil];
}

- (NSURLRequest *)requestForUnregistrationOfDeviceToken:(id)deviceToken {
  NSString *path = [NSString stringWithFormat:@"devices/%@", AFNormalizedDeviceTokenStringWithDeviceToken(deviceToken)];
  NSString *urlString = [[self.SessionManager.baseURL URLByAppendingPathComponent:path] absoluteString];
  return [self.SessionManager.requestSerializer requestWithMethod:@"DELETE" URLString:urlString parameters:nil error:nil];
}

#pragma mark -

- (void)registerDeviceToken:(NSString *)deviceToken
                  withAlias:(NSString *)alias
                    success:(void (^)(id responseObject))success
                    failure:(void (^)(NSError *error))failure
{
  NSMutableDictionary *mutablePayload = [NSMutableDictionary dictionary];
  [mutablePayload setValue:[[NSLocale currentLocale] localeIdentifier] forKey:@"locale"];
  [mutablePayload setValue:[[NSLocale preferredLanguages] objectAtIndex:0] forKey:@"language"];
  [mutablePayload setValue:[[NSTimeZone defaultTimeZone] name] forKey:@"timezone"];

#ifdef __CORELOCATION__
  CLLocation *location = [[[self class] sharedLocationManager] location];
  if (location) {
    [mutablePayload setValue:[[NSNumber numberWithDouble:location.coordinate.latitude] stringValue] forKey:@"lat"];
    [mutablePayload setValue:[[NSNumber numberWithDouble:location.coordinate.longitude] stringValue] forKey:@"lng"];
  }
#endif

  NSMutableSet *mutableTags = [NSMutableSet set];
  [mutableTags addObject:[NSString stringWithFormat:@"v%@", [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"]]];

#if defined(__IPHONE_OS_VERSION_MIN_REQUIRED)
  [mutableTags addObject:[[UIDevice currentDevice] model]];
  [mutableTags addObject:[NSString stringWithFormat:@"%@ %@", [[UIDevice currentDevice] systemName], [[UIDevice currentDevice] systemVersion]]];
#elif defined(__MAC_OS_X_VERSION_MIN_REQUIRED)
  [mutableTags addObject:[[NSProcessInfo processInfo] operatingSystemVersionString]];
#endif

  [mutablePayload setValue:[mutableTags allObjects] forKey:@"tags"];

  if (alias) {
    [mutablePayload setValue:alias forKey:@"alias"];
  }

  [self registerDeviceToken:deviceToken withPayload:mutablePayload success:success failure:failure];
}

- (void)registerDeviceToken:(NSString *)deviceToken
                withPayload:(NSDictionary *)payload
                    success:(void (^)(id responseObject))success
                    failure:(void (^)(NSError *error))failure
{
  NSURLRequest *request = [self requestForRegistrationOfDeviceToken:deviceToken withPayload:payload];

  [self.SessionManager dataTaskWithRequest:request uploadProgress:nil downloadProgress:nil completionHandler:^(NSURLResponse * _Nonnull response, id  _Nullable responseObject, NSError * _Nullable error) {
    if (error && failure) {
      failure(error);
    }else{
      if (success) {
        success(responseObject);
      }
    }
  }];
}

- (void)unregisterDeviceToken:(NSString *)deviceToken
                      success:(void (^)())success
                      failure:(void (^)(NSError *error))failure
{
  NSURLRequest *request = [self requestForUnregistrationOfDeviceToken:deviceToken];

  [self.SessionManager dataTaskWithRequest:request uploadProgress:nil downloadProgress:nil completionHandler:^(NSURLResponse * _Nonnull response, id  _Nullable responseObject, NSError * _Nullable error) {
    if (error && failure) {
      failure(error);
    }else{
      if (success) {
        success(responseObject);
      }
    }
  }];
}

@end

#pragma mark -

static NSString * const kUrbanAirshipAPIBaseURLString = @"https://go.urbanairship.com/api/";

@implementation UrbanAirshipOrbiter

+ (instancetype)urbanAirshipManagerWithApplicationKey:(NSString *)key
                                    applicationSecret:(NSString *)secret
{
  return [[UrbanAirshipOrbiter alloc] initWithBaseURL:[NSURL URLWithString:kUrbanAirshipAPIBaseURLString] credential:[NSURLCredential credentialWithUser:key password:secret persistence:NSURLCredentialPersistenceForSession]];
}

#pragma mark - Orbiter

- (id)initWithBaseURL:(NSURL *)baseURL
           credential:(NSURLCredential *)credential
{
  self = [super initWithBaseURL:baseURL credential:credential];
  if (!self) {
    return nil;
  }

  [self.SessionManager.requestSerializer setValue:@"*/*" forHTTPHeaderField:@"Accept"];

  return self;
}

- (NSURLRequest *)requestForRegistrationOfDeviceToken:(id)deviceToken
                                          withPayload:(NSDictionary *)payload
{
  NSString *path = [NSString stringWithFormat:@"device_tokens/%@", AFNormalizedDeviceTokenStringWithDeviceToken(deviceToken)];
  NSString *urlString = [[self.SessionManager.baseURL URLByAppendingPathComponent:path] absoluteString];
  return [self.SessionManager.requestSerializer requestWithMethod:@"PUT" URLString:urlString parameters:payload error:nil];
}

- (NSURLRequest *)requestForUnregistrationOfDeviceToken:(id)deviceToken
{
  NSString *path = [NSString stringWithFormat:@"device_tokens/%@", AFNormalizedDeviceTokenStringWithDeviceToken(deviceToken)];
  NSString *urlString = [[self.SessionManager.baseURL URLByAppendingPathComponent:path] absoluteString];
  return [self.SessionManager.requestSerializer requestWithMethod:@"DELETE" URLString:urlString parameters:nil error:nil];
}

- (void)registerDeviceToken:(NSString *)deviceToken
                  withAlias:(NSString *)alias
                    success:(void (^)(id responseObject))success
                    failure:(void (^)(NSError *error))failure
{
  [self registerDeviceToken:deviceToken withAlias:alias badge:nil tags:nil timeZone:[NSTimeZone defaultTimeZone] quietTimeStart:nil quietTimeEnd:nil success:success failure:failure];
}

- (void)registerDeviceToken:(NSString *)deviceToken
                  withAlias:(NSString *)alias
                      badge:(NSNumber *)badge
                       tags:(NSSet *)tags
                   timeZone:(NSTimeZone *)timeZone
             quietTimeStart:(NSDateComponents *)quietTimeStartComponents
               quietTimeEnd:(NSDateComponents *)quietTimeEndComponents
                    success:(void (^)(id responseObject))success
                    failure:(void (^)(NSError *error))failure
{
  NSMutableDictionary *mutablePayload = [NSMutableDictionary dictionary];
  if (alias) {
    [mutablePayload setValue:alias forKey:@"alias"];
  }

  if (badge) {
    [mutablePayload setValue:[badge stringValue] forKey:@"badge"];
  }

  if (tags && [tags count] > 0) {
    [mutablePayload setValue:[tags allObjects] forKey:@"tags"];
  }

  if (quietTimeStartComponents && quietTimeEndComponents) {
    NSMutableDictionary *mutableQuietTimePayload = [NSMutableDictionary dictionary];
    [mutableQuietTimePayload setValue:[NSString stringWithFormat:@"%02ld:%02ld", (long)[quietTimeStartComponents hour], (long)[quietTimeStartComponents minute]] forKey:@"start"];
    [mutableQuietTimePayload setValue:[NSString stringWithFormat:@"%02ld:%02ld", (long)[quietTimeEndComponents hour], (long)[quietTimeEndComponents minute]] forKey:@"end"];
    [mutablePayload setValue:mutableQuietTimePayload forKey:@"quiettime"];
  }

  if (timeZone) {
    [mutablePayload setValue:[timeZone name] forKey:@"tz"];
  }

  [self registerDeviceToken:deviceToken withPayload:mutablePayload success:success failure:failure];
}

@end

#pragma mark -

static NSString * const kParseAPIBaseURLString = @"https://api.parse.com/1/";

@implementation ParseOrbiter

+ (instancetype)parseManagerWithApplicationID:(NSString *)applicationID
                                   RESTAPIKey:(NSString *)RESTAPIKey
{
  ParseOrbiter *orbiter = [[ParseOrbiter alloc] initWithBaseURL:[NSURL URLWithString:kParseAPIBaseURLString] credential:nil];
  [orbiter.SessionManager.requestSerializer setValue:applicationID forHTTPHeaderField:@"X-Parse-Application-Id"];
  [orbiter.SessionManager.requestSerializer setValue:RESTAPIKey forHTTPHeaderField:@"X-Parse-REST-API-Key"];

  return orbiter;
}

#pragma mark - Orbiter

- (NSURLRequest *)requestForRegistrationOfDeviceToken:(__unused id)deviceToken
                                          withPayload:(NSDictionary *)payload
{
  NSString *path = [[self.SessionManager.baseURL URLByAppendingPathComponent:@"installations"] absoluteString];
  return [self.SessionManager.requestSerializer requestWithMethod:@"POST" URLString:path parameters:payload error:nil];
}

- (NSURLRequest *)requestForUnregistrationOfDeviceToken:(__unused id)deviceToken {
  return nil;
}


- (void)registerDeviceToken:(id)deviceToken
                  withAlias:(NSString *)alias
                    success:(void (^)(id))success
                    failure:(void (^)(NSError *))failure
{
  [self registerDeviceToken:deviceToken withAlias:alias badge:nil channels:nil timeZone:[NSTimeZone defaultTimeZone] success:success failure:failure];
}

- (void)registerDeviceToken:(id)deviceToken
                  withAlias:(NSString *)alias
                      badge:(NSNumber *)badge
                   channels:(NSSet *)channels
                   timeZone:(NSTimeZone *)timeZone
                    success:(void (^)(id responseObject))success
                    failure:(void (^)(NSError *error))failure
{
  NSMutableDictionary *mutablePayload = [NSMutableDictionary dictionary];
  [mutablePayload setValue:@"ios" forKey:@"deviceType"];
  [mutablePayload setValue:AFNormalizedDeviceTokenStringWithDeviceToken(deviceToken) forKey:@"deviceToken"];

  if (badge) {
    [mutablePayload setValue:[badge stringValue] forKey:@"badge"];
  }

  if (channels && [channels count] > 0) {
    [mutablePayload setValue:[channels allObjects] forKey:@"channels"];
  }

  if (timeZone) {
    [mutablePayload setValue:[timeZone name] forKey:@"timeZone"];
  }

  [self registerDeviceToken:deviceToken withPayload:mutablePayload success:success failure:failure];
}

- (void)unregisterDeviceToken:(__unused id)deviceToken
                      success:(__unused void (^)())success
                      failure:(__unused void (^)(NSError *))failure
{
  [NSException raise:@"Unregistraion not supported by Parse API" format:nil];
}

@end
