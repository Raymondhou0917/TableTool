//
//  CSVConfiguration.m
//  Table Tool
//
//  Created by Andreas Aigner on 21.07.15.
//  Copyright (c) 2015 Egger Apps. All rights reserved.
//

#import "CSVConfiguration.h"

@implementation CSVConfiguration

-(instancetype)init {
    self = [super init];
    if(self){
        _encoding = NSUTF8StringEncoding;
        _columnSeparator = @",";
        _quoteCharacter = @"\"";
        _escapeCharacter = @"\"";
        _decimalMark = @".";
        _firstRowAsHeader = NO;
    }
    return self;
}

-(id)copyWithZone:(NSZone *)zone {
    CSVConfiguration *copy = [[CSVConfiguration allocWithZone:zone]init];
    copy->_encoding = _encoding;
    copy->_columnSeparator = _columnSeparator;
    copy->_decimalMark = _decimalMark;
    copy->_escapeCharacter = _escapeCharacter;
    copy->_quoteCharacter = _quoteCharacter;
    copy->_firstRowAsHeader = _firstRowAsHeader;
    return copy;
}

-(NSString *)description {
    return [NSString stringWithFormat:@"separator: \'%@\', quote: \'%@\', escape: \'%@\', decimal: \'%@\', firstAsHeader: %@",
            _columnSeparator, _quoteCharacter, _escapeCharacter, _decimalMark, _firstRowAsHeader ? @"YES" : @"NO"];
}

+(NSArray<NSArray*>*)supportedEncodings {
	return @[
	  @[NSLocalizedString(@"Unicode (UTF-8)", nil), @(0x4)],
	  @[NSLocalizedString(@"Western (Mac OS Roman)", nil), @(0x1e)],
	  @[NSLocalizedString(@"Western (Windows Latin 1)", nil), @(0xc)],
	  @[NSLocalizedString(@"Chinese (GBK)", nil), @(0x80000632)],
	  @[NSLocalizedString(@"Traditional Chinese (Big5)", nil), @(0x80000a03)],
	  @[NSLocalizedString(@"Central European (ISO Latin 2)", nil), @(0x9)],
	  @[NSLocalizedString(@"Central European (Windows Latin 2)", nil), @(0xf)],
	  @[NSLocalizedString(@"Cyrillic (Windows)", nil), @(0xb)],
	  @[NSLocalizedString(@"Greek (Windows)", nil), @(0xd)],
	  @[NSLocalizedString(@"Turkish (Windows)", nil), @(0xe)],
	  @[NSLocalizedString(@"Japanese (EUC)", nil), @(0x3)],
	  @[NSLocalizedString(@"Japanese (Shift_JIS)", nil), @(0x8)],
	  @[NSLocalizedString(@"Japanese (ISO 2022-JP)", nil), @(0x15)],
	  @[NSLocalizedString(@"Unicode (UTF-16)", nil), @(0xa)],
	  @[NSLocalizedString(@"Unicode (UTF-16, Big Endian)", nil), @(0x90000100)],
	  @[NSLocalizedString(@"Unicode (UTF-16, Little Endian)", nil), @(0x94000100)],
	  @[NSLocalizedString(@"Unicode (UTF-32)", nil), @(0x8c000100)],
	  @[NSLocalizedString(@"Unicode (UTF-32, Big Endian)", nil), @(0x98000100)],
	  @[NSLocalizedString(@"Unicode (UTF-32, Little Endian)", nil), @(0x9c000100)],
    ];
}

@end
