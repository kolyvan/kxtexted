//
//  KxTextEdTests.m
//  KxTextEdTests
//
//  Created by Kolyvan on 09.12.15.
//  Copyright © 2015 Konstantin Bukreev. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "KxTextEdView.h"

@interface KxTextEdTests : XCTestCase

@end

@implementation KxTextEdTests {
    KxTextEdView *_textEd;
}

- (void)setUp {
    
    [super setUp];
    _textEd = [KxTextEdView new];
    _textEd.font = [UIFont fontWithName:@"Georgia" size:19.];
    _textEd.textColor = [UIColor blackColor];
    _textEd.text = @"Lorem ipsum dolor sit amet";
}

- (void)tearDown {
    [super tearDown];
}

- (void)testDefaultStyle {
    
    XCTAssertEqual(_textEd.styleFontBold, NO);
    XCTAssertEqual(_textEd.styleFontItalic, NO);
    XCTAssertEqual(_textEd.styleDecorUnderline, NO);
    XCTAssertEqual(_textEd.styleDecorStrikethrough, NO);
    XCTAssertEqual(_textEd.styleFontSize, 19.);
    XCTAssertEqualObjects(_textEd.styleFontName, @"Georgia");
    XCTAssertEqualObjects(_textEd.styleTextColor, [UIColor blackColor]);
    XCTAssertEqual(_textEd.styleParaAlignment, NSTextAlignmentLeft);
    XCTAssertEqual(_textEd.styleVertAlignSuper, NO);
    XCTAssertEqual(_textEd.styleVertAlignSub, NO);
}

- (void) testChangeTypingStyle {
    
    _textEd.styleFontBold = YES;
    _textEd.styleFontItalic = YES;
    _textEd.styleDecorUnderline = YES;
    _textEd.styleDecorStrikethrough = YES;
    _textEd.styleFontSize = 15.;
    _textEd.styleFontName = @"Helvetica";
    _textEd.styleTextColor = [UIColor redColor];
    
    XCTAssertEqual(_textEd.styleFontBold, YES);
    XCTAssertEqual(_textEd.styleFontItalic, YES);
    XCTAssertEqual(_textEd.styleDecorUnderline, YES);
    XCTAssertEqual(_textEd.styleDecorStrikethrough, YES);
    XCTAssertEqual(_textEd.styleFontSize, 15.);
    XCTAssertEqualObjects(_textEd.styleFontName, @"Helvetica");
    XCTAssertEqualObjects(_textEd.styleTextColor, [UIColor redColor]);
    
    _textEd.styleVertAlignSuper = YES;
    XCTAssertEqual(_textEd.styleVertAlignSuper, YES);
    XCTAssertEqual(_textEd.styleVertAlignSub, NO);
    
    _textEd.styleVertAlignSub = YES;
    XCTAssertEqual(_textEd.styleVertAlignSub, YES);
    XCTAssertEqual(_textEd.styleVertAlignSuper, NO);
}

- (void) testChangeTextStyle {
    
    [_textEd selectAll:nil];

    _textEd.styleFontBold = YES;
    _textEd.styleFontItalic = YES;
    _textEd.styleDecorUnderline = YES;
    _textEd.styleDecorStrikethrough = YES;
    _textEd.styleFontSize = 15.;
    _textEd.styleFontName = @"Helvetica";
    _textEd.styleTextColor = [UIColor redColor];
    
    _textEd.selectedRange = NSMakeRange(1, 1);
    
    XCTAssertEqual(_textEd.styleFontBold, YES);
    XCTAssertEqual(_textEd.styleFontItalic, YES);
    XCTAssertEqual(_textEd.styleDecorUnderline, YES);
    XCTAssertEqual(_textEd.styleDecorStrikethrough, YES);
    XCTAssertEqual(_textEd.styleFontSize, 15.);
    XCTAssertEqualObjects(_textEd.styleFontName, @"Helvetica");
    XCTAssertEqualObjects(_textEd.styleTextColor, [UIColor redColor]);
    
    
    _textEd.styleVertAlignSuper = YES;
    XCTAssertEqual(_textEd.styleVertAlignSuper, YES);
    XCTAssertEqual(_textEd.styleVertAlignSub, NO);
    
    _textEd.styleVertAlignSub = YES;
    XCTAssertEqual(_textEd.styleVertAlignSub, YES);
    XCTAssertEqual(_textEd.styleVertAlignSuper, NO);
}

- (void) testClearStyles {
    
    [_textEd selectAll:nil];
    
    _textEd.styleFontBold = YES;
    _textEd.styleFontItalic = YES;
    _textEd.styleDecorUnderline = YES;
    _textEd.styleDecorStrikethrough = YES;
    _textEd.styleFontSize = 15.;
    _textEd.styleFontName = @"Helvetica";
    _textEd.styleTextColor = [UIColor redColor];
    
    [_textEd clearStyles];
    
    XCTAssertEqual(_textEd.styleFontBold, NO);
    XCTAssertEqual(_textEd.styleFontItalic, NO);
    XCTAssertEqual(_textEd.styleDecorUnderline, NO);
    XCTAssertEqual(_textEd.styleDecorStrikethrough, NO);
    XCTAssertEqual(_textEd.styleFontSize, 19.);
    XCTAssertEqualObjects(_textEd.styleFontName, @"Georgia");
    XCTAssertEqualObjects(_textEd.styleTextColor, [UIColor blackColor]);
}

@end
