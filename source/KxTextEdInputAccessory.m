//
//  KxTextEdInputAccessory.m
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

#import "KxTextEdInputAccessory.h"
#import "KxTextEdView.h"
#import "UIFont+KxTextEd.h"
#import "KxTextEdPickerView.h"
#import "KxTextEdColorPickerView.h"

@import CoreText;

enum {

    KxTextEdButtonBold,
    KxTextEdButtonItalic,
    KxTextEdButtonUnderline,
    KxTextEdButtonStrikethrough,
    KxTextEdButtonFontName,
    KxTextEdButtonFontSize,
    KxTextEdButtonColorText,
    KxTextEdButtonColorBackg,
    KxTextEdButtonParaAlignLeft,
    KxTextEdButtonParaAlignCenter,
    KxTextEdButtonParaAlignRight,
    KxTextEdButtonParaAlignJust,
    KxTextEdButtonParaIndentInc,
    KxTextEdButtonParaIndentDec,
    KxTextEdButtonSuperscript,
    KxTextEdButtonSubscript,
    KxTextEdButtonClear,
    KxTextEdButtonSep1,
    KxTextEdButtonListBullets,
    KxTextEdButtonListNumbers,
    KxTextEdButtonAddLink,
    KxTextEdButtonAddImage,
    KxTextEdButtonSelectPara,
    KxTextEdButtonSep2,
    KxTextEdButtonUndo,
    KxTextEdButtonRedo,
    KxTextEdButtonArrowLeft,
    KxTextEdButtonArrowRight,
    KxTextEdButtonArrowTab,
    KxTextEdButtonCount,
};

@interface KxTextEdInputAccessoryCell : UICollectionViewCell
@property (readonly, nonatomic, strong) UILabel *label;
@end

//////////

@implementation KxTextEdInputAccessory {
    __weak id   _pickerView;
    NSArray     *_colorPickerPallete;
    NSArray     *_fontNamePickerItems;
    NSArray     *_fontSizePickerItems;
}

- (instancetype) initWithFrame:(CGRect)frame
{
    if ((self = [super initWithFrame:frame])) {
        
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
            //self.backgroundColor = [UIColor colorWithRed:220./255. green:223./255. blue:226./255. alpha:1.];
            self.backgroundColor = [UIColor colorWithRed:217./255. green:220./255. blue:223./255. alpha:1.0];
        } else {
            //self.backgroundColor = [UIColor colorWithRed:204./255. green:208./255. blue:214./255. alpha:1.];
            self.backgroundColor = [UIColor colorWithRed:207./255. green:210./255. blue:213./255. alpha:1.];
        }
        
        self.opaque = YES;
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
        
        const CGFloat W = self.bounds.size.width;
        const CGFloat H = self.bounds.size.height - 2.;
        const CGFloat xMargin = 2.;
        
        UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
        flowLayout.minimumLineSpacing = xMargin;
        flowLayout.minimumInteritemSpacing = xMargin;
        flowLayout.sectionInset = UIEdgeInsetsMake(0, xMargin, 0, xMargin);
        flowLayout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
        
        _collView = [[UICollectionView alloc] initWithFrame:(CGRect){0, 1, W, H}
                                       collectionViewLayout:flowLayout];
        
        _collView.delegate = self;
        _collView.dataSource = self;
        _collView.showsHorizontalScrollIndicator = NO;
        _collView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
        _collView.backgroundColor = self.backgroundColor;
        
        [_collView registerClass:[KxTextEdInputAccessoryCell class]
      forCellWithReuseIdentifier:@"Cell"];
        
        [self addSubview:_collView];
        
        _font = [UIFont systemFontOfSize:[UIFont labelFontSize]];
        _foreColor = [UIColor darkTextColor];
        _selectedColor = self.tintColor ?: [UIColor colorWithRed:0. green:0.478 blue:1. alpha:1.];
    }
    
    return self;
}

- (void) layoutSubviews
{
    [super layoutSubviews];
    
    const CGFloat H = self.bounds.size.height - 2.;
    UICollectionViewFlowLayout *flowLayout = (UICollectionViewFlowLayout *)_collView.collectionViewLayout;
    if (flowLayout.itemSize.height != H) {
        [flowLayout invalidateLayout];
    }
}

- (void) needUpdateState
{
    if (_pickerView) {
        [_pickerView dismissPicker];
        _pickerView = nil;
    }
    
    // schedule update
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(updateState) object:nil];
    [self performSelector:@selector(updateState) withObject:nil afterDelay:0.1];
}

- (void) updateState
{
    NSArray *indexPaths = [_collView indexPathsForVisibleItems];
    //[_collView reloadItemsAtIndexPaths:indexPaths];
    
    for (NSIndexPath *indexPath in indexPaths) {
        KxTextEdInputAccessoryCell *cell;
        cell = (KxTextEdInputAccessoryCell *)[_collView cellForItemAtIndexPath:indexPath];
        if (cell) {
            [self updateCell:cell indexPath:indexPath];
        }
    }
}

- (void) updateCell:(KxTextEdInputAccessoryCell *)cell
          indexPath:(NSIndexPath *)indexPath
{
    switch (indexPath.row) {
            
        case KxTextEdButtonBold: {
            
            UIColor *color = _textView.styleFontBold ? _selectedColor : _foreColor;
            NSDictionary *atts = @{ NSFontAttributeName : [self.class toolbarFont],
                                    NSForegroundColorAttributeName : color};
            cell.label.attributedText = [[NSAttributedString alloc] initWithString:@"\ue800" attributes:atts];
            break;
        }
            
        case KxTextEdButtonItalic: {
            
            UIColor *color = _textView.styleFontItalic ? _selectedColor : _foreColor;
            NSDictionary *atts = @{ NSFontAttributeName : [self.class toolbarFont],
                                    NSForegroundColorAttributeName : color};
            cell.label.attributedText = [[NSAttributedString alloc] initWithString:@"\ue801" attributes:atts];
            break;
        }
            
        case KxTextEdButtonUnderline: {
            
            UIColor *color = _textView.styleDecorUnderline ? _selectedColor : _foreColor;
            NSDictionary *atts = @{ NSFontAttributeName : [self.class toolbarFont],
                                    NSForegroundColorAttributeName : color};
            cell.label.attributedText = [[NSAttributedString alloc] initWithString:@"\ue802" attributes:atts];
            break;
        }
            
        case KxTextEdButtonStrikethrough: {
            
            UIColor *color = _textView.styleDecorStrikethrough ? _selectedColor : _foreColor;
            NSDictionary *atts = @{ NSFontAttributeName : [self.class toolbarFont],
                                    NSForegroundColorAttributeName : color};
            cell.label.attributedText = [[NSAttributedString alloc] initWithString:@"\ue803" attributes:atts];
            break;
        }
            
        case KxTextEdButtonFontName: {

            NSDictionary *atts = @{ NSFontAttributeName : _font,
                                    NSForegroundColorAttributeName : _foreColor,};
            cell.label.attributedText = [[NSAttributedString alloc] initWithString:_textView.styleFontName
                                                                        attributes:atts];
            break;
        }
            
        case KxTextEdButtonFontSize: {
            
            NSDictionary *atts = @{ NSFontAttributeName : _font,
                                    NSForegroundColorAttributeName : _foreColor,};
            NSString *title = [NSString stringWithFormat:@"%upt", (unsigned)_textView.styleFontSize];
            cell.label.attributedText = [[NSAttributedString alloc] initWithString:title
                                                                        attributes:atts];
            break;
        }
            
        case KxTextEdButtonColorText: {
            
            NSDictionary *atts = @{ NSFontAttributeName : [self.class toolbarFont],
                                    NSForegroundColorAttributeName : _textView.styleTextColor,};
            cell.label.attributedText = [[NSAttributedString alloc] initWithString:@"\ue804" attributes:atts];
            break;
        }
            
        case KxTextEdButtonColorBackg: {
            
            NSDictionary *atts = @{ NSFontAttributeName : [self.class toolbarFont],
                                    NSForegroundColorAttributeName : _textView.styleBackgColor,};
            cell.label.attributedText = [[NSAttributedString alloc] initWithString:@"\ue805" attributes:atts];
            break;
        }
            
        case KxTextEdButtonParaAlignLeft: {
            
            UIColor *color = _textView.styleParaAlignment == NSTextAlignmentLeft ? _selectedColor : _foreColor;
            NSDictionary *atts = @{ NSFontAttributeName : [self.class toolbarFont],
                                    NSForegroundColorAttributeName : color,};
            cell.label.attributedText = [[NSAttributedString alloc] initWithString:@"\ue806" attributes:atts];
            break;
        }
            
        case KxTextEdButtonParaAlignCenter: {
            
            UIColor *color = _textView.styleParaAlignment == NSTextAlignmentCenter ? _selectedColor : _foreColor;
            NSDictionary *atts = @{ NSFontAttributeName : [self.class toolbarFont],
                                    NSForegroundColorAttributeName : color,};
            cell.label.attributedText = [[NSAttributedString alloc] initWithString:@"\ue807" attributes:atts];
            break;
        }
            
        case KxTextEdButtonParaAlignRight: {
            
            UIColor *color = _textView.styleParaAlignment == NSTextAlignmentRight ? _selectedColor : _foreColor;
            NSDictionary *atts = @{ NSFontAttributeName : [self.class toolbarFont],
                                    NSForegroundColorAttributeName : color,};
            cell.label.attributedText = [[NSAttributedString alloc] initWithString:@"\ue808" attributes:atts];
            break;
        }
            
        case KxTextEdButtonParaAlignJust: {
            
            UIColor *color = _textView.styleParaAlignment == NSTextAlignmentJustified ? _selectedColor : _foreColor;
            NSDictionary *atts = @{ NSFontAttributeName : [self.class toolbarFont],
                                    NSForegroundColorAttributeName : color,};
            cell.label.attributedText = [[NSAttributedString alloc] initWithString:@"\ue809" attributes:atts];
            break;
        }
            
        case KxTextEdButtonParaIndentInc: {
            
            NSDictionary *atts = @{ NSFontAttributeName : [self.class toolbarFont],
                                    NSForegroundColorAttributeName : _foreColor,};
            cell.label.attributedText = [[NSAttributedString alloc] initWithString:@"\ue80A" attributes:atts];
            break;
        }

        case KxTextEdButtonParaIndentDec: {
            
            NSDictionary *atts = @{ NSFontAttributeName : [self.class toolbarFont],
                                    NSForegroundColorAttributeName : _foreColor,};
            cell.label.attributedText = [[NSAttributedString alloc] initWithString:@"\ue80B" attributes:atts];
            break;
        }
            
        case KxTextEdButtonSuperscript: {
            
            UIColor *color = _textView.styleVertAlignSuper ? _selectedColor : _foreColor;
            NSDictionary *atts = @{ NSFontAttributeName : [self.class toolbarFont],
                                    NSForegroundColorAttributeName : color,};
            cell.label.attributedText = [[NSAttributedString alloc] initWithString:@"\ue811" attributes:atts];
            break;
        }
            
        case KxTextEdButtonSubscript: {
            
            UIColor *color = _textView.styleVertAlignSub ? _selectedColor : _foreColor;
            NSDictionary *atts = @{ NSFontAttributeName : [self.class toolbarFont],
                                    NSForegroundColorAttributeName : color,};
            cell.label.attributedText = [[NSAttributedString alloc] initWithString:@"\ue812" attributes:atts];
            break;
        }
            
        case KxTextEdButtonClear: {
            
            NSDictionary *atts = @{ NSFontAttributeName : [self.class toolbarFont],
                                    NSForegroundColorAttributeName : _foreColor,};
            cell.label.attributedText = [[NSAttributedString alloc] initWithString:@"\ue80C" attributes:atts];
            break;
        }
            
        case KxTextEdButtonListBullets: {
            
            NSDictionary *atts = @{ NSFontAttributeName : [self.class toolbarFont],
                                    NSForegroundColorAttributeName : _foreColor,};
            cell.label.attributedText = [[NSAttributedString alloc] initWithString:@"\ue80f" attributes:atts];
            break;
        }
            
        case KxTextEdButtonListNumbers: {
            
            NSDictionary *atts = @{ NSFontAttributeName : [self.class toolbarFont],
                                    NSForegroundColorAttributeName : _foreColor,};
            cell.label.attributedText = [[NSAttributedString alloc] initWithString:@"\ue810" attributes:atts];
            break;
        }
            
        case KxTextEdButtonAddLink: {
            
            NSDictionary *atts = @{ NSFontAttributeName : [self.class toolbarFont],
                                    NSForegroundColorAttributeName : _foreColor,};
            cell.label.attributedText = [[NSAttributedString alloc] initWithString:@"\ue80d" attributes:atts];
            break;
        }
            
        case KxTextEdButtonAddImage: {
            
            NSDictionary *atts = @{ NSFontAttributeName : [self.class toolbarFont],
                                    NSForegroundColorAttributeName : _foreColor,};
            cell.label.attributedText = [[NSAttributedString alloc] initWithString:@"\ue80e" attributes:atts];
            break;
        }
            
        case KxTextEdButtonSelectPara: {
            
            NSDictionary *atts = @{ NSFontAttributeName : _font,
                                    NSForegroundColorAttributeName : _foreColor,};
            cell.label.attributedText = [[NSAttributedString alloc] initWithString:@"*\u00B6" attributes:atts];
            break;
        }
         
        case KxTextEdButtonSep1: case KxTextEdButtonSep2:
            cell.label.attributedText = nil;
            break;
            
        case KxTextEdButtonUndo: {
            
            UIColor *color = _textView.undoManager.canUndo ? _foreColor : [UIColor grayColor];
            NSDictionary *atts = @{ NSFontAttributeName : [self.class toolbarFont],
                                    NSForegroundColorAttributeName : color};
            cell.label.attributedText = [[NSAttributedString alloc] initWithString:@"\ue813" attributes:atts];
            break;
        }
            
        case KxTextEdButtonRedo: {
            
            UIColor *color = _textView.undoManager.canRedo ? _foreColor : [UIColor grayColor];
            NSDictionary *atts = @{ NSFontAttributeName : [self.class toolbarFont],
                                    NSForegroundColorAttributeName : color};
            cell.label.attributedText = [[NSAttributedString alloc] initWithString:@"\ue814" attributes:atts];
            break;
        }
            
        case KxTextEdButtonArrowLeft: {
            
            NSDictionary *atts = @{ NSFontAttributeName : [self.class toolbarFont],
                                    NSForegroundColorAttributeName : _foreColor};
            cell.label.attributedText = [[NSAttributedString alloc] initWithString:@"\ue815" attributes:atts];
            break;
        }
            
        case KxTextEdButtonArrowRight: {
            
            NSDictionary *atts = @{ NSFontAttributeName : [self.class toolbarFont],
                                    NSForegroundColorAttributeName : _foreColor};
            cell.label.attributedText = [[NSAttributedString alloc] initWithString:@"\ue816" attributes:atts];
            break;
        }
            
        case KxTextEdButtonArrowTab: {

            NSDictionary *atts = @{ NSFontAttributeName : [self.class toolbarFont],
                                    NSForegroundColorAttributeName : _foreColor};
            cell.label.attributedText = [[NSAttributedString alloc] initWithString:@"\ue817" attributes:atts];
            break;
        }

        default:
            break;
    }
}

+ (UIFont *) toolbarFont
{
    static UIFont *font;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
                
        NSBundle *bundle = [NSBundle bundleForClass:[self class]];
        NSString *path = [bundle pathForResource:@"kxtexted-toolbar" ofType:@"ttf"];
        
        NSError *error;
        NSData *data = [NSData dataWithContentsOfFile:path
                                              options:NSDataReadingMappedIfSafe
                                                error:&error];
        
        if (data) {
            
            CGDataProviderRef fontProvider = CGDataProviderCreateWithCFData((__bridge CFDataRef)data);
            CGFontRef cgFont = CGFontCreateWithDataProvider(fontProvider);
            CGDataProviderRelease(fontProvider);
            
            if (cgFont) {
            
                if (CTFontManagerRegisterGraphicsFont(cgFont, NULL)) {
                    
                    CFStringRef fontName = CGFontCopyFullName(cgFont);
                    if (fontName) {
                        font = [UIFont fontWithName:(__bridge NSString *)(fontName) size:20.];
                        CFRelease(fontName);
                    }
                }
                
                CGFontRelease(cgFont);
            }
        }
        
#if DEBUG
        if (!font) {
            NSLog(@"warning, failed to load kxtexted-toolbar.ttf font!");
        }
#endif
    });
    
    return font;
}

#pragma mark - properties

- (NSArray *) colorPickerPallete
{
    if (!_colorPickerPallete) {
        _colorPickerPallete = [KxTextEdColorPickerView defaultPalette];
    }
    return _colorPickerPallete;
}

- (NSArray *) fontNamePickerItems
{
    if (!_fontNamePickerItems) {
         _fontNamePickerItems = [[UIFont familyNames] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
    }
    return _fontNamePickerItems;
}

- (NSArray *) fontSizePickerItems
{
    if (!_fontSizePickerItems) {
        NSMutableArray *items = [NSMutableArray array];
        for (NSUInteger i = 12; i < 31; i += 1) {
            [items addObject:@((CGFloat)i)];
        }
        _fontSizePickerItems = [items copy];
    }
    return _fontSizePickerItems;
}

#pragma mark - UICollectionView

- (NSInteger)numberOfSectionsInCollectionView: (UICollectionView *)collectionView
{
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return KxTextEdButtonCount;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView
                  cellForItemAtIndexPath:(NSIndexPath *)indexPath;
{
    
    KxTextEdInputAccessoryCell *cell;
    cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"Cell"
                                                     forIndexPath:indexPath];

    [self updateCell:cell indexPath:indexPath];
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    [collectionView deselectItemAtIndexPath:indexPath animated:NO];
    
    if (_pickerView) {
        [_pickerView dismissPicker];
        _pickerView = nil;
    }
    
    switch (indexPath.row) {
            
        case KxTextEdButtonBold:
            _textView.styleFontBold = !_textView.styleFontBold;
            [self reloadItem:indexPath];
            break;
            
        case KxTextEdButtonItalic:
            _textView.styleFontItalic = !_textView.styleFontItalic;
            [self reloadItem:indexPath];
            break;
            
        case KxTextEdButtonUnderline:
            _textView.styleDecorUnderline = !_textView.styleDecorUnderline;
            [self reloadItem:indexPath];
            break;
            
        case KxTextEdButtonStrikethrough:
            _textView.styleDecorStrikethrough = !_textView.styleDecorStrikethrough;
            [self reloadItem:indexPath];
            break;
            
        case KxTextEdButtonFontName: {
            
            UICollectionViewCell *cell = [collectionView cellForItemAtIndexPath:indexPath];
            KxTextEdView *textView = _textView;
            
            _pickerView = [KxTextEdPickerView presentPickerFromController:nil
                                                               sourceView:cell
                                                                    width:180.
                                                                    title:NSLocalizedString(@"Font", nil)
                                                                    items:self.fontNamePickerItems
                                                                 selected:textView.styleFontName
                                                                    block:^(id item)
                           {
                               textView.styleFontName = item;
                               [collectionView reloadItemsAtIndexPaths:@[indexPath]];
                           }];
                        
            break;
        }
            
        case KxTextEdButtonFontSize: {
            
            UICollectionViewCell *cell = [collectionView cellForItemAtIndexPath:indexPath];
            KxTextEdView *textView = _textView;
            
            _pickerView = [KxTextEdPickerView presentPickerFromController:nil
                                                               sourceView:cell
                                                                    width:100.
                                                                    title:NSLocalizedString(@"Size", nil)
                                                                    items:self.fontSizePickerItems
                                                                 selected:@(textView.styleFontSize)
                                                                    block:^(id item)
                           {
                               textView.styleFontSize = [item floatValue];
                               [collectionView reloadItemsAtIndexPaths:@[indexPath]];
                           }];
            
            break;
        }
            
        case KxTextEdButtonColorText: {
            
            UICollectionViewCell *cell = [collectionView cellForItemAtIndexPath:indexPath];
            __weak __typeof(self) weakSelf = self;
            
            _pickerView = [KxTextEdColorPickerView presentPickerFromController:nil
                                                                    sourceView:cell
                                                                       palette:self.colorPickerPallete
                                                                      selected:_textView.styleTextColor
                                                                         block:^(UIColor *color)
                           {
                               weakSelf.textView.styleTextColor = color;
                               [weakSelf reloadItem:indexPath];
                           }];
            
            break;
        }
            
        case KxTextEdButtonColorBackg: {
            
            UICollectionViewCell *cell = [collectionView cellForItemAtIndexPath:indexPath];
            __weak __typeof(self) weakSelf = self;
            
            _pickerView = [KxTextEdColorPickerView presentPickerFromController:nil
                                                                    sourceView:cell
                                                                      selected:_textView.styleBackgColor
                                                                         block:^(UIColor *color)
                           {
                               weakSelf.textView.styleBackgColor = color;
                               [weakSelf reloadItem:indexPath];
                           }];
            
            break;
        }
            
        case KxTextEdButtonParaIndentInc:
            [_textView increaseStyleParaIndent];
            [collectionView reloadItemsAtIndexPaths:@[indexPath]];
            break;
            
        case KxTextEdButtonParaIndentDec:
            [_textView decreaseStyleParaIndent];
            [collectionView reloadItemsAtIndexPaths:@[indexPath]];
            break;
            
        case KxTextEdButtonParaAlignLeft:
            [self setTextViewStyleParaAlignment:NSTextAlignmentLeft];
            break;
            
        case KxTextEdButtonParaAlignCenter:
            [self setTextViewStyleParaAlignment:NSTextAlignmentCenter];
            break;
            
        case KxTextEdButtonParaAlignRight:
            [self setTextViewStyleParaAlignment:NSTextAlignmentRight];
            break;
            
        case KxTextEdButtonParaAlignJust:
            [self setTextViewStyleParaAlignment:NSTextAlignmentJustified];
            break;
            
        case KxTextEdButtonSuperscript:
            _textView.styleVertAlignSuper = !_textView.styleVertAlignSuper;
            [self reloadItem:indexPath];
            break;
            
        case KxTextEdButtonSubscript:
            _textView.styleVertAlignSub = !_textView.styleVertAlignSub;
            [self reloadItem:indexPath];
            break;
            
        case KxTextEdButtonClear:
            [_textView clearStyles];
            [collectionView reloadSections:[NSIndexSet indexSetWithIndex:0]];
            break;
            
        case KxTextEdButtonListBullets:
            [_textView formatListOrdered:NO];
            [self reloadItem:nil];
            break;
            
        case KxTextEdButtonListNumbers:
            [_textView formatListOrdered:YES];
            [self reloadItem:nil];
            break;
            
        case KxTextEdButtonAddLink:
            [_textView askUserInsertURL];
            break;
            
        case KxTextEdButtonAddImage:
            [_textView askUserInsertImage];
            break;
            
        case KxTextEdButtonSelectPara:
            [_textView selectParagraph];
            break;
            
        case KxTextEdButtonUndo:
            [_textView.undoManager undo];
            [collectionView reloadSections:[NSIndexSet indexSetWithIndex:0]];
            break;
            
        case KxTextEdButtonRedo:
            [_textView.undoManager redo];
            [collectionView reloadSections:[NSIndexSet indexSetWithIndex:0]];
            break;
            
        case KxTextEdButtonArrowLeft:
            [_textView caretGoLeft];
            break;
            
        case KxTextEdButtonArrowRight:
            [_textView caretGoRight];
            break;
            
        case KxTextEdButtonArrowTab:
            [_textView insertTabChar];
            [self reloadItem:nil];
            break;
            
        default:
            break;
    }
}

- (CGSize)collectionView:(UICollectionView *)collectionView
                  layout:(UICollectionViewFlowLayout*)layout
  sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    const CGFloat H = collectionView.bounds.size.height - layout.sectionInset.top  - layout.sectionInset.bottom;
    
    CGFloat W;
    if (indexPath.row == KxTextEdButtonFontName) {
        W = 100.;
    } else if (indexPath.row == KxTextEdButtonSep1 ||
               indexPath.row == KxTextEdButtonSep2) {
        W = 10.;
    } else {
        W = 40.;
    };
    return (CGSize){W, H};
}

- (void) setTextViewStyleParaAlignment:(NSTextAlignment)align
{
    _textView.styleParaAlignment = align;
    
    [_collView reloadItemsAtIndexPaths:@[[NSIndexPath indexPathForItem:KxTextEdButtonParaAlignLeft inSection:0],
                                         [NSIndexPath indexPathForItem:KxTextEdButtonParaAlignCenter inSection:0],
                                         [NSIndexPath indexPathForItem:KxTextEdButtonParaAlignRight inSection:0],
                                         [NSIndexPath indexPathForItem:KxTextEdButtonParaAlignJust inSection:0]]];
}

- (void) reloadItem:(NSIndexPath *)indexPath
{
    if (indexPath) {
        
        [_collView reloadItemsAtIndexPaths:@[indexPath,
                                             [NSIndexPath indexPathForItem:KxTextEdButtonUndo inSection:0],
                                             [NSIndexPath indexPathForItem:KxTextEdButtonRedo inSection:0]]];
    } else {
        
        [_collView reloadItemsAtIndexPaths:@[[NSIndexPath indexPathForItem:KxTextEdButtonUndo inSection:0],
                                             [NSIndexPath indexPathForItem:KxTextEdButtonRedo inSection:0]]];
    }
}

@end

//////////

@implementation KxTextEdInputAccessoryCell

- (instancetype) initWithFrame:(CGRect)rect
{
    if ((self = [super initWithFrame: rect])) {
        
        self.backgroundColor = [UIColor clearColor];
        self.selectedBackgroundView = [[UIView alloc] initWithFrame:rect];
        self.selectedBackgroundView.backgroundColor = [UIColor grayColor];
        self.selectedBackgroundView.opaque = YES;
        
        _label = ({
            UILabel *v = [[UILabel alloc] initWithFrame:self.bounds];
            v.opaque = NO;
            v.backgroundColor = [UIColor clearColor];
            v.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
            v.textAlignment = NSTextAlignmentCenter;
            v.lineBreakMode = NSLineBreakByClipping;
            v;
        });
        [self addSubview:_label];        
    }
    return self;
}

@end
