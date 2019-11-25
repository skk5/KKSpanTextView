//
//  KKSpanTextView.m
//  KKSpanTextViewDemo
//
//  Created by ewing on 2019/10/25.
//

#if !__has_feature(objc_arc)
#error You should Activate ARC for this file. (Use '-fobjc-arc' compile flag.)
#endif

#import "KKSpanTextView.h"
//#import <CoreText/CoreText.h>

#define SELECTED_TEXT_RANGE (@"selectedTextRange")
#define PRIVATE_SPAN_MARK (@"span_text_view_span_mark_key")

@interface KKSpanTextView () <UITextViewDelegate>

@property (nonatomic, assign) int spanID;

@end

@implementation KKSpanTextView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.delegate = self;
        [self addObserver:self forKeyPath:SELECTED_TEXT_RANGE options:NSKeyValueObservingOptionOld context:NULL];
        
        _defaultFont = [self font];
        _defaultTextColor = [self textColor];
        _spanID = 0;
    }
    
    return self;
}

- (void)dealloc
{
    self.delegate = nil;
    [self removeObserver:self forKeyPath:@"selectedTextRange"];
}

#pragma mark - Public Interface
- (BOOL)replaceTextInRange:(NSRange)range withSpanText:(NSAttributedString *)text
{
    // check range valid
    NSUInteger end = (range.length == 0 ? 1 : range.length) + range.location;
    for (NSUInteger idx = range.location + 1; idx <= end; idx++) {
        NSRange spanRange = [self rangeOfSpanAt:idx];
        if (spanRange.location != NSNotFound) {
            return NO;
        }
    }
    
    [self keepCaret:^{
        NSMutableAttributedString *attrText = [[NSMutableAttributedString alloc] initWithAttributedString:self.attributedText];
        // add mark.
        NSMutableAttributedString *spanText = [[NSMutableAttributedString alloc] initWithAttributedString:text];
        [spanText addAttribute:PRIVATE_SPAN_MARK value:@(++self.spanID) range:NSMakeRange(0, spanText.length)];
        //
        NSDictionary *originalAttris = [spanText attributesAtIndex:0 effectiveRange:NULL];
        if (!originalAttris[NSForegroundColorAttributeName] && self.spanTextColor) {
            [spanText addAttribute:NSForegroundColorAttributeName value:self.spanTextColor range:NSMakeRange(0, spanText.length)];
        }
        
        if (!originalAttris[NSFontAttributeName] && self.spanFont) {
            [spanText addAttribute:NSFontAttributeName value:self.spanFont range:NSMakeRange(0, spanText.length)];
        }
        
        if (range.location < attrText.length) {
            [attrText replaceCharactersInRange:range withAttributedString:spanText];
        } else {
            [attrText appendAttributedString:spanText];
        }
        
        self.attributedText = attrText;
        
        return range.location;
    }];
    return YES;
}

- (BOOL)insertSpanText:(NSAttributedString *)text atIndex:(NSUInteger)index
{
    return [self replaceTextInRange:NSMakeRange(index, 0) withSpanText:text];
}

- (void)deleteSpanInRange:(NSRange)range
{
    [self keepCaret:^{
        UITextPosition *s = [self positionFromPosition:self.beginningOfDocument offset:range.location];
        UITextPosition *e = [self positionFromPosition:s offset:range.length];
        UITextRange *textRange = [self textRangeFromPosition:s toPosition:e];
        [self replaceRange:textRange withText:@""];
        
        return range.location;
    }];
}

- (BOOL)insertSpanTextAtCaret:(NSAttributedString *)text
{
    return [self insertSpanText:text atIndex:self.selectedRange.location];
}

- (NSArray *)allContent
{
    if (self.attributedText.length == 0) return nil;
    
    NSMutableArray *result = [NSMutableArray array];
    
    NSAttributedString *attrText = self.attributedText;
    
    NSUInteger idx = 0;
    do {
        NSRange r;
        NSDictionary *attr = [attrText attributesAtIndex:idx effectiveRange:&r];
        NSUInteger end = NSMaxRange(r);
        int spanID = [attr[PRIVATE_SPAN_MARK] intValue];
        
        while(end < attrText.length) {
            NSRange er;
            NSDictionary *a = [attrText attributesAtIndex:end effectiveRange:&er];
            if ([a[PRIVATE_SPAN_MARK] intValue] == spanID) {
                end = NSMaxRange(er);
            } else {
                break;
            }
        }
        
        if (spanID == 0) {
            NSString *subText = [attrText.string substringWithRange:NSMakeRange(r.location, end - r.location)];
            if (subText.length > 0) {
                [result addObject:subText];
            }
        } else {
            NSAttributedString *subAttrText = [attrText attributedSubstringFromRange:NSMakeRange(r.location, end - r.location)];
            if (subAttrText.length > 0) {
                [result addObject:subAttrText];
            }
        }

        idx = end;
    }while (idx < attrText.length);
    
    return result;
}

#pragma mark - Protect Method
- (void)setDelegate:(id<UITextViewDelegate>)delegate
{
    NSAssert(delegate == self, @"Plase use spanDelegate instead.");
    [super setDelegate:delegate];
}

- (BOOL)respondsToSelector:(SEL)aSelector
{
    BOOL r = [super respondsToSelector:aSelector];
    if (!r) {
        r = [_spanDelegate respondsToSelector:aSelector];
    }
    
    return r;
}

- (id)forwardingTargetForSelector:(SEL)aSelector
{
    if ([_spanDelegate respondsToSelector:aSelector]) {
        return _spanDelegate;
    }
    
    return [super forwardingTargetForSelector:aSelector];
}

- (void)setText:(NSString *)text
{
    self.font = _defaultFont;
    self.textColor = _defaultTextColor;
    
    [super setText:text];
}

#pragma mark - Private Methods
- (NSRange)rangeOfSpanAt:(NSUInteger)idx
{
     if (idx < self.attributedText.length) {
           NSRange r = NSMakeRange(NSNotFound, 0);
           NSDictionary *attr = [self.attributedText attributesAtIndex:idx effectiveRange:&r];
           if (attr[PRIVATE_SPAN_MARK]) {
               int spanID = [attr[PRIVATE_SPAN_MARK] intValue];
               NSInteger start = r.location - 1;
               NSUInteger end = NSMaxRange(r);
               
               while (start >= 0) {
                   NSRange sr;
                   NSDictionary *att = [self.attributedText attributesAtIndex:start effectiveRange:&sr];
                   if ([att[PRIVATE_SPAN_MARK] intValue] == spanID) {
                       start = sr.location - 1;
                   } else {
                       break;
                   }
               }
               start += 1;
               
               while(end < self.attributedText.length) {
                   NSRange er;
                   NSDictionary *att = [self.attributedText attributesAtIndex:end effectiveRange:&er];
                   if ([att[PRIVATE_SPAN_MARK] intValue] == spanID) {
                       end = NSMaxRange(er);
                   } else {
                       break;
                   }
               }
               
               return NSMakeRange(start, end - start);
           }
       }
       
       return NSMakeRange(NSNotFound, 0);
}

- (void)resetTypingAttributes
{
    NSMutableDictionary *typingAttr = [NSMutableDictionary dictionary];
    if (self.typingAttributes) {
        [typingAttr setDictionary:self.typingAttributes];
    }
    
    if (_defaultTextColor) {
        typingAttr[NSForegroundColorAttributeName] = _defaultTextColor;
    }
    
    if (_defaultFont) {
        typingAttr[NSFontAttributeName] = _defaultFont;
    }
    
    self.typingAttributes = typingAttr;
}

- (void)keepCaret:(NSUInteger(^)(void))block
{
    if (!block) return;
    
    NSRange oldRange = self.selectedRange;
    NSInteger leadingOffset = [self offsetFromPosition:self.beginningOfDocument toPosition:self.selectedTextRange.start];
    NSInteger trailingOffset = [self offsetFromPosition:self.endOfDocument toPosition:self.selectedTextRange.end];
    NSUInteger insertIndex = block();
    
    if (insertIndex > oldRange.location) {
        UITextPosition *p = [self positionFromPosition:self.beginningOfDocument offset:leadingOffset];
        self.selectedTextRange = [self textRangeFromPosition:p toPosition:p];
    } else {
        UITextPosition *p = [self positionFromPosition:self.endOfDocument offset:trailingOffset];
        self.selectedTextRange = [self textRangeFromPosition:p toPosition:p];
    }
}

#pragma mark - KVO
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context
{
    if ([keyPath isEqualToString:SELECTED_TEXT_RANGE]) {
        float judgeRate = 0.5f;
        
        if (self.selectedRange.length == 0) {
            // click mode.
            NSRange spanRange = [self rangeOfSpanAt:self.selectedRange.location];
            if (spanRange.location != NSNotFound) {
                if (spanRange.location + judgeRate * spanRange.length > self.selectedRange.location) {
                    self.selectedRange = NSMakeRange(spanRange.location, 0);
                } else {
                    self.selectedRange = NSMakeRange(NSMaxRange(spanRange), 0);
                }
            }
        } else {
            // selection mode.
            NSUInteger left = self.selectedRange.location;
            NSUInteger right = NSMaxRange(self.selectedRange);
            NSRange leftSpanRange = [self rangeOfSpanAt:self.selectedRange.location];
            if (leftSpanRange.location != NSNotFound) {
                left = leftSpanRange.location;
            }
            NSRange rightSpanRange = [self rangeOfSpanAt:NSMaxRange(self.selectedRange)];
            if (rightSpanRange.location != NSNotFound) {
                right = NSMaxRange(rightSpanRange);
            }
            
            self.selectedRange = NSMakeRange(left, right - left);
        }
    }
}

#pragma mark - UITextViewDelegate
- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    BOOL shouldReplace = YES;
    
    if ([text isEqualToString:@""]) {
        if (textView.selectedRange.length > 0) {
            shouldReplace = YES;
        } else {
            NSUInteger location = textView.selectedRange.location;
            if (location == 0) {
                shouldReplace = YES;
            } else {
                NSRange spanRange = [self rangeOfSpanAt:location - 1];
                if (spanRange.location != NSNotFound) {
                    [self deleteSpanInRange:spanRange];
                    [self resetTypingAttributes];
                    shouldReplace = NO;
                }
            }
        }
    }
    
    if (shouldReplace && [self.spanDelegate respondsToSelector:@selector(textView:shouldChangeTextInRange:replacementText:)]) {
        shouldReplace = [self.spanDelegate textView:textView shouldChangeTextInRange:range replacementText:text];
    }
    
    if (shouldReplace) {
        [self resetTypingAttributes];
    }
    
    return shouldReplace;
}

@end
