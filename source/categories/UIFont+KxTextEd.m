//
//  UIFont+KxTextEd.m
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

#import "UIFont+KxTextEd.h"

@implementation UIFont(KxTextEd)

- (BOOL) texted_hasBoldStyle
{
    UIFontDescriptor *desc = self.fontDescriptor;
    return 0 != (desc.symbolicTraits & UIFontDescriptorTraitBold);
}

- (BOOL) texted_hasItalicStyle
{
    UIFontDescriptor *fd = self.fontDescriptor;
    return 0 != (fd.symbolicTraits & UIFontDescriptorTraitItalic);
}

- (UIFont *) texted_fontWithBoldStyle
{
    UIFontDescriptor *fd = self.fontDescriptor;
    if (0 != (fd.symbolicTraits & UIFontDescriptorTraitBold)) {
        return self;
    }
    fd = [fd fontDescriptorWithSymbolicTraits:fd.symbolicTraits|UIFontDescriptorTraitBold];
    return [UIFont fontWithDescriptor:fd size:self.pointSize];
}

- (UIFont *) texted_fontWithItalicStyle
{
    UIFontDescriptor *fd = self.fontDescriptor;
    if (0 != (fd.symbolicTraits & UIFontDescriptorTraitItalic)) {
        return self;
    }
    fd = [fd fontDescriptorWithSymbolicTraits:fd.symbolicTraits|UIFontDescriptorTraitItalic];
    return [UIFont fontWithDescriptor:fd size:self.pointSize];
}

- (UIFont *) texted_fontWithDiscardBoldStyle
{
    UIFontDescriptor *fd = self.fontDescriptor;
    if (0 == (fd.symbolicTraits & UIFontDescriptorTraitBold)) {
        return self;
    }
    fd = [fd fontDescriptorWithSymbolicTraits:fd.symbolicTraits & ~UIFontDescriptorTraitBold];
    return [UIFont fontWithDescriptor:fd size:self.pointSize];
}

- (UIFont *) texted_fontWithDiscardItalicStyle
{
    UIFontDescriptor *fd = self.fontDescriptor;
    if (0 == (fd.symbolicTraits & UIFontDescriptorTraitItalic)) {
        return self;
    }
    fd = [fd fontDescriptorWithSymbolicTraits:fd.symbolicTraits & ~UIFontDescriptorTraitItalic];
    return [UIFont fontWithDescriptor:fd size:self.pointSize];
}

- (UIFont *) texted_fontWithFamily:(NSString *)name
{
    if ([self.familyName isEqualToString:name]) {
        return self;
    }
    
    UIFont *font = [UIFont fontWithName:name size:self.pointSize];
    if (!font) {
        return self;
    }
    
    const UIFontDescriptorSymbolicTraits traits = self.fontDescriptor.symbolicTraits;
    
    if (0 != (traits & UIFontDescriptorTraitBold)) {
        
        UIFont *p = [font texted_fontWithBoldStyle];
        if (p) {
            font = p;
        }
    }
    
    if (0 != (traits & UIFontDescriptorTraitItalic)) {
        
        UIFont *p = [font texted_fontWithItalicStyle];
        if (p) {
            font = p;
        }
    }
    
    return font;
}

@end
