#import "VENCalculatorInputTextField.h"
#import "VENMoneyCalculator.h"
#import "UITextField+VENCalculatorInputView.h"

@interface VENCalculatorInputTextField ()
@property (strong, nonatomic) VENMoneyCalculator *moneyCalculator;
@end

static NSString * const k_plus_operator     = @"+";
static NSString * const k_minus_operator    = @"−";
static NSString * const k_multiply_operator = @"×";
static NSString * const k_divide_operator   = @"÷";

@implementation VENCalculatorInputTextField

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setUpInit];
    }
    return self;
}

- (void)awakeFromNib {
    [self setUpInit];
}

- (void)setUpInit {
    self.locale = [NSLocale currentLocale];
    
    VENCalculatorInputView *inputView = [VENCalculatorInputView new];
    inputView.delegate = self;
    inputView.locale = self.locale;
    self.inputView = inputView;
    
    VENMoneyCalculator *moneyCalculator = [VENMoneyCalculator new];
    moneyCalculator.locale = self.locale;
    self.moneyCalculator = moneyCalculator;
    
    [self addTarget:self action:@selector(venCalculatorTextFieldDidEndEditing) forControlEvents:UIControlEventEditingDidEnd];
}


#pragma mark - Properties

- (void)setLocale:(NSLocale *)locale {
    _locale = locale;
    VENCalculatorInputView *inputView = (VENCalculatorInputView *)self.inputView;
    inputView.locale = locale;
    self.moneyCalculator.locale = locale;
}


#pragma mark - UITextField

- (void)venCalculatorTextFieldDidEndEditing {
    NSString *textToEvaluate = [self trimExpressionString:self.text];
    NSString *evaluatedString = [self.moneyCalculator evaluateExpression:textToEvaluate];
    if (evaluatedString) {
        self.text = evaluatedString;
    }
}


#pragma mark - VENCalculatorInputViewDelegate

- (void)calculatorInputView:(VENCalculatorInputView *)inputView didTapKey:(NSString *)key {
    if ([self.delegate respondsToSelector:@selector(textField:shouldChangeCharactersInRange:replacementString:)]) {
        NSRange range = [self selectedNSRange];
        if (![self.delegate textField:self shouldChangeCharactersInRange:range replacementString:key]) {
            return;
        }
    }
    
    [self insertText:key];
    NSString *subString = [self.text substringToIndex:self.text.length - 1];
    if ([self stringContainsOperator:key]) {
        NSString *evaluatedString = [self.moneyCalculator evaluateExpression:[self trimExpressionString:subString]];
        if (evaluatedString) {
            self.text = [NSString stringWithFormat:@"%@%@", evaluatedString, key];
        } else {
            self.text = subString;
        }
    } else if ([key isEqualToString:[self decimalSeparator]]) {
        if (self.text.length == 1) {
            self.text = [NSString stringWithFormat:@"0%@",[self decimalSeparator]];
        }
        NSString *secondToLastCharacterString = [self.text substringWithRange:NSMakeRange([self.text length] - 2, 1)];
        if ([secondToLastCharacterString isEqualToString:[self decimalSeparator]]) {
            self.text = subString;
        }
        else if ([[self rigthSideOfExpression:subString] containsString:[self decimalSeparator]]) {
            self.text = subString;
        }
    }
}

- (void)calculatorInputViewDidTapBackspace:(VENCalculatorInputView *)calculatorInputView {
    [self deleteBackward];
}

#pragma mark - Helpers

/**
 Returns the number at the right side of the operator.
 @param expression The string to check.
 @return The string at right side of the operator.
 */
- (NSString *)rigthSideOfExpression:(NSString *)expression {
    NSString *rightSide = expression;
    if ([self stringContainsOperator:expression]) {
        if ([expression containsString:k_plus_operator]) {
            rightSide = [expression substringFromIndex:[expression rangeOfString:k_plus_operator].location+1];
        }
        else if ([expression containsString:k_minus_operator]) {
            rightSide = [expression substringFromIndex:[expression rangeOfString:k_minus_operator].location+1];
        }
        else if ([expression containsString:k_multiply_operator]) {
            rightSide = [expression substringFromIndex:[expression rangeOfString:k_multiply_operator].location+1];
        }
        else if ([expression containsString:k_minus_operator]) {
            rightSide = [expression substringFromIndex:[expression rangeOfString:k_minus_operator].location+1];
        }
    }
    return rightSide;
}

/**
 Checks if the given string contains any operator.
 @param string The string to check.
 @return YES if contains the operator.
 */
- (BOOL)stringContainsOperator:(NSString *)string {
    return ([string containsString:k_plus_operator] ||
            [string containsString:k_minus_operator] ||
            [string containsString:k_multiply_operator] ||
            [string containsString:k_divide_operator] );
}

/**
 Removes any trailing operations and decimals.
 @param expressionString The expression string to trim
 @return The trimmed expression string
 */
- (NSString *)trimExpressionString:(NSString *)expressionString {
    NSString *txt = self.text;
    while ([txt length] > 0) {
        NSString *lastCharacterString = [txt substringFromIndex:[txt length] - 1];
        if ([self stringContainsOperator:lastCharacterString] ||
            [lastCharacterString isEqualToString:self.decimalSeparator]) {
            txt = [txt substringToIndex:txt.length - 1];
        }
        else {
            break;
        }
    }
    return txt;
}

- (NSString *)decimalSeparator {
    return [self.locale objectForKey:NSLocaleDecimalSeparator];
}

@end
