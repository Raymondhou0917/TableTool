//
//  CSVConfiguration.h
//  Table Tool
//
//  Created by Andreas Aigner on 21.07.15.
//  Copyright (c) 2015 Egger Apps. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CSVConfiguration : NSObject <NSCopying>

@property NSStringEncoding encoding;
@property NSString *columnSeparator;
@property NSString *quoteCharacter;
@property NSString *escapeCharacter;
@property NSString *decimalMark;
@property BOOL firstRowAsHeader;
@property NSString *lineEnding;
@property BOOL trailingNewline;
@property BOOL utf8BOM;

// Classification is used for format scoring/alignment only; cell text is never coerced.
-(BOOL)isNumericText:(NSString *)text;
-(BOOL)hasSameFormatAs:(CSVConfiguration *)other;

+(NSArray<NSArray*>*)supportedEncodings;

@end
