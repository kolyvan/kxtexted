//
//  KxTextEdColorPickerView.m
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

#import "KxTextEdColorPickerView.h"

@implementation KxTextEdColorPickerView {
    UIColor *_oldSelected;
}

+ (instancetype) presentPickerFromController:(UIViewController *)fromVc
                                  sourceView:(UIView *)source
                                    selected:(UIColor *)selected
                                       block:(void(^)(UIColor *))block
{
    return [self presentPickerFromController:fromVc
                                  sourceView:source
                                     palette:[self defaultPalette]
                                    selected:selected
                                       block:block];
}

+ (instancetype) presentPickerFromController:(UIViewController *)fromVc
                                  sourceView:(UIView *)source
                                     palette:(NSArray *)palette
                                    selected:(UIColor *)selected
                                       block:(void(^)(UIColor *))block
{
    if (!fromVc) {
        fromVc = [UIApplication sharedApplication].keyWindow.rootViewController;
    }
    if (fromVc.presentedViewController) {
        fromVc = fromVc.presentedViewController;
    }
    
    // compute view frame
    const BOOL isTall = fromVc.traitCollection.verticalSizeClass == UIUserInterfaceSizeClassRegular;
    const CGFloat hCont = isTall ? 250 : 162;
    const CGFloat wCont = 176.; // 44*4
    
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
    KxTextEdColorPickerView *picker;
    picker = [[KxTextEdColorPickerView alloc] initWithFrame:frame];
    
    picker.palette = palette;
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
{
    if ((self = [super initWithFrame:frame])) {
        
        const CGFloat W = self.bounds.size.width;
        const CGFloat H = self.bounds.size.height;
        const CGFloat hTitle = 25.;
        const CGFloat hColl = H - hTitle - 5.;
        
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
            v.text = NSLocalizedString(@"Color", nil);
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
        
        _collectionView = ({
            
            UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
            flowLayout.minimumLineSpacing = 0.;
            flowLayout.minimumInteritemSpacing = 0.;
            flowLayout.sectionInset = UIEdgeInsetsMake(0., 0., 0., 0.);
            flowLayout.scrollDirection = UICollectionViewScrollDirectionVertical;
            flowLayout.itemSize = (CGSize){44.,44.};
            
            UICollectionView *v = [[UICollectionView alloc] initWithFrame:(CGRect){0, hTitle, W, hColl}
                                                     collectionViewLayout:flowLayout];
            v.delegate = self;
            v.dataSource = self;
            v.autoresizingMask = UIViewAutoresizingNone;
            v.backgroundColor = [UIColor whiteColor];
            
            [v registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:@"Cell"];
            
            v;
        });
        
        [self addSubview:_collectionView];
    }
    
    return self;
}

- (void) dealloc
{
    _collectionView.delegate = nil;
    _collectionView.dataSource = nil;
    
    if (_dimmer) {
        [_dimmer removeFromSuperview];
        _dimmer = nil;
    }
}

- (void) setSelected:(id)selected
{
    if (![_selected isEqual: selected]) {
        
        _selected = _oldSelected = selected;
        
        if (_selected && _palette.count) {
            
            NSUInteger index = [_palette indexOfObject:_selected];
            if (index == NSNotFound) {
                index = _palette.count / 2;
            }
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
            [_collectionView selectItemAtIndexPath:indexPath
                                          animated:NO
                                    scrollPosition:UICollectionViewScrollPositionCenteredVertically];
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

- (NSInteger)numberOfSectionsInCollectionView: (UICollectionView *)collectionView
{
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return _palette.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView
                  cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    UIColor *color = _palette[indexPath.row];
    
    UICollectionViewCell *cell;
    cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"Cell"
                                                     forIndexPath:indexPath];
    
    cell.contentView.backgroundColor = color;
    
    return cell;
}

- (void) collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    _selected = _palette[indexPath.row];
    [self dismissPicker];
}


#pragma mark - class methods

+ (NSArray *) defaultPalette
{
    static NSArray *palette;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        palette = @[
                    
                    [UIColor whiteColor],
                    [UIColor colorWithWhite:0.92 alpha:1.],
                    
                    [UIColor colorWithRed:0.741 green:0.745 blue:0.761 alpha:1.], // light gray
                    [UIColor lightGrayColor],
                    
                    [UIColor colorWithRed:0.557 green:0.557 blue:0.576 alpha:1.], // grey
                    [UIColor darkGrayColor],
                    
                    [UIColor colorWithRed:0.122 green:0.122 blue:0.129 alpha:1.], // black
                    [UIColor darkTextColor],
                    
                    [UIColor redColor],
                    [UIColor colorWithRed:1.000 green:0.227 blue:0.176 alpha:1.], // deep red
                    
                    [UIColor orangeColor],
                    [UIColor colorWithRed:1.000 green:0.584 blue:0.000 alpha:1.], // orange
                    
                    [UIColor colorWithRed:1.000 green:0.286 blue:0.506 alpha:1.], // pink
                    [UIColor colorWithRed:1.000 green:0.176 blue:0.333 alpha:1.], // hotPinkColor
                    
                    [UIColor yellowColor],
                    [UIColor colorWithRed:1.000 green:0.800 blue:0.000 alpha:1.], //yellow
                    
                    [UIColor greenColor],
                    [UIColor colorWithRed:0.298 green:0.851 blue:0.392 alpha:1.], // green
                    
                    [UIColor blueColor],
                    [UIColor colorWithRed:0.204 green:0.667 blue:0.863 alpha:1.], // light blue
                    
                    [UIColor colorWithRed:0.180 green:0.800 blue:0.440 alpha:1.], // greens
                    [UIColor colorWithRed:0.150 green:0.680 blue:0.370 alpha:1.],
                    
                    [UIColor colorWithRed:0.000 green:0.478 blue:1.000 alpha:1.], // blue color
                    [UIColor colorWithRed:0.345 green:0.337 blue:0.839 alpha:1.], // violet
                    
                    [UIColor purpleColor],
                    [UIColor brownColor],
                    [UIColor magentaColor],
                    [UIColor cyanColor],
                    
                    //[UIColor colorWithRed:1.000 green:0.827 blue:0.878 alpha:1.000], // light pink
                    //[UIColor colorWithRed:0.878 green:0.973 blue:0.847 alpha:1.000], // light green
                    
                    ];
    });
    return palette;
}

@end
