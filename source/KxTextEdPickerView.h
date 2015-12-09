//
//  KxTextEdPickerView.h
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

#import <UIKit/UIKit.h>


@interface KxTextEdPickerView : UIView<UIPickerViewDataSource, UIPickerViewDelegate>
@property (readonly, nonatomic, strong) UIPickerView *pickerView;
@property (readonly, nonatomic, strong) UILabel *titleLabel;
@property (readonly, nonatomic, strong) UIButton *closeButton;
@property (readwrite, nonatomic, strong) UIView *dimmer;
@property (readwrite, nonatomic, strong) NSArray *items;
@property (readwrite, nonatomic, strong) UIColor *foreColor;
@property (readwrite, nonatomic, strong) id selected;
@property (readwrite, nonatomic, copy) void(^selectBlock)(id item);

+ (instancetype) presentPickerFromController:(UIViewController *)fromVc
                                  sourceView:(UIView *)source
                                       width:(CGFloat)width
                                       title:(NSString *)title
                                       items:(NSArray *)items
                                    selected:(id)selected
                                       block:(void(^)(id item))block;

- (instancetype) initWithFrame:(CGRect)frame
                         title:(NSString *)title;

- (void) dismissPicker;

@end
