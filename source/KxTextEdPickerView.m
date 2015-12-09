//
//  KxTextEdPickerView.m
//  https://github.com/kolyvan/kxtexted
//
//  Created by Kolyvan on 07.12.15.
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

#import "KxTextEdPickerView.h"

@interface KxTextEdPickerView()
@end

@implementation KxTextEdPickerView {
    id _oldSelected;
}

+ (instancetype) presentPickerFromController:(UIViewController *)fromVc
                                  sourceView:(UIView *)source
                                       width:(CGFloat)width
                                       title:(NSString *)title
                                       items:(NSArray *)items
                                    selected:(id)selected
                                       block:(void(^)(id item))block
{
    if (!fromVc) {
        fromVc = [UIApplication sharedApplication].keyWindow.rootViewController;
    }
    if (fromVc.presentedViewController) {
        fromVc = fromVc.presentedViewController;
    }

    // compute view frame
    const CGFloat hCont = 200.;
    const CGFloat wCont = width;
    
    CGPoint origin = [fromVc.view convertPoint:source.bounds.origin fromView:source];
    origin.y -= (hCont + 5.);
    CGRect frame = { origin, wCont, hCont };

    if (frame.origin.y < 0) {
        frame.origin.y = 0;
    }
    if (CGRectGetMaxX(frame) > fromVc.view.bounds.size.width) {
        frame.origin.x = fromVc.view.bounds.size.width - frame.size.width - 5.;
    }
    
    //
    KxTextEdPickerView *picker;
    picker = [[KxTextEdPickerView alloc] initWithFrame:frame title:title];
    
    picker.items = items;
    picker.selectBlock = block;
    picker.selected = selected;
    
    picker.dimmer = ({
        
        UIView *v = [[UIView alloc] initWithFrame:fromVc.view.bounds];
        v.backgroundColor = [UIColor blackColor];
        v.alpha = 0.2;
        v;
    });
    
    [fromVc.view addSubview:picker.dimmer];
    [fromVc.view addSubview:picker];
    
    return picker;
}

- (instancetype) initWithFrame:(CGRect)frame
                         title:(NSString *)title
{
    if ((self = [super initWithFrame:frame])) {
        
        const CGFloat W = self.bounds.size.width;
        const CGFloat H = self.bounds.size.height;
        const CGFloat hTitle = 30.;
        const CGFloat hPicker = H - hTitle;
        
        self.backgroundColor = [UIColor whiteColor];
#if 0
        self.layer.shadowColor = [UIColor blackColor].CGColor;
        self.layer.shadowOpacity = 0.5;
        self.layer.shadowRadius = 2.;
        self.layer.shadowOffset = (CGSize){1.,1.};
#endif
        self.layer.cornerRadius = 8.;
        
        _titleLabel = ({
            UILabel *v = [[UILabel alloc] initWithFrame:(CGRect){0, 20., W, hTitle - 40.}];
            v.font = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption1];
            v.textAlignment = NSTextAlignmentCenter;
            v.text = title;
            v.textColor = [UIColor grayColor];
            v;
        });
        [self addSubview:_titleLabel];
        
        _closeButton = ({
            UIButton *v = [UIButton buttonWithType:UIButtonTypeCustom];
            v.frame = (CGRect){0, 0, W, hTitle};
            v.autoresizingMask = UIViewAutoresizingFlexibleWidth;
            v.contentEdgeInsets = UIEdgeInsetsMake(0, 6, 9, 0);
            v.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
            [v setTitle:@"\u2304" forState:UIControlStateNormal];
            [v setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
            [v addTarget:self
                  action:@selector(actionClose:)
        forControlEvents:UIControlEventTouchUpInside];
            v;
        });
        [self addSubview:_closeButton];
        
        _pickerView = ({;
            UIPickerView *v = [[UIPickerView alloc] initWithFrame:(CGRect){0, hTitle, W, hPicker}];
            v.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
            v.delegate = self;
            v.dataSource = self;
            v;
        });
        
        [self addSubview:_pickerView];
    }
    
    return self;
}

- (void) dealloc
{
    _pickerView.delegate = nil;
    _pickerView.dataSource = nil;
    
    if (_dimmer) {
        [_dimmer removeFromSuperview];
        _dimmer = nil;
    }
}

- (void) setSelected:(id)selected
{
    if (![_selected isEqual: selected]) {
        
        _selected = _oldSelected = selected;
        
        if (_selected && _items.count) {
            
            NSUInteger index = [_items indexOfObject:_selected];
            if (index == NSNotFound) {
                index = _items.count / 2;
            }
            [_pickerView selectRow:index inComponent:0 animated:NO];
        }
    }
}

- (void) setDimmer:(UIView *)dimmer
{
    if (_dimmer) {
        [_dimmer removeFromSuperview];
    }
    
    _dimmer = dimmer;
    
    if (_dimmer) {
        
        UIGestureRecognizer *gr = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissPicker)];
        [_dimmer addGestureRecognizer:gr];
    }
}

- (void) actionClose:(id)sender
{
    [self dismissPicker];
}

- (void) dismissPicker
{
    if (_selectBlock) {
        if (![_oldSelected isEqual:_selected]) {
            _selectBlock(_selected);
        }
    }
    
    if (_dimmer) {
        [_dimmer removeFromSuperview];
        _dimmer = nil;
    }
    [self removeFromSuperview];
}

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    return _items.count;
}

- (NSAttributedString *)pickerView:(UIPickerView *)pickerView attributedTitleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    id item = _items[row];
    UIColor *color = _foreColor ?: [UIColor darkTextColor];
    return [[NSAttributedString alloc] initWithString:[item description]
                                           attributes:@{NSForegroundColorAttributeName:color}];
    
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    _selected = _items[row];
}

@end
