//
//  ViewController.m
//  EdDemo
//
//  Created by Kolyvan on 04.12.15.
//  Copyright © 2015 Konstantin Bukreev. All rights reserved.
//

#import "ViewController.h"
#import <KxTextEd/KxTextEd.h>

@interface ViewController () <UITextViewDelegate, UISearchBarDelegate>
@property (readonly, nonatomic, strong) UISearchBar *searchBar;
@end

@implementation ViewController

- (instancetype) init
{
    if ((self = [super initWithNibName:nil bundle:nil])) {
        self.title = @"Ed";
    }
    return self;
}

- (void)dealloc
{
    [NSNotificationCenter.defaultCenter removeObserver:self];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _textView = [[KxTextEdView alloc] initWithFrame:self.view.bounds];
    
    _textView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
    _textView.font = [UIFont fontWithName:@"Georgia" size:19.];
    _textView.autocorrectionType = UITextAutocorrectionTypeNo;
    _textView.autocapitalizationType = UITextAutocapitalizationTypeNone;
    _textView.spellCheckingType = UITextSpellCheckingTypeNo;
    _textView.keyboardDismissMode = UIScrollViewKeyboardDismissModeInteractive;
    _textView.delegate = self;
    
    [self.view addSubview:_textView];
    
    
#if 1
        
    _textView.text = @"Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.\nUt enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.\nDuis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur.\nExcepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.";
#else
    
    _textView.text = @"Civil Disobedience\n\nBy Henry David Thoreau - 1849\n\nI HEARTILY ACCEPT the motto, — \"That government is best which governs least\";(1) and I should like to see it acted up to more rapidly and systematically. Carried out, it finally amounts to this, which also I believe, — \"That government is best which governs not at all\"; and when men are prepared for it, that will be the kind of government which they will have. Government is at best but an expedient; but most governments are usually, and all governments are sometimes, inexpedient. The objections which have been brought against a standing army, and they are many and weighty, and deserve to prevail, may also at last be brought against a standing government. The standing army is only an arm of the standing government.The government itself, which is only the mode which the people have chosen to execute their will, is equally liable to be abused and perverted before the people can act through it. Witness the present Mexican war,(2) the work of comparatively a few individuals using the standing government as their tool; for, in the outset, the people would not have consented to this measure.\nThis American government — what is it but a tradition, though a recent one, endeavoring to transmit itself unimpaired to posterity, but each instant losing some of its integrity? It has not the vitality and force of a single living man; for a single man can bend it to his will. It is a sort of wooden gun to the people themselves. But it is not the less necessary for this; for the people must have some complicated machinery or other, and hear its din, to satisfy that idea of government which they have. Governments show thus how successfully men can be imposed on, even impose on themselves, for their own advantage. It is excellent, we must all allow. Yet this government never of itself furthered any enterprise, but by the alacrity with which it got out of its way. It does not keep the country free. It does not settle the West. It does not educate. The character inherent in the American people has done all that has been accomplished; and it would have done somewhat more, if the government had not sometimes got in its way. For government is an expedient by which men would fain succeed in letting one another alone; and, as has been said, when it is most expedient, the governed are most let alone by it. Trade and commerce, if they were not made of India rubber,(3) would never manage to bounce over the obstacles which legislators are continually putting in their way; and, if one were to judge these men wholly by the effects of their actions, and not partly by their intentions, they would deserve to be classed and punished with those mischievous persons who put obstructions on the railroads.";
#endif
    
    [self prepareInputAccessory];
    
    self.navigationItem.leftBarButtonItems =
    @[
      [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSearch target:self action:@selector(actionSearch:)],
      
      [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(actionMore:)],
      ];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShowNotification:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHideNotification:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
    
    self.editing = YES;
}

- (void) viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    
    [_textView resignFirstResponder];
    
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {        
    } completion:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        
        [self prepareInputAccessory];
    }];
}

- (void) prepareInputAccessory
{
    if (self.traitCollection.verticalSizeClass == UIUserInterfaceSizeClassCompact) {
        
        _textView.inputAccessoryView = nil;
        
    } else if (!_textView.inputAccessoryView) {
        
        _textView.inputAccessoryView = ({
            
            const CGSize size = self.view.bounds.size;
            const CGRect frame = (CGRect){0, 0, size.width, size.width > 600. ? 50. : 40.};
            KxTextEdInputAccessory *v = [[KxTextEdInputAccessory alloc] initWithFrame:frame];
            v.textView = _textView;
            v;
        });
    }
}

- (void) actionEdit:(id)sender
{
    self.editing = !self.editing;
}

- (void) setEditing:(BOOL)editing animated:(BOOL)animated
{
    [super setEditing:editing animated:animated];
    
    _textView.editable = editing;
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:editing ? UIBarButtonSystemItemDone : UIBarButtonSystemItemEdit target:self action:@selector(actionEdit:)];
    
    if (editing) {
        [_textView becomeFirstResponder];
    } else {
        [_textView resignFirstResponder];
    }
}

- (void) actionSearch:(id)sender
{
    if (_searchBar) {
        
        _searchBar.delegate = nil;
        _searchBar = nil;
        self.navigationItem.titleView = nil;
        
        [_textView searchText:nil selColor:nil];
        self.editing = self.editing;
        
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSearch target:self action:@selector(actionSearch:)];
        
    } else {
        
        _searchBar = ({
            
            UISearchBar *v = [[UISearchBar alloc] initWithFrame:CGRectZero];
            v.placeholder = @"search";
            v.autocapitalizationType = UITextAutocapitalizationTypeNone;
            v.autocorrectionType = UITextAutocorrectionTypeNo;
            v.spellCheckingType = UITextSpellCheckingTypeNo;
            v.keyboardType = UIKeyboardTypeDefault;
            v.showsCancelButton = YES;
            v.showsSearchResultsButton = NO;
            v.delegate = self;
            v.searchBarStyle = UISearchBarStyleMinimal;
            v.backgroundColor = [UIColor clearColor];
            v.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
            [v sizeToFit];
            v;
        });
        
        self.navigationItem.titleView = _searchBar;
        self.navigationItem.rightBarButtonItem = nil;
        self.navigationItem.leftBarButtonItem = nil;
        
        [_searchBar becomeFirstResponder];
    }
}

- (void) actionMore:(id)sender
{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Actions"
                                                                   message:nil
                                                            preferredStyle:UIAlertControllerStyleAlert];
 
    __weak __typeof(self) weakSelf = self;
    [alert addAction:[UIAlertAction actionWithTitle:@"Save"
                                              style:UIAlertActionStyleDefault
                                            handler:^(UIAlertAction *action)
                      {
                          [weakSelf actionSave:nil];
                      }]];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"Load"
                                              style:UIAlertActionStyleDefault
                                            handler:^(UIAlertAction *action)
                      {
                          [weakSelf actionLoad:nil];
                      }]];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel"
                                              style:UIAlertActionStyleCancel
                                            handler:nil]];
    
    [self presentViewController:alert animated:YES completion:nil];
}

- (void) actionLoad:(id)sender
{
    NSString *contentPath = self.class.contentPath;
    if (![[NSFileManager defaultManager] fileExistsAtPath:contentPath]) {
        return;
    }
    
    NSTextStorage *textStorage = _textView.textStorage;
    
    [textStorage beginEditing];
    
    [textStorage replaceCharactersInRange:NSMakeRange(0, textStorage.length) withString:@""];

    [textStorage readFromURL:[NSURL fileURLWithPath:contentPath]
                     options:@{ NSDocumentTypeDocumentAttribute : NSRTFDTextDocumentType, }
          documentAttributes:nil
                       error:nil];
    
    [textStorage endEditing];
}

- (void) actionSave:(id)sender
{
    NSTextStorage *textStorage = _textView.textStorage;
    NSMutableAttributedString *mas = [textStorage mutableCopy];
    
    NSRange range = {0, mas.length};
    [mas fixAttributesInRange:range];
    
    NSString *contentPath = self.class.contentPath;
    [[NSFileManager defaultManager] removeItemAtPath:contentPath error:nil];
    
    NSFileWrapper *fw = [mas fileWrapperFromRange:range
                               documentAttributes:@{ NSDocumentTypeDocumentAttribute : NSRTFDTextDocumentType, }
                                            error:nil];
    
    if (fw) {
        
        if ([fw writeToURL:[NSURL fileURLWithPath:contentPath]
                   options:NSFileWrapperWritingWithNameUpdating
       originalContentsURL:nil
                     error:nil]) {
            
            NSLog(@"save at %@", contentPath);
        }
    }
}

+ (NSString *) contentPath
{
    NSString *docsPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
                                                              NSUserDomainMask,
                                                              YES) lastObject];
    
    return [docsPath stringByAppendingPathComponent:@"content"];
}

#pragma mark - UITextViewDelegate

- (BOOL)textView:(UITextView *)textView shouldInteractWithURL:(NSURL *)URL inRange:(NSRange)characterRange
{
    NSLog(@"%s %@", __PRETTY_FUNCTION__, URL);
    return YES;
}

#pragma mark - UISearchBarDelegate

- (void)searchBar:(UISearchBar *)searchBar
    textDidChange:(NSString *)searchText
{
    if (searchText.length == 0 || searchText.length > 2) {
        
        [_textView searchText:searchText
                     selColor:[UIColor colorWithRed:0.88 green:0.97 blue:0.85 alpha:1.]];
    }
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    [_textView searchText:searchBar.text
                 selColor:[UIColor colorWithRed:0.88 green:0.97 blue:0.85 alpha:1.]];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    [self actionSearch:nil];
}

#pragma mark - Keyboard

- (void)keyboardWillShowNotification:(NSNotification *)notification
{
    const CGRect keyboard = [notification.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    const CGFloat bottom = CGRectGetHeight(keyboard);
    
    UIEdgeInsets contentInset = _textView.contentInset;
    contentInset.bottom = bottom;
    _textView.contentInset = contentInset;
    _textView.scrollIndicatorInsets = contentInset;
}

- (void)keyboardWillHideNotification:(NSNotification *)notification
{
    UIEdgeInsets contentInset = _textView.contentInset;
    contentInset.bottom = 0;
    _textView.contentInset = contentInset;
}

@end
