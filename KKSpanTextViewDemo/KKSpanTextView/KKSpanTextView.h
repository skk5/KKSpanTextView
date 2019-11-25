//
//  KKSpanTextView.h
//  KKSpanTextViewDemo
//
//  Created by ewing on 2019/10/25.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol KKSpanTextViewDelegate <UITextViewDelegate>



@end

@interface KKSpanTextView : UITextView

@property (nonatomic, weak) id<KKSpanTextViewDelegate> spanDelegate;

// default attribute for span text
@property (nonatomic, strong) UIColor *spanTextColor;
@property (nonatomic, strong) UIFont *spanFont;

@property (nonatomic, strong) UIColor *defaultTextColor; // since attributedText change textColor, add this property.
@property (nonatomic, strong) UIFont *defaultFont; // same reason.

- (BOOL)replaceTextInRange:(NSRange)range withSpanText:(NSAttributedString *)text;
- (BOOL)insertSpanText:(NSAttributedString *)text atIndex:(NSUInteger)index; // index in total content
- (BOOL)insertSpanTextAtCaret:(NSAttributedString *)text;
- (void)deleteSpanInRange:(NSRange)range;

- (NSArray *)allContent; // array of String|AttributedString, string means normal text, attributedString means span text.
@end

NS_ASSUME_NONNULL_END
