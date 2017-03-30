//
//  CheckinDemoUITests.m
//  CheckinDemoUITests
//
//  Created by eidan on 2017/3/29.
//  Copyright © 2017年 Amap. All rights reserved.
//

#import <XCTest/XCTest.h>

@interface CheckinDemoUITests : XCTestCase

@end

@implementation CheckinDemoUITests

- (void)setUp {
    [super setUp];
    
    // Put setup code here. This method is called before the invocation of each test method in the class.
    
    // In UI tests it is usually best to stop immediately when a failure occurs.
    self.continueAfterFailure = NO;
    // UI tests must launch the application that they test. Doing this in setup will make sure it happens for each test method.
    [[[XCUIApplication alloc] init] launch];
    
    // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}


- (void)testExample {
    
    
    XCUIApplication *app = [[XCUIApplication alloc] init];
    [app.buttons[@"开始定位"] tap];
    
    sleep(15);
    
    XCUIElement *maannotationcontainerElement = app.otherElements[@"maannotationcontainer"];
    
    [maannotationcontainerElement swipeRight];
    
    [self checkAlertWithTitleText:@"调整距离不可超过500米" cancelBtnText:@"确定" app:app test:self success:^{
        
        sleep(2);
        
        XCUIElementQuery *tablesQuery = app.tables;
        
        [tablesQuery.cells[@"POITableViewCell_0"] swipeUp];
        
        sleep(2);
        
        [tablesQuery.cells[@"POITableViewCell_3"] tap];
        
        [app.buttons[@"签到"] tap];
        
        [self checkAlertWithTitleText:@"签到成功" cancelBtnText:@"确定" app:app test:self success:^{
            
            XCTestExpectation *e = [self expectationWithDescription:@"empty wait"];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [e fulfill];
            });
            [self waitForExpectationsWithTimeout:5 handler:nil];
            
        } failure:^{
            XCTAssertFalse(@"签到失败");
        }];

        
    } failure:^{
        XCTAssertFalse(@"定位失败");
    }];
    
    
}

//alertView
- (void)checkAlertWithTitleText:(nonnull NSString *)text cancelBtnText:(nonnull NSString *)cancelBtnText app:(nonnull XCUIApplication *)app test:(nonnull XCTestCase *)test success:(nonnull void(^)())success failure:(nonnull void(^)())failure {
    
    __block BOOL result = NO;
    
    if (app == nil || test == nil) {
        failure();
        return;
    }
    
    XCUIElement *alert = app.alerts[text];
    
    NSPredicate *exists = [NSPredicate predicateWithFormat:@"exists == YES"];
    
    [test expectationForPredicate:exists evaluatedWithObject:alert handler:nil];
    
    [test waitForExpectationsWithTimeout:5 handler:^(NSError * _Nullable error) {
        result = YES;
    }];
    
    
    [alert.buttons[cancelBtnText] tap];
    
    if (result) {
        success();
    } else {
        failure();
    }
}

@end
