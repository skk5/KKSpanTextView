//
//  ViewController.m
//  KKSpanTextViewDemo
//
//  Created by ewing on 2019/10/25.
//

#import "ViewController.h"
#import "KKSpanTextView.h"

@interface ViewController () <KKSpanTextViewDelegate>
@property (nonatomic, strong) KKSpanTextView *textView;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    KKSpanTextView *tv = [[KKSpanTextView alloc] initWithFrame:CGRectZero];
    tv.spanDelegate = self;
    tv.backgroundColor = [UIColor grayColor];
    tv.spanTextColor = [UIColor blueColor];
    [self.view addSubview:tv];
    
    tv.translatesAutoresizingMaskIntoConstraints = NO;
    
    [[tv.topAnchor constraintEqualToSystemSpacingBelowAnchor:self.view.layoutMarginsGuide.topAnchor multiplier:1] setActive:YES];
    [[tv.widthAnchor constraintEqualToAnchor:self.view.widthAnchor multiplier:1] setActive:YES];
    [[tv.heightAnchor constraintEqualToConstant:100] setActive:YES];
    [[tv.leftAnchor constraintEqualToAnchor:self.view.leftAnchor] setActive:YES];
    
    self.textView = tv;
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    NSAttributedString *span = [[NSAttributedString alloc] initWithString:@"#test span#"];
    
    int random = 0;
    if (self.textView.text.length > 0) {
        random = arc4random() % self.textView.text.length;
    }
    
    BOOL insert = [self.textView insertSpanText:span atIndex:random];
    NSLog(@"insert result: %d", insert);
}

#pragma mark - KKSpanTextViewDelegate
- (BOOL)textViewShouldEndEditing:(UITextView *)textView
{
    NSLog(@"%s[%d]: %s", __FILE__, __LINE__, __func__);
    return YES;
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    NSLog(@"%s[%d]: %s", __FILE__, __LINE__, __func__);
    return YES;
}

- (void)textViewDidChange:(UITextView *)textView
{
    NSLog(@"%s[%d]: %s", __FILE__, __LINE__, __func__);
    NSLog(@"allContent: %@", [self.textView allContent]);
}

@end
