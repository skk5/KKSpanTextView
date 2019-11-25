//
//  KKSpanTextViewDemoTests.m
//  KKSpanTextViewDemoTests
//
//  Created by ewing on 2019/11/1.
//

#import <XCTest/XCTest.h>
#import "KKSpanTextView.h"

@interface KKSpanTextViewDemoTests : XCTestCase

@property (nonatomic, strong) KKSpanTextView *testTarget;

@end

@implementation KKSpanTextViewDemoTests

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
    self.testTarget = [[KKSpanTextView alloc] initWithFrame:CGRectMake(0, 0, 200, 200)];
}

- (BOOL)checkTextViewBy:(NSString *)markedText
{
    NSMutableString *resultString = [NSMutableString string];
    NSArray *content = [_testTarget allContent];
    for (id obj in content) {
        if ([obj isKindOfClass:[NSString class]]) {
            [resultString appendString:obj];
        } else if ([obj isKindOfClass:[NSAttributedString class]]) {
            [resultString appendFormat:@"<span>%@</span>", [(NSAttributedString *)obj string]];
        }
    }
    
    return [markedText isEqualToString:resultString];
}

- (NSAttributedString *)spanTextForTest
{
    NSAttributedString *attr = [[NSAttributedString alloc] initWithString:@"你好Test😊🙂xgfFy"];
    return attr;
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    
}

- (void)testExample {
    // This is an example of a functional test case.
    // Use XCTAssert and related functions to verify your tests produce the correct results.
    _testTarget.attributedText = [self spanTextForTest];
    XCTAssert([self checkTextViewBy:@"你好Test😊🙂xgfFy"]);
    
    [_testTarget insertSpanText:[[NSAttributedString alloc] initWithString:@"span1"] atIndex:0];
    XCTAssert([self checkTextViewBy:@"<span>span1</span>你好Test😊🙂xgfFy"]);
    
    [_testTarget insertSpanTextAtCaret:[[NSAttributedString alloc] initWithString:@"span2"]];
    XCTAssert([self checkTextViewBy:@"<span>span1</span>你好Test😊🙂xgfFy<span>span2</span>"]);
    
    BOOL rslt = [_testTarget insertSpanText:[[NSAttributedString alloc] initWithString:@"span3"] atIndex:1];
    XCTAssert(!rslt);
    XCTAssert([self checkTextViewBy:@"<span>span1</span>你好Test😊🙂xgfFy<span>span2</span>"]);
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

@end
