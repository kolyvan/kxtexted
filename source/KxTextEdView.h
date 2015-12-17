//
//  KxTextEdView.h
//  https://github.com/kolyvan/kxtexted
//
//  Created by Kolyvan on 04.12.15.
//  Copyright © 2015 Konstantin Bukreev. All rights reserved.
//

/*
 Copyright (c) 2015 Konstantin Bukreev All rights reserved.
 
 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this
 list of conditions and the following disclaimer.
 
 - Redistributions in binary form must reproduce the above copyright notice,
 this list of conditions and the following disclaimer in the documentation
 and/or other materials provided with the distribution.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
 FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

#import <UIKit/UIKit.h>

@class KxTextEdInputAccessory;

@interface KxTextEdView : UITextView<UIImagePickerControllerDelegate, UINavigationControllerDelegate>

@property (readwrite, nonatomic) BOOL styleFontBold;
@property (readwrite, nonatomic) BOOL styleFontItalic;
@property (readwrite, nonatomic) BOOL styleDecorUnderline;
@property (readwrite, nonatomic) BOOL styleDecorStrikethrough;
@property (readwrite, nonatomic) CGFloat styleFontSize;
@property (readwrite, nonatomic, strong) NSString *styleFontName;
@property (readwrite, nonatomic, strong) UIColor *styleTextColor;
@property (readwrite, nonatomic, strong) UIColor *styleBackgColor;
@property (readwrite, nonatomic) NSTextAlignment styleParaAlignment;
@property (readwrite, nonatomic) BOOL styleVertAlignSuper;
@property (readwrite, nonatomic) BOOL styleVertAlignSub;
@property (readwrite, nonatomic) BOOL autoFormatList;
@property (readwrite, nonatomic) BOOL allowExtUndo;

- (void) increaseStyleParaIndent;
- (void) decreaseStyleParaIndent;
- (void) clearStyles;
- (void) formatListOrdered:(BOOL)ordered;
- (void) insertURL:(NSURL *)URL title:(NSString *)title;
- (void) askUserInsertURL;
- (void) insertImage:(UIImage *)image fileURL:(NSURL *)fileURL;
- (void) askUserInsertImage;
- (void) selectParagraph;
- (void) searchText:(NSString *)text selColor:(UIColor *)selColor;
- (void) caretGoLeft;
- (void) caretGoRight;
- (void) insertTabChar;

- (void) insertStringAtCaret:(NSString *)string style:(NSDictionary *)style;
- (void) insertAttributedStringAtCaret:(NSAttributedString *)astring;
- (NSRange) insertString:(NSString *)string range:(NSRange)range style:(NSDictionary *)style;
- (NSRange) insertAttributedString:(NSAttributedString *)astring range:(NSRange)range;
- (void) scrollToVisibleCaretAnimated:(BOOL)animated;

- (UIFont *)styleFont;

- (NSArray *) customMenuItems;
- (void) addCustomMenuItems;
- (void) actionEditLink:(id)sender;
- (void) actionOpenLink:(id)sender;

- (NSDictionary *) defaultStyle;

@end
