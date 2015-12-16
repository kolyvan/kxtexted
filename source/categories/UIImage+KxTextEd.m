//
//  UIImage+KxTextEd.m
//  https://github.com/kolyvan/kxtexted
//
//  Created by Kolyvan on 08.12.15.
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

#import "UIImage+KxTextEd.h"
@import ImageIO;

@implementation UIImage(KxTextEd)

+ (NSString *) texted_sourceTypeWithPath:(NSString *)path size:(CGSize *)outSize
{
    NSData *data = [NSData dataWithContentsOfFile:path options:NSDataReadingMappedIfSafe error:nil];
    if (!data) {
        return nil;
    }
    
    CGImageSourceRef imgSource = CGImageSourceCreateWithData((__bridge CFDataRef)data, NULL);
    if (!imgSource) {
        return nil;
    }
    
    CFStringRef sType = CGImageSourceGetType(imgSource);
    
    if (outSize) {
        
        CFDictionaryRef properties = CGImageSourceCopyPropertiesAtIndex(imgSource, 0, NULL);
        
        if (properties) {
            
            
            CFNumberRef pixelWidth = CFDictionaryGetValue(properties, kCGImagePropertyPixelWidth);
            CFNumberRef pixelHeight = CFDictionaryGetValue(properties, kCGImagePropertyPixelHeight);
            
            *outSize = (CGSize) {
                [(__bridge NSNumber *)pixelWidth integerValue],
                [(__bridge NSNumber *)pixelHeight integerValue],
            };
            
            CFRelease(properties);
            
        } else {
            
            *outSize = CGSizeZero;
        }
    }
    
    CFRelease(imgSource);
    
    return sType ? (__bridge NSString *)sType : nil;
}

- (UIImage *) texted_resizeImageWithRatio:(CGFloat)ratio
{
    if (ratio <= 0. || ratio == 1.) {
        return self;
    }
    
    CGImageRef cgImage = self.CGImage;
    const CGFloat W = roundf(CGImageGetWidth(cgImage) * ratio);
    const CGFloat H = roundf(CGImageGetHeight(cgImage) * ratio);
    const size_t bitsPerComponent = CGImageGetBitsPerComponent(cgImage);
    const size_t bytesPerRow = CGImageGetBytesPerRow(cgImage);
    CGColorSpaceRef colorSpace = CGImageGetColorSpace(cgImage);
    CGBitmapInfo bitmapInfo = CGImageGetBitmapInfo(cgImage);
    
    if (CGColorSpaceGetNumberOfComponents(colorSpace) == 3) {
        const uint32_t alpha = (bitmapInfo & kCGBitmapAlphaInfoMask);
        if (alpha == kCGImageAlphaNone) {
            
            bitmapInfo &= ~kCGBitmapAlphaInfoMask;
            bitmapInfo |= kCGImageAlphaNoneSkipFirst;
            
        } else if (!(alpha == kCGImageAlphaNoneSkipFirst ||
                     alpha == kCGImageAlphaNoneSkipLast)) {
            
            bitmapInfo &= ~kCGBitmapAlphaInfoMask;
            bitmapInfo |= kCGImageAlphaPremultipliedFirst;
        }
    }
    
    CGContextRef context = CGBitmapContextCreate(NULL,
                                                 W,
                                                 H,
                                                 bitsPerComponent,
                                                 bytesPerRow,
                                                 colorSpace,
                                                 bitmapInfo);    
    if (context) {
        
        CGContextSetInterpolationQuality(context, kCGInterpolationHigh);
        CGContextDrawImage(context, (CGRect){0., 0., W, H}, cgImage);
        CGImageRef result = CGBitmapContextCreateImage(context);
        CGContextRelease(context);
        if (result) {
            UIImage *image = [UIImage imageWithCGImage:result
                                                 scale:self.scale
                                           orientation:self.imageOrientation];
            CGImageRelease(result);
            return image;
        }
    }
    
    return nil;
}

@end
