//
//  KxTextEdView.m
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

#import "KxTextEdView.h"
#import "UIFont+KxTextEd.h"
#import "UIImage+KxTextEd.h"
#import "KxTextEdInputAccessory.h"

static NSString *const KxTextEdViewListItemAttribute = @"KxTextEdViewListItemAttribute";
static NSString *const KxTextEdViewSearchAttribute = @"KxTextEdViewSearchAttribute";


@interface KxTextEdView()<UITextViewDelegate>
@property (readwrite, nonatomic, weak) id<UITextViewDelegate> realDelegate;
@end

@implementation KxTextEdView {
    
    UIImagePickerController *_imagePicker;
    UIFont                  *_defaultFont;
    UIColor                 *_defaultTextColor;
}

- (instancetype) initWithFrame:(CGRect)frame
{    
    NSTextStorage *textStorage = [NSTextStorage new];
    NSLayoutManager *layoutManager = [NSLayoutManager new];
    NSTextContainer *textContainer = [[NSTextContainer alloc] initWithSize:(CGSize){frame.size.width, HUGE_VALF}];
    textContainer.widthTracksTextView = YES;
    
    [layoutManager addTextContainer:textContainer];
    [textStorage removeLayoutManager:textStorage.layoutManagers.firstObject];
    [textStorage addLayoutManager:layoutManager];
    
    if ((self = [super initWithFrame:frame textContainer:textContainer])) {
        [self commonInit];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    if ((self = [super initWithCoder:coder])) {
        [self commonInit];
    }
    return self;
}

- (void) commonInit
{
    self.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    self.textColor = [UIColor darkTextColor];
    self.backgroundColor = [UIColor whiteColor];
    self.opaque = YES;
    self.editable = YES;
    self.selectable = YES;
    self.dataDetectorTypes = UIDataDetectorTypeNone;
    self.showsHorizontalScrollIndicator = NO;
    
    super.delegate = self;
    
    _autoFormatList = YES;
    _allowExtUndo = YES;
}

- (void)dealloc
{
    self.delegate = nil;
}

#pragma mark - properties

- (BOOL) styleFontBold
{
    return self.styleFont.texted_hasBoldStyle;
}

- (void) setStyleFontBold:(BOOL)bold
{
    UIFont *font = self.styleFont;
    UIFont *newFont = bold ? font.texted_fontWithBoldStyle : font.texted_fontWithDiscardBoldStyle;
    if (![font isEqual:newFont]) {
        [self updateAttribute:NSFontAttributeName value:newFont];
    }
}

- (BOOL) styleFontItalic
{
    return self.styleFont.texted_hasItalicStyle;
}

- (void) setStyleFontItalic:(BOOL)italic
{
    UIFont *font = self.styleFont;
    UIFont *newFont = italic ? font.texted_fontWithItalicStyle : font.texted_fontWithDiscardItalicStyle;
    if (![font isEqual:newFont]) {
        [self updateAttribute:NSFontAttributeName value:newFont];
    }
}

- (NSString *) styleFontName
{
    return self.styleFont.familyName;
}

- (void) setStyleFontName:(NSString *)name
{
    UIFont *font = self.styleFont;
    UIFont *newFont = [font texted_fontWithFamily:name];
    if (![font isEqual:newFont]) {
        [self updateAttribute:NSFontAttributeName value:newFont];
    }
}

- (CGFloat) styleFontSize
{
    return self.styleFont.pointSize;
}

- (void) setStyleFontSize:(CGFloat)newSize
{
    UIFont *font = self.styleFont;
    UIFont *newFont = [font fontWithSize:newSize];
    if (![font isEqual:newFont]) {
        [self updateAttribute:NSFontAttributeName value:newFont];
    }
}

- (BOOL) styleDecorUnderline
{
    NSNumber *n = [self styleAttribute:NSUnderlineStyleAttributeName];
    return n ? n.unsignedIntegerValue != NSUnderlineStyleNone : NO;
}

- (void) setStyleDecorUnderline:(BOOL)newStyle
{
    const BOOL style = self.styleDecorUnderline;
    if (style != newStyle) {
        [self updateAttribute:NSUnderlineStyleAttributeName value:@(newStyle)];
    }
}

- (BOOL) styleDecorStrikethrough
{
    NSNumber *n = [self styleAttribute:NSStrikethroughStyleAttributeName];
    return n ? n.boolValue : NO;
}

- (void) setStyleDecorStrikethrough:(BOOL)strike
{
    const BOOL style = self.styleDecorStrikethrough;
    const BOOL newStyle = strike;
    if (style != newStyle) {
        [self updateAttribute:NSStrikethroughStyleAttributeName value:@(newStyle)];
    }
}

- (BOOL) styleVertAlignSuper
{
    NSNumber *n = [self styleAttribute:NSBaselineOffsetAttributeName];
    return n ? n.floatValue > 1. : NO;
}

- (void) setStyleVertAlignSuper:(BOOL)newStyle
{
    const BOOL style = self.styleVertAlignSuper;
    if (style != newStyle) {
        [self.textStorage beginEditing];
        if (newStyle) {
            const CGFloat baseline = roundf(_defaultFont.pointSize * 0.2);
            const CGFloat fontSize = roundf(_defaultFont.pointSize * 0.7);
            [self updateAttribute:NSBaselineOffsetAttributeName value:@(baseline)];
            [self setStyleFontSize:fontSize];
        } else {
            [self updateAttribute:NSBaselineOffsetAttributeName value:@0.];
            [self setStyleFontSize:_defaultFont.pointSize];
        }
        [self.textStorage endEditing];
    }
}

- (BOOL) styleVertAlignSub
{
    NSNumber *n = [self styleAttribute:NSBaselineOffsetAttributeName];
    return n ? n.floatValue < -1. : NO;
}

- (void) setStyleVertAlignSub:(BOOL)newStyle
{
    const BOOL style = self.styleVertAlignSub;
    if (style != newStyle) {
        [self.textStorage beginEditing];
        if (newStyle) {
            const CGFloat baseline = roundf(_defaultFont.pointSize * 0.2);
            const CGFloat fontSize = roundf(_defaultFont.pointSize * 0.7);
            [self updateAttribute:NSBaselineOffsetAttributeName value:@(-baseline)];
            [self setStyleFontSize:fontSize];
        } else {
            [self updateAttribute:NSBaselineOffsetAttributeName value:@0.];
            [self setStyleFontSize:_defaultFont.pointSize];
        }
        [self.textStorage endEditing];
    }
}

- (UIColor *)styleTextColor
{
    UIColor *color = [self styleAttribute:NSForegroundColorAttributeName];
    return color ?: _defaultTextColor;
}

- (void) setStyleTextColor:(UIColor *)newColor
{
    const UIColor *color = self.styleTextColor;
    if (![color isEqual:newColor]) {
        [self updateAttribute:NSForegroundColorAttributeName value:newColor];
    }
}

- (UIColor *)styleBackgColor
{
    UIColor *color = [self styleAttribute:NSBackgroundColorAttributeName];
    return color ?: self.backgroundColor;
}

- (void) setStyleBackgColor:(UIColor *)newColor
{
    const UIColor *color = self.styleBackgColor;
    if (![color isEqual:newColor]) {
        [self updateAttribute:NSBackgroundColorAttributeName value:newColor];        
    }
}

- (NSTextAlignment) styleParaAlignment
{
    NSParagraphStyle *para = [self attribute:NSParagraphStyleAttributeName atRange:self.selectedRange];
    return para ? para.alignment : NSTextAlignmentLeft;
}

- (void) setStyleParaAlignment:(NSTextAlignment)newAlign
{
    [self updateParaAttribute:^(NSMutableParagraphStyle *para) {
        if (para.alignment != newAlign) {
            para.alignment = newAlign;
            return YES;
        }
        return NO;
    }];
}

#pragma mark - public methods

- (void) increaseStyleParaIndent
{
    const CGFloat kStep = 10.;
    [self updateParaAttribute:^(NSMutableParagraphStyle *para) {
        if (para.headIndent < 100.) {
            para.headIndent = para.firstLineHeadIndent  = para.headIndent + kStep;
            return YES;
        }
        return NO;
    }];
}

- (void) decreaseStyleParaIndent
{
    const CGFloat kStep = 10.;
    [self updateParaAttribute:^(NSMutableParagraphStyle *para) {
        if (para.headIndent) {
            para.headIndent = para.firstLineHeadIndent  = MAX(0, para.headIndent - kStep);
            return YES;
        }
        return NO;
    }];
}

- (void) clearStyles
{
    const NSRange selRange = self.selectedRange;
    if (selRange.length) {

        [self.textStorage beginEditing];
        [self.textStorage setAttributes:self.defaultStyle range:selRange];
        [self.textStorage endEditing];
        
        if (_allowExtUndo) {
            [self.undoManager removeAllActionsWithTarget:self];
        }
        
    } else {
        
        self.typingAttributes = self.defaultStyle;
    }
}

- (void) formatListOrdered:(BOOL)ordered
{
    NSDictionary *atts = self.styleListItem;
    
    NSUInteger index = 1;
    const NSRange selRange = self.selectedRange;
    NSUInteger loc = selRange.location;
    NSUInteger inserted = 0;
    
    [self.textStorage beginEditing];
    
    while (loc <= NSMaxRange(selRange)) {
        
        const NSRange range = [self.textStorage.string lineRangeForRange:NSMakeRange(loc, 0)];

        NSString *number = [NSString stringWithFormat:@"%u. ", (unsigned)index];
        NSString *bullet = @"\u2022 ";
        NSString *string = ordered ? number : bullet;
        
        NSString *text = [self.textStorage.string substringWithRange:range];
        
        if ([text hasPrefix:string]) {
            
            loc += range.length;
            
        } else {
            
            NSUInteger length = 0;
            if (ordered && [text hasPrefix:bullet]) {
                length = bullet.length;
            } else if (!ordered && [text hasPrefix:number]) {
                length = number.length;
            }
        
            NSAttributedString *as = [[NSAttributedString alloc] initWithString:string attributes:atts];
            [self insertAttributedString:as range:NSMakeRange(range.location, length)];
            
            if (!range.length) {
                break;
            }
            
            loc += range.length + string.length;
            inserted += string.length;
        }
        
        index += 1;
    }
    
    [self.textStorage endEditing];
    
    if (inserted) {
        if (selRange.length) {
            self.selectedRange = NSMakeRange(selRange.location, selRange.length + inserted);
        } else {
            self.selectedRange = NSMakeRange(NSMaxRange(selRange) + inserted, 0);
        }
    }
}

- (void) insertURL:(NSURL *)URL title:(NSString *)title
{
    if (!URL) {
        return;
    }
    
    if (!title.length) {
        title = URL.host;
    }
    
    NSDictionary *atts = @{
                           NSFontAttributeName : self.styleFont,
                           NSForegroundColorAttributeName : self.styleTextColor,
                           NSLinkAttributeName : URL,
                           };
    
    NSAttributedString *as = [[NSAttributedString alloc] initWithString:title attributes:atts];
    [self insertAttributedStringAtCaret:as];
}

- (void) askUserInsertURL
{
    NSString *linkTitle, *urlString;
    BOOL editLink = NO;
    
    const NSUInteger textLen = self.textStorage.length;
    if (textLen) {
        
        const NSRange selRange = self.selectedRange;
        
        NSRange linkRange = {0};
        NSRange paraRange = [self.textStorage.string paragraphRangeForRange:selRange];
        if (paraRange.location == NSNotFound) {
            paraRange = (NSRange){0, textLen};
        }
        
        NSUInteger caretIndex = selRange.location;
        if (caretIndex >= textLen) {
            caretIndex = textLen - 1;
        }
        
        if ([self.textStorage attribute:NSLinkAttributeName
                                atIndex:caretIndex
                  longestEffectiveRange:&linkRange
                                inRange:paraRange] &&
            linkRange.length)
        {
            self.selectedRange = linkRange;
            
            UITextRange *selectionRange = [self selectedTextRange];
            NSString *text = [self textInRange:selectionRange];
            if (text.length) {
                
                NSURL *URL = [self attribute:NSLinkAttributeName atRange:self.selectedRange];
                if (URL) {
                    
                    editLink = YES;
                    linkTitle = text;
                    urlString = URL.absoluteString;
                    
                } else {
                    
                    URL = [NSURL URLWithString:text];
                    if (URL) {
                        linkTitle = URL.host;
                        urlString = URL.absoluteString;
                    } else {
                        linkTitle = text;
                    }
                }
            }
        }
    }
    
    UIAlertController *alert;
    alert = [UIAlertController alertControllerWithTitle:editLink ? NSLocalizedString(@"Edit Link", nil) : NSLocalizedString(@"Insert Link", nil)
                                                message:nil
                                         preferredStyle:UIAlertControllerStyleAlert];
    
    [alert addTextFieldWithConfigurationHandler:^(UITextField * textField) {
        textField.placeholder = NSLocalizedString(@"Title", nil);
        textField.text = linkTitle;
    }];
    
    [alert addTextFieldWithConfigurationHandler:^(UITextField * textField) {
        textField.placeholder = NSLocalizedString(@"URL", nil);
        textField.text = urlString;
    }];
    
    __weak __typeof(self) weakSelf = self;
    [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Done", nil)
                                              style:UIAlertActionStyleDefault
                                            handler:^(UIAlertAction * action)
    {
        NSString *title = alert.textFields[0].text;
        NSString *urlString = alert.textFields[1].text;
        
        if (urlString.length) {
            
            if (![urlString hasPrefix:@"http:"] &&
                ![urlString hasPrefix:@"https:"] &&
                ![urlString hasPrefix:@"mailto:"] &&
                ![urlString hasPrefix:@"//"])
            {
                urlString = [@"http://" stringByAppendingString:urlString];
            }
            NSURL *URL = [NSURL URLWithString:urlString];
            [weakSelf insertURL:URL title:title];
        }

    }]];
    
    [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil)
                                              style:UIAlertActionStyleCancel
                                            handler:nil]];
    
    [self.window.rootViewController presentViewController:alert animated:YES completion:nil];
}

- (void) insertImage:(UIImage *)image fileURL:(NSURL *)fileURL
{
    NSFileWrapper *fileWrapper;
    if (fileURL && fileURL.isFileURL) {
        fileWrapper = [[NSFileWrapper alloc] initWithURL:fileURL options:0 error:nil];
    }
    
    if (!fileWrapper && !image) {
        return;
    }
    
    NSString *UTI;
    CGSize imgSize = {0};
    
    if (fileURL) {
        UTI = [UIImage texted_sourceTypeWithPath:fileURL.path
                                            size:image ? NULL : &imgSize];
    }
    
    if (!UTI) {
        UTI = @"public.image"; //kUTTypeImage
    }
    
    if (image) {
        imgSize = image.size;
    }

    const CGSize maxSize = {
        self.textContainer.size.width - self.textContainer.lineFragmentPadding * 2. - self.textContainerInset.left - self.textContainerInset.right,
        self.bounds.size.height - - self.textContainerInset.top - self.textContainerInset.bottom,
    };
    
    if (CGSizeEqualToSize(imgSize, CGSizeZero)) {
        
        imgSize.width = maxSize.width * 0.5;
        imgSize.height = maxSize.height * 0.5;
        
    } else {
        
        if (imgSize.width > maxSize.width) {
            
            imgSize.height *= (maxSize.width / imgSize.width);
            imgSize.width = maxSize.width;
        }
        
        if (imgSize.height > maxSize.height) {
            
            imgSize.width *= (maxSize.height / imgSize.height);
            imgSize.height = maxSize.height;
        }
        
        if (image &&
            (image.size.width > imgSize.width ||
             image.size.height > imgSize.height))
        {
            const CGFloat R = MIN(imgSize.width / image.size.width,
                                  imgSize.height / image.size.height);
            UIImage *resized = [image texted_resizeImageWithRatio:R];
            if (resized) {
                image = resized;
                imgSize = resized.size;
            }
        }
    }
    
    NSTextAttachment *textAttach = [[NSTextAttachment alloc] initWithData:nil ofType:UTI];
    
    textAttach.bounds = (CGRect){0, 0, roundf(imgSize.width), roundf(imgSize.height)};
    
    if (fileWrapper) {
        textAttach.fileWrapper = fileWrapper;
    } else  {
        textAttach.image = image;
    }
    
    NSAttributedString *as = [NSAttributedString attributedStringWithAttachment:textAttach];
    
    NSMutableAttributedString *mas = [as mutableCopy];
    [mas addAttributes:self.defaultStyle range:NSMakeRange(0, mas.length)];
    as = [mas copy];

    [self insertAttributedStringAtCaret:as];
}

- (void) askUserInsertImage
{
    const UIImagePickerControllerSourceType sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    
    if (![UIImagePickerController isSourceTypeAvailable:sourceType]) {
        return;
    }
    if (![[UIImagePickerController availableMediaTypesForSourceType:sourceType] containsObject:@"public.image"]) {
        return;
    }
    
    _imagePicker = [UIImagePickerController new];
    _imagePicker.modalPresentationStyle = UIModalPresentationCurrentContext;
    _imagePicker.sourceType = sourceType;
    _imagePicker.mediaTypes = @[@"public.image"]; //kUTTypeImage
    _imagePicker.delegate = self;
    _imagePicker.allowsEditing = NO;
    
    UIViewController *vc = self.window.rootViewController;
    if (vc.presentedViewController) {
        vc = vc.presentedViewController;
    }
    
    [vc presentViewController:_imagePicker animated:YES completion:nil];
}

- (void) selectParagraph
{
    NSRange paraRange = [self.textStorage.string paragraphRangeForRange:self.selectedRange];
    if (paraRange.length) {
        if (paraRange.length > 1) {
            paraRange.length -= 1; // skip term \n
        }
        self.selectedRange = paraRange;
    }
}

- (void) searchText:(NSString *)pattern
           selColor:(UIColor *)selColor
{
    [self.textStorage beginEditing];
    
    [self.textStorage enumerateAttribute:KxTextEdViewSearchAttribute
                                 inRange:NSMakeRange(0, self.textStorage.length)
                                 options:NSAttributedStringEnumerationLongestEffectiveRangeNotRequired
                              usingBlock:^(id  value, NSRange range, BOOL *stop)
    {
        [self.textStorage removeAttribute:KxTextEdViewSearchAttribute range:range];
        [self.textStorage removeAttribute:NSBackgroundColorAttributeName range:range];
    }];
    
    if (pattern.length) {
        
        NSScanner *scanner = [NSScanner scannerWithString:self.textStorage.string];
        scanner.caseSensitive = NO;
        
        while (!scanner.isAtEnd) {
            
            [scanner scanUpToString:pattern intoString:nil];
            
            const NSUInteger scanLoc = scanner.scanLocation;
            if ([scanner scanString:pattern intoString:nil]) {
                
                const NSRange range = { scanLoc, pattern.length };
                
                [self.textStorage addAttribute:KxTextEdViewSearchAttribute
                                         value:@YES
                                         range:range];
                
                [self.textStorage addAttribute:NSBackgroundColorAttributeName
                                         value:selColor
                                         range:range];
                
            } else {
                break;
            }
        }
    }

    [self.textStorage endEditing];
}

- (void) caretGoLeft
{
    NSRange range = self.selectedRange;
    if (range.location) {
        self.selectedRange = NSMakeRange(range.location - 1, 0);
    }
}

- (void) caretGoRight
{
    NSRange range = self.selectedRange;
    if (range.location < self.textStorage.length) {
        self.selectedRange = NSMakeRange(range.location + 1, 0);
    }
}

- (void) insertTabChar
{
    [self insertStringAtCaret:@"\t" style:nil];
}

- (void) scrollToVisibleCaretAnimated:(BOOL)animated
{
    if (animated) {
        [self scrollRangeToVisible:self.selectedRange];
    } else {
        [UIView performWithoutAnimation:^{
            [self scrollRangeToVisible:self.selectedRange];
        }];
    }
}

- (NSArray *) customMenuItems
{
    UIMenuItem *editItem = [[UIMenuItem alloc] initWithTitle:NSLocalizedString(@"Edit URL", nil)
                                                      action:@selector(actionEditLink:)];
    
    UIMenuItem *openItem = [[UIMenuItem alloc] initWithTitle:NSLocalizedString(@"Open URL", nil)
                                                      action:@selector(actionOpenLink:)];
    
    return @[editItem, openItem];
}

- (void) addCustomMenuItems
{
    NSArray *menuItems = self.customMenuItems;
    if (menuItems.count) {
        [UIMenuController sharedMenuController].menuItems = menuItems;
    }
}

#pragma mark - actions

- (void) actionEditLink:(id)sender
{
    [self askUserInsertURL];
}

- (void) actionOpenLink:(id)sender
{
    const NSUInteger textLen = self.textStorage.length;
    if (!textLen) {
        return;
    }

    const NSRange selRange = self.selectedRange;
    
    const NSUInteger caretIndex = selRange.location;
    if (caretIndex >= textLen) {
        return;
    }
    
    NSRange linkRange = {0};
    NSRange paraRange = [self.textStorage.string paragraphRangeForRange:selRange];
    if (paraRange.location == NSNotFound) {
        paraRange = (NSRange){0, textLen};
    }
    
    id val = [self.textStorage attribute:NSLinkAttributeName
                                 atIndex:caretIndex
                   longestEffectiveRange:&linkRange
                                 inRange:paraRange];
    
    if (val && linkRange.length) {
        
        NSURL *URL;
        
        if ([val isKindOfClass:[NSURL class]]) {
            URL = val;
        } else if ([val isKindOfClass:[NSString class]]) {
            URL = [NSURL URLWithString:val];
        }
        
        if (URL &&
            (![self.realDelegate respondsToSelector:@selector(textView:shouldInteractWithURL:inRange:)] ||
             [self.realDelegate textView:self shouldInteractWithURL:val inRange:linkRange]))
        {
            [[UIApplication sharedApplication] openURL:URL];
        }
    }
}

#pragma mark - private

- (UIFont *)styleFont
{
    UIFont *font = [self styleAttribute:NSFontAttributeName];
    return font ?: _defaultFont;
}

- (id) styleAttribute:(NSString *)name
{
    const NSRange range = self.selectedRange;
    if (range.length) {
        return [self attribute:name atRange:range] ?: self.typingAttributes[name];
    } else {
        return self.typingAttributes[name] ?: [self attribute:name atRange:range];
    }
}

- (id) attribute:(NSString *)name atRange:(NSRange)range
{
    NSUInteger index = range.location;
    if (index == NSNotFound) {
        return nil;
    } else if (index >= self.textStorage.length) {
        return nil;
    } else if (range.length) {
        index += range.length / 2;
    }
    return [self.textStorage attribute:name
                               atIndex:index
                 longestEffectiveRange:NULL
                               inRange:range];
}

- (void) updateAttribute:(NSString *)name value:(id)value
{
    const NSRange selRange = self.selectedRange;
    if (selRange.length) {
        
        [self updateAttribute:name value:value range:selRange];
       
    } else {
        
        [self updateTypingAttributes:^(NSMutableDictionary *md) {
            if (value) {
                md[name] = value;
            } else {
                [md removeObjectForKey:name];
            }
        }];
    }
}

- (void) updateAttribute:(NSString *)name value:(id)value range:(NSRange)range
{
    if (_allowExtUndo) {
        
        id oldVal = [self attribute:name atRange:range];
        KxTextEdView *invTarget = [self.undoManager prepareWithInvocationTarget:self];
        [invTarget updateAttribute:name value:oldVal range:range];
        [self.undoManager setActionName:@"Style"];
    }
    
    if (value) {
        [self.textStorage addAttribute:name value:value range:range];
    } else {
        [self.textStorage removeAttribute:name range:range];
    }
}

- (void) updateTypingAttributes:(void(^)(NSMutableDictionary *))block
{
    NSMutableDictionary *md = self.typingAttributes ? [self.typingAttributes mutableCopy] : [NSMutableDictionary dictionary];
    block(md);
    self.typingAttributes = md.count ? md : nil;
}

- (BOOL) enumerateParaInRange:(NSRange )range
                        block:(void(^)(NSRange paraRange))block
{
    __block BOOL hasAny = NO;
    
#if 1
    
    [self.textStorage enumerateAttribute:NSParagraphStyleAttributeName
                                 inRange:range
                                 options:0
                              usingBlock:^(id value, NSRange range, BOOL *stop)
    {
        block(range);
        hasAny = YES;
    }];

#else

    [self.textStorage.string enumerateSubstringsInRange:range
                                                options:NSStringEnumerationByParagraphs
                                             usingBlock:^(NSString *substring,
                                                          NSRange substringRange,
                                                          NSRange enclosingRange,
                                                          BOOL *stop)
     {
         block(enclosingRange);
         hasAny = YES;
     }];
    
#endif
    return hasAny;
}

- (void) updateParaAttribute:(BOOL(^)(NSMutableParagraphStyle *))block
{
    NSTextStorage *textStorage = self.textStorage;
    
    void(^func)(NSRange) = ^(NSRange paraRange) {
    
        NSParagraphStyle *para = [textStorage attribute:NSParagraphStyleAttributeName
                                                atIndex:paraRange.location
                                  longestEffectiveRange:NULL
                                                inRange:paraRange];
        
        NSMutableParagraphStyle *mPara = para ? [para mutableCopy] : [NSMutableParagraphStyle new];
        if (block(mPara)) {
            
            [textStorage addAttribute:NSParagraphStyleAttributeName
                                value:[mPara copy]
                                range:paraRange];
        }
    };
    
    [self.textStorage beginEditing];
    
    const NSRange selRange = self.selectedRange;
    if (!selRange.length ||
        ![self enumerateParaInRange:selRange block:func])
    {
        NSRange paraRange = [textStorage.string paragraphRangeForRange:selRange];
        if (paraRange.length) {
            func(paraRange);
        }
    }
    
    [self.textStorage endEditing];
}

- (NSDictionary *) defaultStyle
{
    return @{ NSFontAttributeName : _defaultFont,
              NSForegroundColorAttributeName  : _defaultTextColor,
              NSParagraphStyleAttributeName : [NSParagraphStyle new], };
}

- (NSDictionary *) styleListItem
{
    return @{ NSFontAttributeName : self.styleFont,
              NSForegroundColorAttributeName  : self.styleTextColor,
              KxTextEdViewListItemAttribute : @YES };
}

- (void) autoFormatListAtRange:(NSRange)range
{
    const NSRange lineRange = [self.textStorage.string lineRangeForRange:range];
    
    if (lineRange.length > 3 &&
        [self attribute:KxTextEdViewListItemAttribute
                atRange:NSMakeRange(lineRange.location, 0)])
    {
        NSString *line = [self.textStorage.string substringWithRange:lineRange];
        NSString *bullet = @"\u2022 ";
        NSString *string;
        
        if ([line hasPrefix:bullet]) {
            
            string = bullet;
            
        } else {
            
            NSInteger i = 0;
            NSScanner *scanner = [NSScanner scannerWithString:line];
            if ([scanner scanInteger:&i]) {
                string = [NSString stringWithFormat:@"%u. ", (unsigned)(i+1)];
            }
        }
        
        if (string) {
            
            NSDictionary *atts = self.styleListItem;
            
            NSParagraphStyle *paraStyle = [self attribute:NSParagraphStyleAttributeName atRange:lineRange];
            if (paraStyle) {
                NSMutableDictionary *md = [atts mutableCopy];
                md[NSParagraphStyleAttributeName] = paraStyle;
                atts = [md copy];
            }
            
            NSAttributedString *as = [[NSAttributedString alloc] initWithString:string attributes:atts];
            
            __weak __typeof(self) weakSelf = self;
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)),
                           dispatch_get_main_queue(), ^ {

                               __strong __typeof(weakSelf) strongSelf = weakSelf;
                               if (strongSelf) {
                                   const NSUInteger idx = NSMaxRange(range);
                                   if (idx < strongSelf.textStorage.length) {
                                       NSRange r = [strongSelf insertAttributedString:as range:NSMakeRange(idx+1, 0)];
                                       strongSelf.selectedRange = NSMakeRange(r.location, 0);
                                   }
                               }
                           });
        }
    }
}

- (void) insertStringAtCaret:(NSString *)string
                       style:(NSDictionary *)style
{
    const NSRange range = [self insertString:string range:self.selectedRange style:style];
    self.selectedRange = NSMakeRange(range.location, 0);
}

- (void) insertAttributedStringAtCaret:(NSAttributedString *)astring
{
    const NSRange range = [self insertAttributedString:astring range:self.selectedRange];    
    self.selectedRange = NSMakeRange(range.location, 0);
}

- (NSRange) insertString:(NSString *)string
                   range:(NSRange)range
                   style:(NSDictionary *)style
{
    NSAttributedString *as;
    if (string) {
        as = [[NSAttributedString alloc] initWithString:string
                                             attributes:style ?: self.defaultStyle];
    }
    return [self insertAttributedString:as range:range];
}

- (NSRange) insertAttributedString:(NSAttributedString *)astring
                             range:(NSRange)range
{
    if (_allowExtUndo) {
        
        NSAttributedString *as;
        if (range.length) {
            as = [self.textStorage attributedSubstringFromRange:range];
        }
        
        //KxTextEdView *invTarget = [self.undoManager prepareWithInvocationTarget:self];
        //[invTarget insertAttributedString:as range:NSMakeRange(range.location, astring.length)];
        
        const NSRange undoRange = NSMakeRange(range.location, astring.length);
        [self.undoManager registerUndoWithTarget:self handler:^(id target) {
            KxTextEdView *p = target;
            const NSRange r = [p insertAttributedString:as range:undoRange];
            self.selectedRange = NSMakeRange(r.location, 0);
        }];
        
        [self.undoManager setActionName:@"Insert"];
    }
    
    if (range.length) {
        [self.textStorage deleteCharactersInRange:range];
    }
    
    if (astring) {
        [self.textStorage insertAttributedString:astring atIndex:range.location];
    }
    
    NSUInteger location = range.location + astring.length;
    
    if (location == self.textStorage.length) {
        
        // fix losting of the default style at end of document
        NSAttributedString *as = [[NSAttributedString alloc] initWithString:@" " attributes:self.defaultStyle];
        [self.textStorage insertAttributedString:as atIndex:location];
        location += 1;
    }
    
    return NSMakeRange(location, 0);
}

#pragma mark - override

- (void) setFont:(UIFont *)font
{
    [super setFont:font];
    _defaultFont = font ?: [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
}

- (void) setTextColor:(UIColor *)textColor
{
    [super setTextColor:textColor];
    _defaultTextColor = textColor ?: [UIColor darkTextColor];
}

- (void) paste:(id)sender
{
    UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
    
    // NSLog(@"paste: %@", [pasteboard pasteboardTypes]);
    // TODO: public.rtf, Apple Web Archive pasteboard type, iOS rich content paste pasteboard type
    
    if ([pasteboard containsPasteboardTypes:@[@"public.url", @"public.image"]]) {
        
        NSURL *URL; UIImage *image;
        
        id value = [pasteboard valueForPasteboardType:@"public.url"];
        if (value && [value isKindOfClass:[NSURL class]]) {
            URL = value;
        }
        
        value = [pasteboard valueForPasteboardType:@"public.image"];
        if (value) {

            if ([value isKindOfClass:[UIImage class]]) {
                image = value;
            } else if ([value isKindOfClass:[NSData class]]) {
                image = [UIImage imageWithData:value];
            }
        }
        
        if (image) {
            
            [self insertImage:image fileURL:(URL.isFileURL ? URL : nil)];
            return;
            
        } else if (URL) {
            
            [self insertURL:URL title:nil];
            return;
        }
    }
    
    [super paste:sender];
}

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender
{
    if (action == @selector(paste:)) {
        
        UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
        if (![pasteboard containsPasteboardTypes:@[@"public.text", @"public.url", @"public.image"]]) {
            return NO;
        }
    }
    
    if (action == @selector(actionEditLink:) ||
        action == @selector(actionOpenLink:))
    {
        if (!self.hasText) {
            return NO;
        }
        
        id val = [self attribute:NSLinkAttributeName atRange:self.selectedRange];
        return val != nil;
    }
    
    return [super canPerformAction:action withSender:sender];
}

- (BOOL)canBecomeFirstResponder
{
    [self addCustomMenuItems];
    return [super canBecomeFirstResponder];
}

#if 0
- (void)setSelectedTextRange:(UITextRange *)selectedTextRange
{
    [super setSelectedTextRange:selectedTextRange];
    if (self.inputAccessoryView && [self.inputAccessoryView isKindOfClass:[KxTextEdInputAccessory class]]) {
        [(KxTextEdInputAccessory *)self.inputAccessoryView needUpdateState];
    }
}
#endif

#pragma mark - delegate forwarder

// the delegate forwarder code taken from http://github.com/steipete/PSPDFTextView
// The MIT License https://opensource.org/licenses/MIT
// Copyright (c) 2014 Peter Steinberger, PSPDFKit GmbH.

- (void)setDelegate:(id<UITextViewDelegate>)delegate
{
    [super setDelegate:nil];
    self.realDelegate = delegate != self ? delegate : nil;
    [super setDelegate:delegate ? self : nil];
}

- (BOOL)respondsToSelector:(SEL)sel
{
    return [super respondsToSelector:sel] || [self.realDelegate respondsToSelector:sel];
}

- (id)forwardingTargetForSelector:(SEL)sel
{
    id delegate = self.realDelegate;
    if (delegate && [delegate respondsToSelector:sel]) {
        return delegate;
    }
    return [super forwardingTargetForSelector:sel];
}

#pragma mark - UITextViewDelegate

- (void)textViewDidChangeSelection:(UITextView *)textView
{
    id<UITextViewDelegate> delegate = self.realDelegate;
    if ([delegate respondsToSelector:_cmd]) {
        [delegate textViewDidChangeSelection:textView];
    }
    
    if (self.inputAccessoryView && [self.inputAccessoryView isKindOfClass:[KxTextEdInputAccessory class]]) {
        [(KxTextEdInputAccessory *)self.inputAccessoryView needUpdateState];
    }
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    id<UITextViewDelegate> delegate = self.realDelegate;
    if ([delegate respondsToSelector:_cmd]) {
        if (![delegate textView:textView shouldChangeTextInRange:range replacementText:text]) {
           return NO;
        }
    }
    
    if (_autoFormatList && text.length == 1 && [text isEqualToString:@"\n"]) {
        [self autoFormatListAtRange:range];
    }
    
    return YES;
}

#pragma mark - UIImagePickerControllerDelegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    UIImage *image = [info valueForKey:UIImagePickerControllerOriginalImage];
    
    [_imagePicker dismissViewControllerAnimated:YES completion:nil];
    _imagePicker = nil;
    
    [self insertImage:image fileURL:nil];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [_imagePicker dismissViewControllerAnimated:YES completion:nil];
    _imagePicker = nil;
}

@end
