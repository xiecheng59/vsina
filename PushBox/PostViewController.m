//
//  PostViewController.m
//  PushBox
//
//  Created by Xie Hasky on 11-7-30.
//  Copyright 2011年 同济大学. All rights reserved.
//

#import "PostViewController.h"
#import "UIApplicationAddition.h"
#import "PushBoxAppDelegate.h"
#import "AnimationProvider.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import "WeiboClient.h"
#import "Status.h"
#import "User.h"
#import "AnimationProvider.h"

#define LabelRedColor [UIColor colorWithRed:143/255.0 green:63/255.0 blue:63/255.0 alpha:1.0]
#define LabelBlackColor [UIColor colorWithRed:100/255.0 green:100/255.0 blue:100/255.0 alpha:1.0]
@implementation PostViewController

@synthesize titleLabel = _titleLabel;
@synthesize wordsCountLabel = _wordsCountLabel;
@synthesize cancelButton = _cancelButton;
@synthesize doneButton = _doneButton;
@synthesize referButton = _referButton;
@synthesize topicButton = _topicButton;
@synthesize camaraButton = _camaraButton;
@synthesize textView = _textView;
@synthesize postingRoundImageView = _postingRoundImageView;
@synthesize postingCircleImageView = _postingCircleImageView;
@synthesize rightView = _rightView;
@synthesize rightImageView = _rightImageView;
@synthesize pc = _pc;
@synthesize targetStatus = _targetStatus;
@synthesize atView = _atView;
@synthesize atScreenNames = _atScreenNames;
@synthesize atTableView = _atTableView;
@synthesize atTextField = _atTextField;
@synthesize emotionsView = _emotionsView;
@synthesize locationButton = _locationButton;
@synthesize locationLabel = _lacationLabel;
//@synthesize emotionsView = _emotionsView;
//@synthesize emotionsScrollView = _emotionsScrollView;
//@synthesize emotionsPageControl = _emotionsPageControl;

- (void)dealloc
{
    NSLog(@"PostViewController dealloc");
    
    [_titleLabel release];
    [_wordsCountLabel release];
    [_cancelButton release];
    [_doneButton release];
    [_referButton release];
    [_topicButton release];
    [_camaraButton release];
    [_textView release];
    [_rightView release];
    [_rightImageView release];
    [_atView release];
    [_pc release];
    [_atScreenNames release];
    [_targetStatus release];
	[_postingCircleImageView release];
	[_postingRoundImageView release];
    [super dealloc];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    self.titleLabel = nil;
    self.wordsCountLabel = nil;
    self.cancelButton = nil;
    self.doneButton = nil;
    self.referButton = nil;
    self.topicButton = nil;
    self.camaraButton = nil;
    self.textView = nil;
    self.rightView = nil;
    self.atView = nil;
    self.rightImageView = nil;
	self.postingCircleImageView = nil;
	self.postingRoundImageView = nil;
}

- (id)initWithType:(PostViewType)type
{
    self = [super init];
    _type = type;
    return self;
}

- (void)getLoacationInfo 
{
    [self.locationLabel setHidden:NO];
    // TODO    
    // 如果可以利用本地服务时
    if([CLLocationManager locationServicesEnabled]){
        
        man = [[CLLocationManager alloc] init];
        
        man.delegate = self;
        
        //        // 发生事件的的最小距离间隔（缺省是不指定）
        //        man.distanceFilter = kCLDistanceFilterNone;
        //        
        //        // 精度 (缺省是Best)
        //        man.desiredAccuracy = kCLLocationAccuracyBest;
        
        // 开始测量
        [man startUpdatingLocation];
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.textView.text = nil;
    [self.textView becomeFirstResponder];
    
    if (_type == PostViewTypeRepost) {
        //        [self.camaraButton removeFromSuperview];
        //        self.camaraButton = nil;
        [self.camaraButton setEnabled:NO];
        
        self.titleLabel.text = NSLocalizedString(@"转发微博", nil);
        if (self.targetStatus.repostStatus) {
			self.textView.text = [NSString stringWithFormat:NSLocalizedString(@" //@%@:%@", nil), 
                                  self.targetStatus.author.screenName,
                                  self.targetStatus.text];
		}
		else {
			self.textView.text = NSLocalizedString(@"转发微博", nil);
		}
		NSRange range;
		range.location = 0;
		range.length = 0;
		self.textView.selectedRange = range;
        
        [self.locationLabel setHidden:YES];
        [self.locationButton setHidden:YES];
    }
	
	[self textViewDidChange:self.textView];
	
    _emotionsViewController = [[EmotionsViewController alloc] init];
    self.emotionsView = _emotionsViewController.view;
    self.emotionsView.layer.anchorPoint = CGPointMake(0.5, 0);
    _emotionsViewController.delegate = self;
    
	self.rightView.layer.anchorPoint = CGPointMake(0, 0.4);
	self.atView.layer.anchorPoint = CGPointMake(0.5, 0);
    self.textView.delegate = self;
    
    // Location
    if (_type != PostViewTypeRepost) {
        NSUserDefaults *userDefault = [NSUserDefaults standardUserDefaults];
        Boolean isAutoLocate = [[userDefault objectForKey:kUserDefaultKeyAutoLocate] boolValue];
        if (isAutoLocate) {
            self.locationButton.selected = YES;
            [self getLoacationInfo];
        }
        else {
            self.locationButton.selected = NO;
        }
    }
}

- (void)textViewDidChange:(UITextView *)textView
{
    NSString *text = self.textView.text;
    //    int leng = [text length];
    int bytes = [text lengthOfBytesUsingEncoding:NSUTF16StringEncoding];
    const char *ptr = [text cStringUsingEncoding:NSUTF16StringEncoding];
    int words = 0;
    for (int i = 0; i < bytes; i++) {
        if (*ptr) {
            words++;
        }
        ptr++;
    }
    words += 1;
    words /= 2;
    words = 140 - words;
    self.wordsCountLabel.text = [NSString stringWithFormat:@"%d", words];
    self.doneButton.enabled = words >= 0;
    
    if (words >= 0) {
        self.wordsCountLabel.text = [NSString stringWithFormat:@"%d", words];
        self.wordsCountLabel.textColor = LabelBlackColor;
    } else {
        self.wordsCountLabel.text = [NSString stringWithFormat:@"超出 %d", -words];
        self.wordsCountLabel.textColor = LabelRedColor;
    }
    
    //
    if ((NSString*)_lastChar && [(NSString*)_lastChar compare:@"@"] == NSOrderedSame) {
        NSLog(@"!!!!!!!!!!!!%@", _lastChar);
        [self atButtonClicked:nil];
    }
}

- (IBAction)locationButtonClicked:(UIButton*)sender {    
    if (sender.selected) {
        sender.selected = NO;
        [self.locationLabel setHidden:YES];
    }
    else {
        sender.selected = YES;
        [self.locationLabel setHidden:NO];
        [self getLoacationInfo];
    }
}

- (IBAction)atButtonClicked:(id)sender {    
    if (sender) {
        int location = self.textView.selectedRange.location;
        NSString *content = self.textView.text;
        NSString *result = [NSString stringWithFormat:@"%@@%@",[content substringToIndex:location], [content substringFromIndex:location]];
        self.textView.text = result;
        
        NSRange range = self.textView.selectedRange;
        range.location = location + 1;
        self.textView.selectedRange = range;
    }
    
    UIView *superView = [self.view superview];
    
    if (!_atBgButton)
        _atBgButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 1024, 748)];
    
    [_atBgButton addTarget:self action:@selector(dismissAtView) forControlEvents:UIControlEventTouchUpInside];
    [superView addSubview:_atBgButton];
    
    [superView addSubview:self.atView];
    CGRect frame = self.atView.frame;
    frame.origin = CGPointMake(200, 105);
    self.atView.frame = frame;
    
    [self.atView.layer addAnimation:[AnimationProvider popoverAnimation] forKey:nil];
    
    self.atTextField.text = @"";
    [self.atTextField becomeFirstResponder];
    
    [UIView animateWithDuration:1.0 animations:^{
        self.atView.alpha = 1.0;
    }];
    
    [self atTextFieldEditingBegan];
}

- (IBAction)emotionsButtonClicked:(id)sender {    
    UIView *superView = [self.view superview];
    
    if (!_emotionBgButton)
        _emotionBgButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 1024, 748)];
    
    [_emotionBgButton addTarget:self action:@selector(dismissEmotionsView) forControlEvents:UIControlEventTouchUpInside];
    [superView addSubview:_emotionBgButton];
    
    [superView addSubview:self.emotionsView];
    CGRect frame = self.emotionsView.frame;
    frame.origin = CGPointMake(321, 106);
    self.emotionsView.frame = frame;
    [_emotionsViewController.scrollView scrollRectToVisible:CGRectMake(0, 0, 204, 144) animated:NO];
    
    [self.emotionsView.layer addAnimation:[AnimationProvider popoverAnimation] forKey:nil];
    
    [UIView animateWithDuration:1.0 animations:^{
        self.emotionsView.alpha = 1.0;
    }];
}

- (void)dismissView
{
    if (self.rightView.superview) {
        [self.rightView removeFromSuperview];
    }
    if (self.atView.superview) {
        [self.atView removeFromSuperview];
    }
    [self.textView resignFirstResponder];
    [[UIApplication sharedApplication] dismissModalViewController];
}

- (IBAction)cancelButtonClicked:(UIButton *)sender {
    if ([self.textView.text length] == 0) {
        [self dismissView];
    }
    else {
        UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil 
                                                                 delegate:self 
                                                        cancelButtonTitle:nil 
                                                   destructiveButtonTitle:NSLocalizedString(@"取消" , nil)
                                                        otherButtonTitles:nil];
        [actionSheet showFromRect:sender.bounds inView:sender animated:YES];
        [actionSheet release];
    }
}

- (void)dismissAtView
{
    if (self.atView.superview) {
        [UIView animateWithDuration:0.3 
                         animations:^(){
                             self.atView.alpha = 0.0;
                         } 
                         completion:^(BOOL finished) {
                             [self.atView removeFromSuperview];
                             self.atView.alpha = 1.0;
                         }];
    }
    
    [_atBgButton removeFromSuperview];
    
    [self.textView becomeFirstResponder];
}

- (void)dismissEmotionsView
{
    if (self.emotionsView.superview) {
        [UIView animateWithDuration:0.3 
                         animations:^(){
                             self.emotionsView.alpha = 0.0;
                         } 
                         completion:^(BOOL finished) {
                             [self.emotionsView removeFromSuperview];
                             self.emotionsView.alpha = 1.0;
                         }];
    }
    
    [_emotionBgButton removeFromSuperview];
    
    [self.textView becomeFirstResponder];
}

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == actionSheet.destructiveButtonIndex) {
        [self dismissView];
    }
}

- (void)showPostingView
{
    _postingCircleImageView.alpha = 1.0;
    _postingRoundImageView.alpha = 1.0;
    
    CABasicAnimation *rotationAnimation =[CABasicAnimation animationWithKeyPath:@"transform.rotation"];
    rotationAnimation.duration = 1.0;
    rotationAnimation.fromValue = [NSNumber numberWithFloat:0.0];
    rotationAnimation.toValue = [NSNumber numberWithFloat:-2.0 * M_PI];
    rotationAnimation.repeatCount = 65535;
    [_postingCircleImageView.layer addAnimation:rotationAnimation forKey:@"kAnimationLoad"];
}

- (void)hidePostingView
{
    [UIView animateWithDuration:1.0 animations:^{
        _postingRoundImageView.alpha = 0.0;
        _postingCircleImageView.alpha = 0.0;
    } completion:^(BOOL finished) {
        [_postingCircleImageView.layer removeAnimationForKey:@"kAnimationLoad"];
    }];
}

- (IBAction)doneButtonClicked:(id)sender {
    NSString *status = self.textView.text;
    
    if (!status.length) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"错误", nil)
                                                        message:NSLocalizedString(@"微博内容不能为空", nil)
                                                       delegate:self
                                              cancelButtonTitle:NSLocalizedString(@"确定", nil)
                                              otherButtonTitles:nil];
        [alert show];
        [alert release];
        return;
    }
    
    WeiboClient *client = [WeiboClient client];
    
    [self showPostingView];
    [client setCompletionBlock:^(WeiboClient *client) {
        [self hidePostingView];
        if (!client.hasError) {
            [self dismissView];
            [[UIApplication sharedApplication] showOperationDoneView];
        } else {
            [ErrorNotification showPostError];
        }
    }];
    
    if (_type == PostViewTypeRepost) {
        [client repost:self.targetStatus.statusID 
                  text:status 
         commentStatus:NO 
         commentOrigin:NO];
    }
    else {
        if (!self.camaraButton.enabled && self.rightImageView.image) {
            [client post:status withImage:self.rightImageView.image];
        }
        else {
            if (self.locationButton.selected) {
                [client post:status cor:man.location.coordinate];
            }
            else {
                [client post:status];
            }
        }
    }
    
}

- (void)configureAtScreenNamesArray:(NSString*)text
{    
    if (self.atScreenNames) {
        [self.atScreenNames removeAllObjects];
    }
    else {
        self.atScreenNames = [[[NSMutableArray alloc] initWithCapacity:1] autorelease];
    }
    
    // init
    if ([text compare:@"init"] == NSOrderedSame) {
        [self.atScreenNames addObject:[[[NSString alloc] initWithFormat:@"@"] autorelease]];
    }
    
    // text
    else {        
        [self.atScreenNames insertObject:[[[NSString alloc] initWithFormat:@"@%@", text] autorelease] atIndex:0];
        
        NSManagedObjectContext* context = [(PushBoxAppDelegate*)[[UIApplication sharedApplication] delegate] managedObjectContext];
        NSEntityDescription *entityDescription = [NSEntityDescription                                                  entityForName:@"User" inManagedObjectContext:context];
        NSFetchRequest *request = [[[NSFetchRequest alloc] init] autorelease];
        [request setEntity:entityDescription];
        NSPredicate *predicate = [NSPredicate predicateWithFormat:[[[NSString alloc] initWithFormat:@"screenName like[c] \"*%@*\"", text] autorelease]];
        [request setPredicate:predicate];
        NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc]                                                                      initWithKey:@"screenName" ascending:YES];
        [request setSortDescriptors:[NSArray arrayWithObject:sortDescriptor]];
        [sortDescriptor release];
        NSError *error;
        NSArray *array = [context executeFetchRequest:request error:&error];
        
        for (int i = 0; i < [array count]; i++) {
            [self.atScreenNames addObject:[[[NSString alloc] initWithFormat:@"@%@", [[array objectAtIndex:i] screenName]] autorelease]];
        }
    }
}


- (Boolean)isAtEndChar:(unichar)c
{
    NSArray* atEndCharArray = [[[NSArray alloc] initWithObjects:
                                [[[NSNumber alloc] initWithInt:44] autorelease],   // ' '
                                [[[NSNumber alloc] initWithInt:46] autorelease],   // ' '
                                [[[NSNumber alloc] initWithInt:32] autorelease],   // ' '
                                [[[NSNumber alloc] initWithInt:64] autorelease],   // '@'
                                [[[NSNumber alloc] initWithInt:58] autorelease],   // ':'
                                [[[NSNumber alloc] initWithInt:59] autorelease],   // ';'
                                [[[NSNumber alloc] initWithInt:35] autorelease],   // '#'
                                [[[NSNumber alloc] initWithInt:39] autorelease],   // '''
                                [[[NSNumber alloc] initWithInt:34] autorelease],   // '"'
                                [[[NSNumber alloc] initWithInt:40] autorelease],   // '('
                                [[[NSNumber alloc] initWithInt:41] autorelease],   // ')'
                                [[[NSNumber alloc] initWithInt:91] autorelease],   // '['
                                [[[NSNumber alloc] initWithInt:93] autorelease],   // ']'
                                [[[NSNumber alloc] initWithInt:123] autorelease],   // '{'
                                [[[NSNumber alloc] initWithInt:125] autorelease],   // '}'
                                [[[NSNumber alloc] initWithInt:126] autorelease],   // '~'
                                [[[NSNumber alloc] initWithInt:33] autorelease],   // '!'
                                [[[NSNumber alloc] initWithInt:36] autorelease],   // '$'
                                [[[NSNumber alloc] initWithInt:37] autorelease],   // '%'
                                [[[NSNumber alloc] initWithInt:94] autorelease],   // '^'
                                [[[NSNumber alloc] initWithInt:38] autorelease],   // '&'
                                [[[NSNumber alloc] initWithInt:42] autorelease],   // '*'
                                [[[NSNumber alloc] initWithInt:43] autorelease],   // '+'
                                [[[NSNumber alloc] initWithInt:61] autorelease],   // '='
                                [[[NSNumber alloc] initWithInt:124] autorelease],   // '|'
                                [[[NSNumber alloc] initWithInt:60] autorelease],   // '<'
                                [[[NSNumber alloc] initWithInt:62] autorelease],   // '>'
                                [[[NSNumber alloc] initWithInt:92] autorelease],   // '\'
                                [[[NSNumber alloc] initWithInt:47] autorelease],   // '/'
                                [[[NSNumber alloc] initWithInt:63] autorelease],   // '?'
                                [[[NSNumber alloc] initWithInt:65306] autorelease],   // '"'
                                [[[NSNumber alloc] initWithInt:65307] autorelease],   // '"'
                                [[[NSNumber alloc] initWithInt:8216] autorelease],   // '"'
                                [[[NSNumber alloc] initWithInt:8217] autorelease],   // '"'
                                [[[NSNumber alloc] initWithInt:8220] autorelease],   // '"'
                                [[[NSNumber alloc] initWithInt:8221] autorelease],   // '"'
                                [[[NSNumber alloc] initWithInt:65288] autorelease],   // '"'
                                [[[NSNumber alloc] initWithInt:65289] autorelease],   // '"'
                                [[[NSNumber alloc] initWithInt:65339] autorelease],   // '"'
                                [[[NSNumber alloc] initWithInt:12290] autorelease],   // '"'
                                [[[NSNumber alloc] initWithInt:65341] autorelease],   // '"'
                                [[[NSNumber alloc] initWithInt:65292] autorelease],   // '，'
                                [[[NSNumber alloc] initWithInt:12289] autorelease],   // '、'
                                [[[NSNumber alloc] initWithInt:65371] autorelease],   // '"'
                                [[[NSNumber alloc] initWithInt:65373] autorelease],   // '"'
                                [[[NSNumber alloc] initWithInt:65374] autorelease],   // '"'
                                [[[NSNumber alloc] initWithInt:65281] autorelease],   // '"'
                                [[[NSNumber alloc] initWithInt:65283] autorelease],   // '"'
                                [[[NSNumber alloc] initWithInt:65509] autorelease],   // '"'
                                [[[NSNumber alloc] initWithInt:65285] autorelease],   // '"'
                                [[[NSNumber alloc] initWithInt:8212] autorelease],   // '"'
                                [[[NSNumber alloc] initWithInt:65290] autorelease],   // '"'
                                [[[NSNumber alloc] initWithInt:65291] autorelease],   // '"'
                                [[[NSNumber alloc] initWithInt:65309] autorelease],   // '"'
                                [[[NSNumber alloc] initWithInt:65372] autorelease],   // '"'
                                [[[NSNumber alloc] initWithInt:12298] autorelease],   // '"'
                                [[[NSNumber alloc] initWithInt:65295] autorelease],   // '"'
                                [[[NSNumber alloc] initWithInt:65311] autorelease],   // '"'
                                [[[NSNumber alloc] initWithInt:8230] autorelease],   // '"'
                                nil] autorelease];
    for (int i = 0; i < [atEndCharArray count]; i++)
    {
        if (c == [[atEndCharArray objectAtIndex:i] intValue])
            return YES;
    }
    
    return NO;
}

- (BOOL)isAtStringValid:(NSString*)str {
    for (int i = 0; i < [str length]; i++) {
        if ([self isAtEndChar:[str characterAtIndex:i]]) {
            return NO;
        }
    }
    return YES;
}

- (IBAction)atTextFieldEditingChanged:(UITextField*)textField {
    
    if ([self isAtStringValid:textField.text]) {
        [self configureAtScreenNamesArray:textField.text];
        [self.atTableView reloadData];
    }
    else {
        if (self.atScreenNames) {
            [self.atScreenNames removeAllObjects];
        }
        self.atScreenNames = [[[NSMutableArray alloc] initWithObjects:[[[NSString alloc] initWithFormat:@"@%@", textField.text] autorelease], nil] autorelease];
        [self.atTableView reloadData];
    }
}

- (IBAction)atTextFieldEditingEnd {
    [self dismissAtView];
}

- (IBAction)atTextFieldEditingBegan {
    
    [self configureAtScreenNamesArray:self.atTextField.text];
    [self.atTableView reloadData];
}

- (IBAction)topicButtonClicked:(id)sender {
    NSString *text = self.textView.text;
    text = [text stringByAppendingString:@"##"];
    self.textView.text = text;
    int length = text.length;
    NSRange range;
    range.location = length-1;
    range.length = 0;
    self.textView.selectedRange = range;
}

- (IBAction)camaraButtonClicked:(id)sender {
    UIImagePickerController *ipc = [[UIImagePickerController alloc] init];
    ipc.delegate = self;
    ipc.mediaTypes = [NSArray arrayWithObject:(NSString *)kUTTypeImage];
    
    _pc = [[UIPopoverController alloc] initWithContentViewController:ipc];
    [ipc release];
    
    self.pc.delegate = self;
    
    [self.textView resignFirstResponder];
    [self.pc presentPopoverFromRect:self.camaraButton.bounds inView:self.camaraButton
           permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
}

- (IBAction)removeImageButtonClicked:(id)sender {
    self.camaraButton.hidden = NO;
    [self.camaraButton setEnabled:YES];
    
    [UIView animateWithDuration:0.3 animations:^{
        self.rightView.alpha = 0.0;
    } completion:^(BOOL fin) {
        if (fin) {
            [self.rightView removeFromSuperview];
        }
    }];
}

- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController
{
    self.pc = nil;
    [self.textView becomeFirstResponder];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    UIImage *img = [info objectForKey:UIImagePickerControllerOriginalImage];
    [self.pc dismissPopoverAnimated:YES];
    self.pc = nil;
    
    CGRect frame = self.rightView.frame;
    frame.origin = CGPointMake(737, 42);
    self.rightView.frame = frame;
    
    self.rightImageView.image = img;
    self.rightView.alpha = 0;
    
//    self.camaraButton.hidden = YES;
    [self.camaraButton setEnabled:NO];
    
    UIView *superView = [self.view superview];
    [superView addSubview:self.rightView];
    self.rightView.alpha = 1.0;
    [self.rightView.layer addAnimation:[AnimationProvider popoverAnimation] forKey:nil];
    
    [self.textView becomeFirstResponder];
}

#pragma - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.atScreenNames count];
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    NSString *CellIdentifier = @"PostViewAtTableViewCell";
    PostViewAtTableViewCell *cell = (PostViewAtTableViewCell*)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (cell == nil) {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"PostViewAtTableViewCell" owner:self options:nil];
        cell = [nib lastObject];
    }
    
    cell.screenNameLabel.text = [_atScreenNames objectAtIndex:[indexPath row]];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    int location = self.textView.selectedRange.location;
    NSString *content = self.textView.text;
    NSString *result = [NSString stringWithFormat:@"%@%@%@",[content substringToIndex:location], ([[[self.atScreenNames objectAtIndex:[indexPath row]] substringFromIndex:1] stringByAppendingString:@" "]), [content substringFromIndex:location]];
    
    self.textView.text = result;
    NSRange range = self.textView.selectedRange;
    range.location = location + [([[[self.atScreenNames objectAtIndex:[indexPath row]] substringFromIndex:1] stringByAppendingString:@" "]) length];
    self.textView.selectedRange = range;
    
    [self dismissAtView];
}

- (void)didSelectEmotion:(NSString*)phrase
{
    int location = self.textView.selectedRange.location;
    NSString *content = self.textView.text;
    NSString *result = [NSString stringWithFormat:@"%@%@%@",[content substringToIndex:location], phrase, [content substringFromIndex:location]];
    self.textView.text = result;
    
    NSRange range = self.textView.selectedRange;
    range.location = location + [phrase length];
    self.textView.selectedRange = range;
    
    [self dismissEmotionsView];
    
}

#pragma - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    
    int location = self.textView.selectedRange.location;
    NSString *content = self.textView.text;
    NSString *result = [NSString stringWithFormat:@"%@%@%@",[content substringToIndex:location], ([[[self.atScreenNames objectAtIndex:0] substringFromIndex:1] stringByAppendingString:@" "]), [content substringFromIndex:location]];
    self.textView.text = result;
    
    NSRange range = self.textView.selectedRange;
    range.location = location + [([[[self.atScreenNames objectAtIndex:0] substringFromIndex:1] stringByAppendingString:@" "]) length];
    self.textView.selectedRange = range;
    
    [self dismissAtView];
    
    return NO;
}

#pragma - UITextViewDelegate

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    _lastChar = [text retain];
    return YES;
}

#pragma - CoreLoction

// 如果GPS测量成果以下的函数被调用
- (void)locationManager:(CLLocationManager *)manager
    didUpdateToLocation:(CLLocation *)newLocation
           fromLocation:(CLLocation *)oldLocation{
    
    //    // 取得经纬度
    //    CLLocationCoordinate2D coordinate = newLocation.coordinate;
    //    CLLocationDegrees latitude = coordinate.latitude;
    //    CLLocationDegrees longitude = coordinate.longitude;
    //    // 取得精度
    //    CLLocationAccuracy horizontal = newLocation.horizontalAccuracy;
    //    CLLocationAccuracy vertical = newLocation.verticalAccuracy;
    //    // 取得高度
    //    CLLocationDistance altitude = newLocation.altitude;
    //    // 取得时刻
    //    NSDate *timestamp = [newLocation timestamp];
    //    // 以下面的格式输出 format: <latitude>, <longitude>> +/- <accuracy>m @ <date-time>
    //    NSLog([newLocation description]);
    //    // 与上次测量地点的间隔距离
    //    if(oldLocation != nil){
    //        CLLocationDistance d = [newLocation getDistanceFrom:oldLocation];
    //        NSLog([NSString stringWithFormat:@"%f", d]);
    //    }
    
    //    CLGeocoder* glcoder = [[CLGeocoder alloc] init];
    //    [glcoder reverseGeocodeLocation:manager.location completionHandler:^(NSArray* placemarks, NSError* error) {
    //        CLPlacemark* pm = [placemarks lastObject];
    //        NSLog(@"%@", [pm administrativeArea]);
    //        NSLog(@"%@", [pm country]);
    //        NSLog(@"%@", [pm inlandWater]);
    //        NSLog(@"%@", [pm ISOcountryCode]);
    //        NSLog(@"%@", [pm locality]);
    //        NSLog(@"%@", [pm name]);
    //        NSLog(@"%@", [pm ocean]);
    //        NSLog(@"%@", [pm postalCode]);
    //        NSLog(@"%@", [pm subAdministrativeArea]);
    //        NSLog(@"%@", [pm subLocality]);
    //        NSLog(@"%@", [pm subThoroughfare]);
    //        NSLog(@"%@", [pm thoroughfare]);
    //    }];
    
    WeiboClient *client = [WeiboClient client];
    [client setCompletionBlock:^(WeiboClient *client) {
		[self hidePostingView];
        if (!client.hasError) {
            NSDictionary* dic = (NSDictionary*)client.responseJSONObject;
            dic = (NSDictionary*)[dic objectForKey:@"address"];
            self.locationLabel.text = [[NSString alloc] initWithFormat:@"%@%@%@", [dic objectForKey:@"city_name"], [dic objectForKey:@"district_name"], [dic objectForKey:@"poi_name"]];
        } else {
            // ERROR
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"定位失败" 
                                                                message:@"请检查网络和定位设置并重试"
                                                               delegate:nil
                                                      cancelButtonTitle:NSLocalizedString(@"确定", nil)
                                                      otherButtonTitles:nil];
            [alertView show];
            [alertView release];
            
            [self.locationLabel setHidden:YES];
            [self.locationLabel setText:@"正在定位..."];
            [self.locationButton setSelected:NO];
		}
    }];
    float lat = (float)newLocation.coordinate.latitude;
    float lon = (float)newLocation.coordinate.longitude;
    [client getAddressFromGeoWithCoordinate:[[NSString alloc] initWithFormat:@"%f,%f", lon, lat]];
    
    [manager stopUpdatingLocation];
}

- (void)locationManager:(CLLocationManager *)manager
       didFailWithError:(NSError *)error{
    
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"定位失败" 
                                                        message:@"请检查网络和定位设置并重试"
                                                       delegate:nil
                                              cancelButtonTitle:NSLocalizedString(@"确定", nil)
                                              otherButtonTitles:nil];
    [alertView show];
    [alertView release];
    
    [self.locationLabel setHidden:YES];
    [self.locationLabel setText:@"正在定位..."];
    [self.locationButton setSelected:NO];

    [manager stopUpdatingLocation];
}

@end
